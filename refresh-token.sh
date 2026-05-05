#!/bin/bash
# ~/bin/refresh-token.sh

set -e

# Configuration
USERNAME="jhaynes"
ARTIFACTORY_URL="https://artifactory.devopsbase.com"
BITBUCKET_HOST="bitbucket.devopsbase.com"

# KeePassXC Configuration
KEEPASS_DB="${HOME}/.keepassxc/CACI-SecureResources.kdbx"
KEEPASS_KEYFILE="${HOME}/.keepassxc/CACI-SecureResources.keyx"
KEEPASS_ENTRY="DevOpsBase"

echo "=== Bitbucket Token Refresh ==="
echo

# Get KeePass database master password from macOS Keychain
echo "1. Retrieving KeePass database password from Keychain..."
KEEPASS_DB_PASSWORD=$(security find-generic-password -a "CACI-SecureResources" -s "KeePassXC-DB" -w 2>/dev/null)

if [ -z "$KEEPASS_DB_PASSWORD" ]; then
  echo "❌ Failed to retrieve KeePass database password from Keychain"
  echo "Run: security add-generic-password -a 'CACI-SecureResources' -s 'KeePassXC-DB' -w"
  exit 1
fi
echo "   ✓ Retrieved database password (length: ${#KEEPASS_DB_PASSWORD})"

# Get password from KeePassXC
echo "2. Retrieving DevOpsBase password from KeePassXC..."
KEEPASS_PASSWORD=$(echo "$KEEPASS_DB_PASSWORD" | keepassxc-cli show \
  --key-file "${KEEPASS_KEYFILE}" \
  -s -a Password \
  "${KEEPASS_DB}" \
  "${KEEPASS_ENTRY}")

if [ -z "$KEEPASS_PASSWORD" ]; then
  echo "❌ Failed to retrieve password from KeePassXC"
  exit 1
fi
echo "   ✓ Retrieved DevOpsBase password"

# Prompt for SurePass code
read -p "Enter SurePass code: " SUREPASS_CODE

if [ -z "$SUREPASS_CODE" ]; then
  echo "❌ SurePass code cannot be empty"
  exit 1
fi

# Combine password and code
FULL_PASSWORD="${KEEPASS_PASSWORD}${SUREPASS_CODE}"
echo "   ✓ Combined password with SurePass code"

# COMMENTED OUT - Original Artifactory token request
# echo
# echo "3. Requesting token from Artifactory..."
# echo "   URL: ${ARTIFACTORY_URL}/access/api/v1/tokens"
# echo "   Username: ${USERNAME}"
# RESPONSE=$(curl -s --max-time 30 -u "${USERNAME}:${FULL_PASSWORD}" \
#   -XPOST "${ARTIFACTORY_URL}/access/api/v1/tokens" \
#   -d "scope=applied-permissions/user" \
#   -d "include_reference_token=true" \
#   -d "expires_in=86400")
#
# CURL_EXIT=$?
# echo "   Curl exit code: $CURL_EXIT"
# if [ $CURL_EXIT -ne 0 ]; then
#   echo "❌ Failed to connect to Artifactory (curl exit code: $CURL_EXIT)"
#   [ $CURL_EXIT -eq 28 ] && echo "   Connection timed out after 30 seconds"
#   exit 1
# fi
#
# # Extract access token
# echo "   Response length: ${#RESPONSE} characters"
# # Remove any trailing '%' or whitespace that might interfere with JSON parsing
# RESPONSE=$(echo "$RESPONSE" | tr -d '\000-\037' | sed 's/%$//')
#
# echo "${RESPONSE}"
# # Show which token fields are available
# echo "   Token fields in response:"
# echo "$RESPONSE" | jq -r 'keys[] | select(contains("token"))'
#
# # Use access_token instead of reference_token for Git authentication
# ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token // empty')
# #ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.reference_token // empty')
# if [ -z "$ACCESS_TOKEN" ]; then
#   echo "❌ Failed to get token"
#   echo "Response: $RESPONSE"
#   exit 1
# fi
# echo "   ✓ Extracted token (length: ${#ACCESS_TOKEN})"
# echo "   Token preview: ${ACCESS_TOKEN:0:20}..."

# Get token from Bitbucket
echo
echo "3. Requesting token from Bitbucket..."
echo "   URL: https://${BITBUCKET_HOST}/rest/access-tokens/1.0/users/${USERNAME}"
echo "   Username: ${USERNAME}"

RESPONSE=$(curl -s --max-time 30 -u "${USERNAME}:${FULL_PASSWORD}" \
  -X PUT "https://${BITBUCKET_HOST}/rest/access-tokens/1.0/users/${USERNAME}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "daily-git-token",
    "expiryDays": 1,
    "permissions": ["REPO_READ", "REPO_WRITE"]
  }')

CURL_EXIT=$?
echo "   Curl exit code: $CURL_EXIT"
if [ $CURL_EXIT -ne 0 ]; then
  echo "❌ Failed to connect to Bitbucket (curl exit code: $CURL_EXIT)"
  [ $CURL_EXIT -eq 28 ] && echo "   Connection timed out after 30 seconds"
  exit 1
fi

echo "   Response length: ${#RESPONSE} characters"
echo
echo "=== COMPLETE RESPONSE ==="
echo "$RESPONSE"
echo "======================="
echo

# Try to parse as JSON to see structure
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
  echo "Response is valid JSON with keys:"
  echo "$RESPONSE" | jq 'keys'
else
  echo "Response is not JSON - showing first 1000 characters:"
  echo "$RESPONSE" | head -c 1000
fi

exit 0

echo
echo "4. Storing token in macOS Keychain..."

# Delete existing entry if it exists (ignore errors)
echo "   Deleting existing token (if any)..."
security delete-internet-password \
  -a "${USERNAME}" \
  -s "${BITBUCKET_HOST}" \
  2>/dev/null || true

# Store for Bitbucket
echo "   Adding new token to keychain..."
security add-internet-password \
  -a "${USERNAME}" \
  -s "${BITBUCKET_HOST}" \
  -w "${ACCESS_TOKEN}" \
  -r "htps"

ADD_EXIT=$?
echo "   Security add-internet-password exit code: $ADD_EXIT"
if [ $ADD_EXIT -eq 0 ]; then
  echo "   ✓ ${BITBUCKET_HOST}"
else
  echo "   ❌ Failed to add token to keychain (exit code: $ADD_EXIT)"
  exit 1
fi

echo
echo "✅ Token stored successfully"
echo "   • Username: ${USERNAME}"
echo "   • Expires in: 24 hours"
echo "   • Bitbucket: https://${BITBUCKET_HOST}"