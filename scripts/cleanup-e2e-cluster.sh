#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "🧹 Cleaning up E2E Test Cluster"
echo "==============================="

# Configuration (same logic as creation script)
KUBE_VERSION="${KUBE_VERSION:-1.33.0}"
DRONE_BUILD_NUMBER="${DRONE_BUILD_NUMBER:-9999}"
DRONE_REPO_NAME="${DRONE_REPO_NAME:-module-auth}"
CLUSTER_NAME="${DRONE_REPO_NAME}-${DRONE_BUILD_NUMBER}-${KUBE_VERSION}"
KUBECONFIG_PATH="${KUBECONFIG:-$(pwd)/kubeconfig-e2e}"

echo "🗑️  Deleting Kind cluster: ${CLUSTER_NAME}"
kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || echo "   Cluster ${CLUSTER_NAME} not found (already clean)"

echo "🗑️  Cleaning up generated files..."
rm -f "${KUBECONFIG_PATH}"
rm -f "config-${CLUSTER_NAME}.yaml"
rm -f "env-${CLUSTER_NAME}.env"
rm -rf /tmp/test-certs

# Clean up test artifacts that might be left behind
rm -f /tmp/cookies.txt /tmp/auth_step*.log /tmp/auth_final_response.json

echo "✅ E2E cluster cleanup completed!"