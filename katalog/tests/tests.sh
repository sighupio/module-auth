#!/usr/bin/env bats
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2154

load helper

set -o pipefail

# ========== Tool Validation Functions ==========

# Tool validation function for CI environment debugging
validate_tools() {
  show "🔧 Validating CI environment tools..."
  
  # Check core tools existence
  for tool in curl grep sed head tail; do
    if command -v "$tool" >/dev/null 2>&1; then
      show "✅ $tool: $(command -v $tool)"
    else
      show "❌ Missing: $tool"
      return 1
    fi
  done
  
  # Check tool versions and capabilities
  show "📋 Tool versions:"
  show "  curl: $(curl --version | head -1)"
  show "  grep: $(grep --version 2>&1 | head -1 || echo 'No version info')"
  show "  sed: $(sed --version 2>&1 | head -1 || echo 'No version info')"
  
  # Test GNU vs BSD detection
  if grep --version 2>/dev/null | grep -q "GNU"; then
    show "📍 GNU grep detected"
  else
    show "📍 BSD/other grep detected"
  fi
  
  if sed --version 2>/dev/null | grep -q "GNU"; then
    show "📍 GNU sed detected"
  else
    show "📍 BSD/other sed detected"
  fi
}

# Test regex pattern functionality
test_regex_patterns() {
  show "🧪 Testing regex patterns..."
  
  # Create test data similar to the failing curl output
  cat > /tmp/test_curl_output <<'EOF'
< location: https://pomerium.116.202.228.246.nip.io:4048/.pomerium/sign_in?params
< location: https://dex.116.202.228.246.nip.io:4048/auth?params
EOF
  
  # Test the failing pattern
  result=$(grep -E '< location: https?://dex[^/]*' /tmp/test_curl_output | tail -n 1)
  if [ -n "$result" ]; then
    show "✅ Dex pattern works: $result"
  else
    show "❌ Dex pattern fails"
  fi
  
  # Test sed extraction
  if [ -n "$result" ]; then
    extracted=$(echo "$result" | sed -E 's|.*< location: (https?://[^/]+).*|\1|')
    show "✅ Sed extraction: $extracted"
  else
    show "❌ No input for sed test"
  fi
  
  rm -f /tmp/test_curl_output
}

# Alternative pattern matching approaches
try_alternative_patterns() {
  show "🔄 Trying alternative pattern matching..."
  
  # Use awk instead of grep+sed
  dex_url_awk=$(awk '/< location:.*dex/ { print $3; exit }' /tmp/auth_step1.log)
  
  # Use basic grep instead of extended regex
  dex_url_basic=$(grep "< location:" /tmp/auth_step1.log | grep "dex" | tail -1)
  
  show "AWK result: $dex_url_awk"
  show "Basic grep result: $dex_url_basic"
}

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


@test "validate complete OIDC authentication flow with session handling" {
  info
  show "🔍 Testing complete OIDC authentication flow..."
  show "  → Flow: httpbin → Pomerium → Dex → LDAP → JWT → httpbin"
  
  # Validate CI environment tools first
  validate_tools || { show "Tool validation failed"; return 1; }
  test_regex_patterns
  
  # CRITICAL: Clean session state to prevent pollution
  rm -f ./cookies.txt
  show "  → Cleaned session state"
  
  # Step 1: Initial access to httpbin - should redirect to Dex via Pomerium
  show "  → Step 1: Accessing httpbin to initiate authentication flow"
  curl -k -v -L -c ./cookies.txt --max-time 30 \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/" \
      > /tmp/auth_step1.log 2>&1
  
  # Step 2: Parse Dex login form details from the redirected response
  show "  → Step 2: Parsing Dex login form"
  
  # Debug: Show contents of auth_step1.log for troubleshooting
  show "🐛 Debug: Contents of auth_step1.log (first 20 lines):"
  show "$(head -20 /tmp/auth_step1.log || echo 'File not found or empty')"
  
  show "🐛 Debug: Looking for location headers:"
  show "$(grep -i location /tmp/auth_step1.log || echo 'No location headers found')"
  
  show "🐛 Debug: Looking for dex references:"
  show "$(grep -i dex /tmp/auth_step1.log || echo 'No dex references found')"
  
  # Extract Dex base URL from Location header - look for dex domain (final redirect in chain)
  show "🐛 Debug: Attempting to extract dex_base_url..."
  dex_base_url=$(grep -E '< location: https?://dex[^/]*' /tmp/auth_step1.log | tail -n 1 | sed -E 's|.*< location: (https?://[^/]+).*|\1|')
  show "🐛 Debug: Extracted dex_base_url: '$dex_base_url'"
  
  # If primary pattern matching failed, try alternatives
  if [ -z "$dex_base_url" ]; then
    show "🔄 Primary pattern failed, trying alternatives..."
    try_alternative_patterns
    
    # Try alternative extraction methods if still empty
    if [ -z "$dex_base_url" ]; then
      show "❌ All pattern matching methods failed"
      show "📋 Full auth_step1.log content:"
      show "$(cat /tmp/auth_step1.log)"
      return 1
    fi
  fi
  
  # Get the final response body which should contain the Dex login form - the curl log already shows the HTML
  # Extract the HTML content from the curl verbose output (from line that starts with <!DOCTYPE)
  dex_form_html=$(sed -n '/<!DOCTYPE html>/,/<\/html>/p' /tmp/auth_step1.log)
  
  show "🐛 Debug: Extracted HTML form content (first 10 lines):"
  show "$(echo "$dex_form_html" | head -10 || echo 'No HTML content found')"
  
  # Extract form action from HTML and decode HTML entities
  form_action=$(echo "$dex_form_html" | grep -oE 'action="[^"]*"' | sed 's/action="//;s/"//' | sed 's/&amp;/\&/g')
  show "🐛 Debug: Extracted form_action: '$form_action'"
  
  # For this Dex setup, there's no CSRF token needed - just username/password
  csrf_token=""
  
  
  # Construct full login URL
  if [[ "$form_action" == /* ]]; then
    dex_login_url="${dex_base_url}${form_action}"
  else
    dex_login_url="$form_action"
  fi
  
  show "🐛 Debug: Final dex_login_url: '$dex_login_url'"
  
  # Step 3: Submit LDAP credentials to Dex
  show "  → Step 3: Submitting credentials to Dex"
  curl -k -v -L -c ./cookies.txt -b ./cookies.txt --max-time 30 \
      -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "login=user1" \
      --data-urlencode "password=userone" \
      "$dex_login_url" \
      > /tmp/auth_step3.log 2>&1
  
  # Step 4: Verify authenticated access to httpbin/headers
  show "  → Step 4: Verifying authenticated access to httpbin/headers"
  
  # Access httpbin/headers with session cookies - should return 200 OK
  final_response=$(curl -k -s -L -w "%{http_code}" -c ./cookies.txt -b ./cookies.txt --max-time 30 \
      "https://httpbin.${MACHINE_IP_NIP_DOMAIN}:${EXTERNAL_PORT}/headers" \
      -o /tmp/auth_final_response.json 2>/dev/null)
  
  show "    → Final response code: $final_response"
  
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
  rm -f ./cookies.txt /tmp/auth_step1.log /tmp/auth_step3.log /tmp/auth_final_response.json
  show "  → Cleaned up test artifacts"
}

