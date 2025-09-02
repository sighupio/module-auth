#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "📝 Processing all templates..."
cd katalog/tests

# Check required environment variables
if [ -z "$MACHINE_IP_NIP_DOMAIN" ]; then
  echo "❌ MACHINE_IP_NIP_DOMAIN not set. Use: export MACHINE_IP_NIP_DOMAIN=yourip.nip.io"
  exit 1
fi

# Process templates
echo "  → Processing Dex configuration..."
envsubst < manifests/dex/resources/config.yml.template > manifests/dex/secrets/config.yml

echo "  → Processing Dex ingress..."
envsubst < manifests/dex/ingress.yml.template > manifests/dex/ingress.yml

echo "  → Processing Pomerium configuration..."
envsubst < manifests/pomerium/resources/pomerium-config.env.template > manifests/pomerium/resources/pomerium-config.env

echo "  → Processing httpbin ingress..."
envsubst < manifests/httpbin/ingress.yml.template > manifests/httpbin/ingress.yml

echo "  → Processing Certificate resources..."
envsubst < manifests/certificates/dex-certificate.yaml.template > manifests/certificates/dex-certificate.yaml
envsubst < manifests/certificates/pomerium-certificate.yaml.template > manifests/certificates/pomerium-certificate.yaml
envsubst < manifests/certificates/httpbin-certificate.yaml.template > manifests/certificates/httpbin-certificate.yaml

echo "  → Processing Pomerium policy..."
envsubst < manifests/pomerium/resources/pomerium-policy.yml.template > manifests/pomerium/resources/pomerium-policy.yml

echo "✅ All templates processed successfully!"