#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "🧪 Running E2E Test Suite for Module Auth"
echo "======================================="

# Configuration (must match cluster creation script)
KUBE_VERSION="${KUBE_VERSION:-1.33.0}"
DRONE_BUILD_NUMBER="${DRONE_BUILD_NUMBER:-9999}"
DRONE_REPO_NAME="${DRONE_REPO_NAME:-module-auth}"
CLUSTER_NAME="${DRONE_REPO_NAME}-${DRONE_BUILD_NUMBER}-${KUBE_VERSION}"
KUBECONFIG_PATH="${KUBECONFIG:-$(pwd)/kubeconfig-e2e}"

# Verify cluster exists and kubeconfig is available
if [ ! -f "${KUBECONFIG_PATH}" ]; then
  echo "❌ Error: Kubeconfig not found at ${KUBECONFIG_PATH}"
  echo "   Please run scripts/create-e2e-cluster.sh first"
  exit 1
fi

export KUBECONFIG="${KUBECONFIG_PATH}"

# Verify cluster is accessible
if ! kubectl get serviceaccount default > /dev/null 2>&1; then
  echo "❌ Error: Cannot access cluster ${CLUSTER_NAME}"
  echo "   Please ensure the cluster is running"
  exit 1
fi

# Source environment variables from cluster creation
ENV_FILE="./env-${CLUSTER_NAME}.env"
if [ ! -f "${ENV_FILE}" ]; then
  echo "❌ Error: Environment file not found at ${ENV_FILE}"
  echo "   Please run scripts/create-e2e-cluster.sh first"
  exit 1
fi

echo "📋 Loading environment from ${ENV_FILE}..."
source "${ENV_FILE}"

echo "🧪 Running BATS test suite..."
bats ./katalog/tests/tests.sh

echo "✅ E2E tests completed successfully!"