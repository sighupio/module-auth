#!/bin/bash
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

echo "🧹 Cleaning generated files..."
cd katalog/tests

rm -f manifests/dex/secrets/config.yml
rm -f manifests/dex/ingress.yml
rm -f manifests/pomerium/resources/pomerium-config.env
rm -f manifests/httpbin/ingress.yml
rm -f manifests/certificates/dex-certificate.yaml
rm -f manifests/certificates/pomerium-certificate.yaml
rm -f manifests/certificates/httpbin-certificate.yaml
rm -f manifests/pomerium/resources/pomerium-policy.yml

# Clean temporary e2e files
rm -f config-*-*.yaml
rm -f env-*-*.env
rm -f kubeconfig-e2e

echo "✅ Generated files cleaned!"