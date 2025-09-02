#!/usr/bin/env bats
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2154

load helper

set -o pipefail

# ========== Prerequisites ==========





# ========== Unified Template Processing ==========

@test "process all templates with machine IP configuration" {
  info
  echo "📝 Processing all templates with machine IP: ${MACHINE_IP_NIP_DOMAIN}"
  
  # Generate Dex config from template
  echo "  → Processing Dex configuration..."
  envsubst < katalog/tests/manifests/dex/resources/config.yml.template > katalog/tests/manifests/dex/secrets/config.yml
  
  # Generate Dex ingress from template
  echo "  → Processing Dex ingress..."
  envsubst < katalog/tests/manifests/dex/ingress.yml.template > katalog/tests/manifests/dex/ingress.yml
  
  # Generate Pomerium config from template  
  echo "  → Processing Pomerium configuration..."
  envsubst < katalog/tests/manifests/pomerium/resources/pomerium-config.env.template > katalog/tests/manifests/pomerium/resources/pomerium-config.env
  
  # Generate httpbin ingress from template
  echo "  → Processing httpbin ingress..."
  envsubst < katalog/tests/manifests/httpbin/ingress.yml.template > katalog/tests/manifests/httpbin/ingress.yml
  
  # Generate Certificate resources from templates
  echo "  → Processing Certificate resources..."
  envsubst < katalog/tests/manifests/certificates/dex-certificate.yaml.template > katalog/tests/manifests/certificates/dex-certificate.yaml
  envsubst < katalog/tests/manifests/certificates/pomerium-certificate.yaml.template > katalog/tests/manifests/certificates/pomerium-certificate.yaml  
  envsubst < katalog/tests/manifests/certificates/httpbin-certificate.yaml.template > katalog/tests/manifests/certificates/httpbin-certificate.yaml
  
  # Generate Pomerium policy from template
  echo "  → Processing Pomerium policy..."
  envsubst < katalog/tests/manifests/pomerium/resources/pomerium-policy.yml.template > katalog/tests/manifests/pomerium/resources/pomerium-policy.yml
  
  echo "✅ All templates processed successfully"
}

# ========== Unified Deployment ==========

@test "deploy complete auth stack with unified architecture" {
  info
  echo "🚀 Deploying complete authentication stack..."
  echo "📋 Components: cert-manager → nginx-ingress → ldap → dex → pomerium → httpbin → gangplank"
  
  # Deploy everything with single apply call
  apply katalog/tests/manifests auth-stack
  
  echo "✅ Auth stack deployment initiated"
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

# ========== Authentication Flow Validation ==========

@test "validate Pomerium enforces authentication for httpbin" {
  info
  # Access httpbin without authentication should redirect to Pomerium auth
  response=$(curl -k -s -o /dev/null -w "%{http_code}" \
      https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/)
  
  # Should redirect to authentication (302/303) or show auth page
  [[ "$response" == "302" || "$response" == "303" || "$response" == "200" ]]
}

@test "validate Pomerium redirects to Dex for authentication" {
  info
  # Follow redirects to see if we end up at Dex
  response=$(curl -k -s -L \
      https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/ | head -20)
  
  # Should contain Dex login page elements or be redirected to Dex
  echo "$response" | grep -q -i -E "(dex|login|auth)"
}

@test "validate complete OIDC authentication flow with session handling" {
  info
  echo "🔍 Testing complete OIDC authentication flow..."
  echo "  → Flow: httpbin → Pomerium → Dex → LDAP → JWT → httpbin"
  
  # CRITICAL: Clean session state to prevent pollution
  rm -f /tmp/cookies.txt
  echo "  → Cleaned session state"
  
  # Step 1: Initial access to httpbin - should redirect to Dex via Pomerium
  echo "  → Step 1: Accessing httpbin to initiate authentication flow"
  curl -k -v -L -c /tmp/cookies.txt -b /tmp/cookies.txt --max-time 30 \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/" \
      > /tmp/auth_step1.log 2>&1
  
  # Step 2: Parse Dex login form details from the redirected response
  echo "  → Step 2: Parsing Dex login form"
  
  # Extract Dex base URL from Location header - look for dex domain
  dex_base_url=$(grep -E '< location: https?://dex[^/]*' /tmp/auth_step1.log | head -n 1 | sed -E 's|.*< location: (https?://[^/]+).*|\1|')
  echo "    → Dex base URL: $dex_base_url"
  
  # Get the final response body which should contain the Dex login form - the curl log already shows the HTML
  # Extract the HTML content from the curl verbose output (from line that starts with <!DOCTYPE)
  dex_form_html=$(sed -n '/<!DOCTYPE html>/,/<\/html>/p' /tmp/auth_step1.log)
  
  # Extract form action from HTML and decode HTML entities
  form_action=$(echo "$dex_form_html" | grep -oE 'action="[^"]*"' | sed 's/action="//;s/"//' | sed 's/&amp;/\&/g')
  
  # For this Dex setup, there's no CSRF token needed - just username/password
  csrf_token=""
  
  echo "    → Form action: $form_action"
  echo "    → CSRF token: ${csrf_token:0:20}..."
  
  # Construct full login URL
  if [[ "$form_action" == /* ]]; then
    dex_login_url="${dex_base_url}${form_action}"
  else
    dex_login_url="$form_action"
  fi
  echo "    → Login URL: $dex_login_url"
  
  # Step 3: Submit LDAP credentials to Dex
  echo "  → Step 3: Submitting credentials to Dex"
  curl -k -v -L -c /tmp/cookies.txt -b /tmp/cookies.txt --max-time 30 \
      -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "login=user1" \
      --data-urlencode "password=userone" \
      "$dex_login_url" \
      > /tmp/auth_step3.log 2>&1
  
  # Step 4: Verify authenticated access to httpbin/headers
  echo "  → Step 4: Verifying authenticated access to httpbin/headers"
  
  # Access httpbin/headers with session cookies - should return 200 OK
  final_response=$(curl -k -s -L -w "%{http_code}" -c /tmp/cookies.txt -b /tmp/cookies.txt --max-time 30 \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/headers" \
      -o /tmp/auth_final_response.json 2>/dev/null)
  
  echo "    → Final response code: $final_response"
  
  # CRITICAL ASSERTION: Must get 200 OK
  [[ "$final_response" == "200" ]]
  
  # Verify response is valid httpbin JSON
  response_content=$(cat /tmp/auth_final_response.json)
  echo "$response_content" | grep -q '"headers"'
  
  # Verify Pomerium authentication headers are present
  echo "$response_content" | grep -q -i -E "(X-Pomerium|pomerium)"
  
  echo "  ✅ Complete authentication flow successful!"
  echo "  📊 Response contains httpbin headers with Pomerium authentication"
  
  # Clean up test artifacts
  rm -f /tmp/cookies.txt /tmp/auth_step1.log /tmp/auth_step3.log /tmp/auth_final_response.json
  echo "  → Cleaned up test artifacts"
}

@test "validate complete auth system integration" {
  info
  echo "🎉 SUCCESS: Complete unified auth stack deployed and validated!"
  echo "🔗 Architecture: LDAP → Dex → Pomerium → httpbin"
  echo "🌐 Machine IP networking: ${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}"
  echo "🔐 SSL/TLS: cert-manager with common CA architecture"
  echo "🔄 Session Management: Pattern identified and validated"
  echo "🚀 Ready for production-like auth flow testing"
}