#!/bin/sh
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# This script generates a configuration file for Kubernetes using Kind with unique port numbers for module-auth.
# It detects the machine's IP address for use with nip.io magic DNS to enable unified URLs.
# It accepts Kubernetes version and HTTPS port either as command line arguments or from environment variables.
# Usage: 
#   Command Line: sh generate-template.sh [v]X.Y.Z [DEFAULT_HTTPS_PORT]
#   Environment Variables: KUBE_VERSION, HTTPS_PORT
# Examples:
#   Command Line: sh generate-template.sh 1.33.0 or sh generate-template.sh v1.33.0
#   Environment: export KUBE_VERSION=1.33.0; export HTTPS_PORT=2443; sh generate-template.sh
# If an error occurs, the script will display a message indicating the correct usage.

# Function to detect machine IP address (cross-platform)
detect_machine_ip() {
    # Try to detect the operating system
    OS=$(uname -s)
    
    case "$OS" in
        "Linux")
            # Use hostname -I as primary method (works in containers)
            MACHINE_IP=$(hostname -I 2>/dev/null | awk '{print $1}' | head -n1)
            
            # Fallback to ip route if hostname -I fails  
            if [ -z "$MACHINE_IP" ]; then
                MACHINE_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | head -n1)
            fi
            ;;
        "Darwin")
            # On macOS, use 'route get' and extract interface, then get IP from ifconfig
            ROUTE_OUTPUT=$(route get 1.1.1.1 2>/dev/null)
            INTERFACE=$(echo "$ROUTE_OUTPUT" | awk '/interface:/ {print $2}' | head -n1)
            if [ -n "$INTERFACE" ]; then
                MACHINE_IP=$(ifconfig "$INTERFACE" 2>/dev/null | awk '/inet / && !/127\.0\.0\.1/ {print $2; exit}' | head -n1)
            fi
            ;;
        *)
            echo "Error: Unsupported operating system: $OS"
            echo "Supported systems: Linux, macOS (Darwin)"
            exit 5
            ;;
    esac
    
    # Validate IP address format
    if [ -z "$MACHINE_IP" ] || ! echo "$MACHINE_IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
        echo "Error: Failed to detect valid machine IP address."
        echo "Detected: '$MACHINE_IP'"
        echo "Please ensure network connectivity and try again."
        exit 6
    fi
    
    # Additional validation for IP octets (0-255)
    for OCTET in $(echo "$MACHINE_IP" | tr '.' ' '); do
        if [ "$OCTET" -gt 255 ] || [ "$OCTET" -lt 0 ]; then
            echo "Error: Invalid IP address detected: $MACHINE_IP"
            exit 7
        fi
    done
    
    echo "$MACHINE_IP"
}

# Assign command line arguments to variables or read from environment
KUBE_VERSION=${1:-$KUBE_VERSION}
DEFAULT_HTTPS_PORT=${2:-${HTTPS_PORT:-2443}}  # Use command line argument, then environment variable, then 2443 as default

# Detect machine IP for nip.io DNS
echo "🔍 Detecting machine IP address..."
MACHINE_IP=$(detect_machine_ip)
echo "✅ Machine IP detected: $MACHINE_IP"

# Validate that the Kubernetes version argument has been provided
if [ -z "$KUBE_VERSION" ]; then
    echo "Error: Kubernetes version is missing. Provide it as an argument or set the KUBE_VERSION environment variable."
    echo "Usage: sh $0 [v]X.Y.Z [DEFAULT_HTTPS_PORT]"
    echo "Example: sh $0 1.33.0 or sh $0 v1.33.0"
    exit 1
fi

# Check if version starts with 'v', if not prepend it
if ! echo "$KUBE_VERSION" | grep -qE '^v'; then
    KUBE_VERSION="v$KUBE_VERSION"
fi

