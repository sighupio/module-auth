#!/usr/bin/env bats
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2154

load helper

set -o pipefail

# ========== Tool Validation Functions ==========

# These debug functions are no longer needed since we use stable curl --write-out
# instead of parsing version-dependent verbose output

# ========== Prerequisites ==========





# ========== Unified Template Processing ==========

@test "process all templates with machine IP configuration" {
  info
  show "📝 Processing all templates with machine IP: ${MACHINE_IP_NIP_DOMAIN}"
  
  # Generate Dex config from template
  show "  → Processing Dex configuration..."
  envsubst < katalog/tests/manifests/dex/resources/config.yml.template > katalog/tests/manifests/dex/secrets/config.yml
  
  # Generate Dex ingress from template
  show "  → Processing Dex ingress..."
  envsubst < katalog/tests/manifests/dex/ingress.yml.template > katalog/tests/manifests/dex/ingress.yml
  
  # Generate Pomerium config from template  
  show "  → Processing Pomerium configuration..."
  envsubst < katalog/tests/manifests/pomerium/resources/pomerium-config.env.template > katalog/tests/manifests/pomerium/resources/pomerium-config.env
  
  # Generate httpbin ingress from template
  show "  → Processing httpbin ingress..."
  envsubst < katalog/tests/manifests/httpbin/ingress.yml.template > katalog/tests/manifests/httpbin/ingress.yml
  
  # Generate Certificate resources from templates
  show "  → Processing Certificate resources..."
  envsubst < katalog/tests/manifests/certificates/dex-certificate.yaml.template > katalog/tests/manifests/certificates/dex-certificate.yaml
  envsubst < katalog/tests/manifests/certificates/pomerium-certificate.yaml.template > katalog/tests/manifests/certificates/pomerium-certificate.yaml  
  envsubst < katalog/tests/manifests/certificates/httpbin-certificate.yaml.template > katalog/tests/manifests/certificates/httpbin-certificate.yaml
  
  # Generate Pomerium policy from template
  show "  → Processing Pomerium policy..."
  envsubst < katalog/tests/manifests/pomerium/resources/pomerium-policy.yml.template > katalog/tests/manifests/pomerium/resources/pomerium-policy.yml
  
  show "✅ All templates processed successfully"
}

# ========== Unified Deployment ==========

@test "deploy complete auth stack with unified architecture" {
  info
  show "🚀 Deploying complete authentication stack..."
  show "📋 Components: cert-manager → nginx-ingress → ldap → dex → pomerium → httpbin → gangplank"
  
  # Deploy everything with single apply call
  apply katalog/tests/manifests auth-stack
  
  show "✅ Auth stack deployment initiated"
}

# ========== Unified Component Validation ==========

