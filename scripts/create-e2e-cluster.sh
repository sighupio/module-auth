#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "🚀 Creating E2E Test Cluster for Module Auth"
echo "=========================================="

# Configuration (CI provides these, local uses defaults from mise.toml)
KUBE_VERSION="${KUBE_VERSION:-1.33.0}"
export DRONE_BUILD_NUMBER="${DRONE_BUILD_NUMBER:-9999}"
export DRONE_REPO_NAME="${DRONE_REPO_NAME:-module-auth}"
CLUSTER_NAME="${DRONE_REPO_NAME}-${DRONE_BUILD_NUMBER}-${KUBE_VERSION}"
KUBECONFIG_PATH="${KUBECONFIG:-$(pwd)/kubeconfig-e2e}"

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

# Step 4: Update environment with CI-specific IP if needed
if [ "${DRONE_BUILD_NUMBER:-9999}" != "9999" ]; then
  echo "🔧 Drone CI detected (build ${DRONE_BUILD_NUMBER}), updating environment with Kind node IP to avoid hairpinning..."
  
  # Wait for nodes to be ready and get internal IP
  until NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null) && [ -n "$NODE_IP" ]; do
    echo "   Waiting for node IP to be available..."
    sleep 2
  done
  
  # Update the environment file with node IP
  ENV_FILE="./env-${CLUSTER_NAME}.env"
  echo "   Original MACHINE_IP: $(grep MACHINE_IP= ${ENV_FILE} | cut -d'=' -f2)"
  echo "   Using Kind node IP: ${NODE_IP}"
  
  # Update both MACHINE_IP and MACHINE_IP_NIP_DOMAIN
  sed -i.backup "s/MACHINE_IP=.*/MACHINE_IP=${NODE_IP}/" "${ENV_FILE}"
  sed -i.backup "s/MACHINE_IP_NIP_DOMAIN=.*/MACHINE_IP_NIP_DOMAIN=${NODE_IP}.nip.io/" "${ENV_FILE}"
  
  # Clean up backup file
  rm -f "${ENV_FILE}.backup"
  
  echo "✅ Environment updated with Kind node IP: ${NODE_IP}"
else
  echo "🏠 Local environment detected (build 9999), using host machine IP"
fi

echo "✅ E2E cluster created successfully!"
echo "   Cluster: ${CLUSTER_NAME}"
echo "   Kubeconfig: ${KUBECONFIG_PATH}"
echo "   Environment: ./env-${CLUSTER_NAME}.env"