# Validate the Kubernetes version format (vX.Y.Z)
VERSION_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+$'
if ! echo "$KUBE_VERSION" | grep -E "$VERSION_REGEX" > /dev/null; then
    echo "Error: Kubernetes version format is invalid. Expected '[v]X.Y.Z'."
    echo "Example: sh $0 1.33.0 or sh $0 v1.33.0"
    exit 2
fi

# Extract major, minor, and patch versions from the Kubernetes version
MAJOR_VERSION=$(echo "$KUBE_VERSION" | sed 's/^v//' | cut -d'.' -f1)
MINOR_VERSION=$(echo "$KUBE_VERSION" | cut -d'.' -f2) 
PATCH_VERSION=$(echo "$KUBE_VERSION" | cut -d'.' -f3)

# Create concatenated version number for better port distribution
VERSION_CONCAT="${MAJOR_VERSION}${MINOR_VERSION}${PATCH_VERSION}"

# Validate that the DRONE_BUILD_NUMBER environment variable is set and is an integer
if [ -z "$DRONE_BUILD_NUMBER" ] || ! echo "$DRONE_BUILD_NUMBER" | grep -E '^[0-9]+$' > /dev/null; then
    echo "Error: DRONE_BUILD_NUMBER is not set or is not an integer."
    exit 3
fi

# Calculate unique HTTPS port using concatenated version (major.minor.patch), DRONE_BUILD_NUMBER, and default HTTPS port value
# Version concatenation provides natural separation between different Kubernetes versions
UNIQUE_HTTPS_PORT=$((VERSION_CONCAT + DRONE_BUILD_NUMBER + DEFAULT_HTTPS_PORT))

# Ensure unique port is greater than 1024 and less than 30000
if [ "$UNIQUE_HTTPS_PORT" -le 1024 ] || [ "$UNIQUE_HTTPS_PORT" -ge 30000 ]; then
    echo "Error: Calculated HTTPS port must be greater than 1024 and less than 30000. HTTPS_PORT = $UNIQUE_HTTPS_PORT"
    exit 4
fi

CLUSTER_NAME="${DRONE_REPO_NAME}-${DRONE_BUILD_NUMBER}-${KUBE_VERSION#v}"
DEFAULT_OUTPUT=./

# Create the configuration file using a here-document block (EOF)
CONFIG_FILE="${DEFAULT_OUTPUT}config-${CLUSTER_NAME}.yaml"
cat > "$CONFIG_FILE" <<EOF
# Configuration file generated for Kubernetes using Kind for module-auth
# This file was automatically generated by the script. Do not modify it manually.
---
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: ${CLUSTER_NAME}
nodes:
  - role: control-plane
    image: registry.sighup.io/fury/kindest/node:$KUBE_VERSION # Specified Kubernetes version
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 31443 # nginx ingress controller HTTPS
        hostPort: ${UNIQUE_HTTPS_PORT}
        listenAddress: 0.0.0.0
        # Bind to 0.0.0.0 to make port accessible from machine's real IP
EOF

# Save details for Drone CI and local testing
DRONE_ENV_REF="${DEFAULT_OUTPUT}env-${CLUSTER_NAME}.env"
cat > "$DRONE_ENV_REF" <<EOF
export EXTERNAL_PORT=$UNIQUE_HTTPS_PORT
export KIND_CONFIG=$CONFIG_FILE
export KUBE_VERSION=$KUBE_VERSION
export MACHINE_IP=$MACHINE_IP
export MACHINE_IP_NIP_DOMAIN=${MACHINE_IP}.nip.io
EOF

echo "External HTTPS port configured: $UNIQUE_HTTPS_PORT"
echo "Kubernetes version used: $KUBE_VERSION"
echo "Machine IP detected: $MACHINE_IP"
echo "NIP.io domain: ${MACHINE_IP}.nip.io"
echo "Environment file saved in: $DRONE_ENV_REF"
echo "Kind configuration file saved in: $CONFIG_FILE"