@test "validate cert-manager deployment" {
  info
  test(){
    kubectl get deployment -n cert-manager cert-manager >/dev/null 2>&1 &&
    kubectl get deployment -n cert-manager cert-manager-cainjector >/dev/null 2>&1 &&
    kubectl get deployment -n cert-manager cert-manager-webhook >/dev/null 2>&1
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate nginx-ingress controller ready" {
  info
  test(){
    check_ds_ready "ingress-nginx-controller" "ingress-nginx"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate LDAP server ready" {
  info
  test(){
    check_deploy_ready "ldap-server" "ldap"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate Dex ready" {
  info
  test(){
    check_deploy_ready "dex" "kube-system"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate Pomerium ready" {
  info
  test(){
    check_deploy_ready "pomerium" "pomerium"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate httpbin ready" {
  info
  test(){
    check_deploy_ready "httpbin" "pomerium"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate Gangplank ready" {
  info
  test(){
    check_deploy_ready "gangplank" "kube-system"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "validate HTTP endpoints are accessible" {
  info
  show "🌐 Checking HTTP endpoint accessibility..."
  show "  → Testing Dex, Pomerium, and httpbin ingress routing"
  test(){
    check_http_endpoint_ready "https://dex.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/" "200" &&
    check_http_endpoint_ready "https://pomerium.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/" "200 302" &&
    check_http_endpoint_ready "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/" "302"
  }
  loop_it test 60 5
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

# ========== Authentication Flow Validation ==========

@test "debug pod-to-ingress connectivity from within cluster" {
  info
  show "🔍 Testing pod-to-ingress connectivity from within cluster..."
  show "  → Running debug pod with curl to test all ingresses"
  
  # Test each ingress endpoint from inside a pod
  for endpoint in "dex" "pomerium" "httpbin"; do
    show "  → Testing ${endpoint} ingress connectivity..."
    
    kubectl run disposable-${endpoint} \
      --image=quay.io/sighup/debug-tools:bookworm \
      --restart=Never --rm -i --timeout=30s \
      -- /bin/sh -c "
        echo 'Testing ${endpoint}.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}...'
        curl -k -v --max-time 10 \
          -w 'RESULT: HTTP_%{http_code} URL:%{url_effective} TIME:%{time_total}s\\n' \
          https://${endpoint}.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/ \
          2>&1 || echo 'CURL_FAILED: \$?'
      " 2>&1 | while read line; do 
        show "    ${endpoint^^}: $line"
      done
  done
  
  show "✅ Pod-to-ingress connectivity test completed"
}

@test "validate complete OIDC authentication flow with session handling" {
  info
  show "🔍 Testing complete OIDC authentication flow..."
  show "  → Flow: httpbin → Pomerium → Dex → LDAP → JWT → httpbin"
  
  
  # CRITICAL: Clean session state to prevent pollution
  rm -f ./cookies.txt
  show "  → Cleaned session state"
  
  # Step 1: Initial access to httpbin - should redirect to Dex via Pomerium
  show "  → Step 1: Accessing httpbin to initiate authentication flow"
  FINAL_URL=$(curl -k -L -s -c ./cookies.txt --max-time 30 \
      -w '%{url_effective}' -o /tmp/auth_step1_body.log \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/")
  
  show "  → Final URL after redirects: $FINAL_URL"
  
  # Check Pomerium logs after Step 1
  show "  → Checking Pomerium logs after Step 1..."
  POMERIUM_POD=$(kubectl get pods -n pomerium -l app=pomerium -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [[ -n "$POMERIUM_POD" ]]; then
    kubectl logs -n pomerium "$POMERIUM_POD" --tail=5 2>/dev/null | while read line; do show "    POMERIUM: $line"; done
  fi
  
  # Step 2: Parse Dex login form details from the final URL
  show "  → Step 2: Extracting Dex base URL from final destination"
  
  # Extract Dex base URL directly from final URL (stable across curl versions)
  dex_base_url=$(echo "$FINAL_URL" | sed -E 's|^(https?://[^/]+).*|\1|')
  show "  → Extracted Dex base URL: '$dex_base_url'"
  
  # Validate that we got a Dex URL
  if [[ "$dex_base_url" != *"dex"* ]]; then
    show "❌ Expected Dex URL but got: $dex_base_url"
    show "📋 Full final URL: $FINAL_URL"
    return 1
  fi
  
  # Get the final response body which should contain the Dex login form
  dex_form_html=$(cat /tmp/auth_step1_body.log)
  
  show "  → Retrieved Dex login form HTML ($(echo "$dex_form_html" | wc -l) lines)"
  
  # Extract form action from HTML and decode HTML entities
  form_action=$(echo "$dex_form_html" | grep -oE 'action="[^"]*"' | sed 's/action="//;s/"//' | sed 's/&amp;/\&/g')
  show "  → Extracted form action: '$form_action'"
  
  # For this Dex setup, there's no CSRF token needed - just username/password
  csrf_token=""
  
  
  # Construct full login URL
  if [[ "$form_action" == /* ]]; then
    dex_login_url="${dex_base_url}${form_action}"
  else
    dex_login_url="$form_action"
  fi
  
  show "  → Dex login URL: '$dex_login_url'"
  
  # Step 3: Submit LDAP credentials to Dex
  show "  → Step 3: Submitting credentials to Dex"
  curl -k -v -L -c ./cookies.txt -b ./cookies.txt --max-time 30 \
      -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "login=user1" \
      --data-urlencode "password=userone" \
      "$dex_login_url" \
      > /tmp/auth_step3.log 2>&1
  
  # Check Pomerium logs after Step 3
  show "  → Checking Pomerium logs after Step 3..."
  if [[ -n "$POMERIUM_POD" ]]; then
    kubectl logs -n pomerium "$POMERIUM_POD" --tail=5 2>/dev/null | while read line; do show "    POMERIUM: $line"; done
  fi
  
  # Step 4: Verify authenticated access to httpbin/headers
  show "  → Step 4: Verifying authenticated access to httpbin/headers"
  
  # Access httpbin/headers with session cookies - should return 200 OK
  final_response=$(curl -k -s -L -w "%{http_code}" -c ./cookies.txt -b ./cookies.txt --max-time 30 \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/headers" \
      -o /tmp/auth_final_response.json 2>/dev/null)
  
  show "    → Final response code: $final_response"
  
  # Check Pomerium logs after Step 4
  show "  → Checking Pomerium logs after Step 4..."
  if [[ -n "$POMERIUM_POD" ]]; then
    kubectl logs -n pomerium "$POMERIUM_POD" --tail=5 2>/dev/null | while read line; do show "    POMERIUM: $line"; done
  fi
  
  # CRITICAL ASSERTION: Must get 200 OK
  [[ "$final_response" == "200" ]]
  
  # Verify response is valid httpbin JSON
  response_content=$(cat /tmp/auth_final_response.json)
  echo "$response_content" | grep -q '"headers"'
  
  # Verify Pomerium authentication headers are present
  echo "$response_content" | grep -q -i -E "(X-Pomerium|pomerium)"
  
  show "  ✅ Complete authentication flow successful!"
  show "  📊 Response contains httpbin headers with Pomerium authentication"
  
  # Clean up test artifacts
  rm -f ./cookies.txt /tmp/auth_step1_body.log /tmp/auth_step3.log /tmp/auth_final_response.json
  show "  → Cleaned up test artifacts"
}

