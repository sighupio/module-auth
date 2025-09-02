#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "🚀 Starting E2E Test Suite for Module Auth"
echo "=========================================="

# Configuration (CI provides these, local uses defaults from mise.toml)
KUBE_VERSION="${KUBE_VERSION:-1.33.0}"
export DRONE_BUILD_NUMBER="${DRONE_BUILD_NUMBER:-9999}"
export DRONE_REPO_NAME="${DRONE_REPO_NAME:-module-auth}"
CLUSTER_NAME="${DRONE_REPO_NAME}-${DRONE_BUILD_NUMBER}-${KUBE_VERSION}"
KUBECONFIG_PATH="${KUBECONFIG:-$(pwd)/kubeconfig-e2e}"

# Cleanup function
cleanup() {
  echo "🧹 Cleaning up..."
  kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || true
  rm -f "${KUBECONFIG_PATH}"
  rm -f "config-${CLUSTER_NAME}.yaml"
  rm -f "env-${CLUSTER_NAME}.env"
  rm -rf /tmp/test-certs
}

# Trap to ensure cleanup on exit (success or failure)
trap cleanup EXIT

echo "📦 Step 1: Creating Kind cluster (K8s ${KUBE_VERSION})..."
./scripts/generate-kind-config.sh ${KUBE_VERSION}
kind create cluster --config "./config-${CLUSTER_NAME}.yaml" --name "${CLUSTER_NAME}"

echo "📋 Step 2: Setting up kubeconfig..."
kind get kubeconfig --name "${CLUSTER_NAME}" > "${KUBECONFIG_PATH}"
export KUBECONFIG="${KUBECONFIG_PATH}"

echo "⏳ Step 3: Waiting for cluster to be ready..."
until kubectl get serviceaccount default > /dev/null 2>&1; do 
  echo "   Waiting for control-plane..." 
  sleep 2
done

echo "🧪 Step 4: Running E2E tests..."
source "./env-${CLUSTER_NAME}.env"
bats ./katalog/tests/tests.sh

echo "✅ E2E tests completed successfully!"