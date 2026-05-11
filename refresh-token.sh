#!/bin/bash
# ~/bin/refresh-token.sh

set -e

# Configuration
USERNAME="jhaynes"
ARTIFACTORY_HOST="artifactory.devopsbase.com"
ARTIFACTORY_URL="https://${ARTIFACTORY_HOST}"
BITBUCKET_HOST="bitbucket.devopsbase.com"
DO_SERVER_FOLDER="${HOME}/projects/do-dashboard-server"

# KeePassXC Configuration
KEEPASS_DB="${HOME}/.keepassxc/CACI-SecureResources.kdbx"
KEEPASS_KEYFILE="${HOME}/.keepassxc/CACI-SecureResources.keyx"
KEEPASS_ENTRY="DevOpsBase"

# Determine mode
MODE="${1:-artifactory}"  # Default to 'artifactory' if no argument

case "$MODE" in
  -h|--help|help)
    echo "Usage: $0 [artifactory|bitbucket|both]"
    echo ""
    echo "Modes:"
    echo "  artifactory - Only get Artifactory token and save to .artifactory_credentials and keychain (default)"
    echo "  bitbucket   - Only get Bitbucket token and save to keychain"
    echo "  both        - Get both tokens"
    echo ""
#    echo "Prerequisites:"
#    echo "  - KeePassXC database password stored in macOS Keychain"
#    echo "  - Run: security add-generic-password -a 'CACI-SecureResources' -s 'KeePassXC-DB' -w"
    exit 0
    ;;
  artifactory|bitbucket|both)
    # Valid mode
    ;;
  *)
    echo "Usage: $0 [artifactory|bitbucket|both]"
    echo "  artifactory - Only get Artifactory token and save to .artifactory_credentials and keychain (default)"
    echo "  bitbucket   - Only get Bitbucket token and save to keychain"
    echo "  both        - Get both tokens"
    exit 1
    ;;
esac

# Get KeePass database master password from macOS Keychain
KEEPASS_DB_PASSWORD=$(security find-generic-password -a "CACI-SecureResources" -s "KeePassXC-DB" -w 2>/dev/null)

if [ -z "$KEEPASS_DB_PASSWORD" ]; then
  echo "❌ Failed to retrieve KeePass database password from Keychain"
  echo "Run: security add-generic-password -a 'CACI-SecureResources' -s 'KeePassXC-DB' -w"
  exit 1
fi

# Get password from KeePassXC (suppress password prompt on stderr)
DEVOPS_BASE_PASSWORD=$(echo "$KEEPASS_DB_PASSWORD" | keepassxc-cli show \
  --key-file "${KEEPASS_KEYFILE}" \
  -s -a Password \
  "${KEEPASS_DB}" \
  "${KEEPASS_ENTRY}" 2>/dev/null)

if [ -z "$DEVOPS_BASE_PASSWORD" ]; then
  echo "❌ Failed to retrieve password from KeePassXC"
  exit 1
fi

# ============================================================================
# Artifactory Token
# ============================================================================
if [ "$MODE" = "artifactory" ] || [ "$MODE" = "both" ]; then
  read -p "Enter SurePass code for Artifactory: " SUREPASS_CODE_ARTIFACTORY

  if [ -z "$SUREPASS_CODE_ARTIFACTORY" ]; then
    echo "❌ SurePass code cannot be empty"
    exit 1
  fi

  FULL_DEVOPS_BASE_PASSWORD="${DEVOPS_BASE_PASSWORD}${SUREPASS_CODE_ARTIFACTORY}"

  ARTIFACTORY_RESPONSE=$(curl -s --max-time 30 -u "${USERNAME}:${FULL_DEVOPS_BASE_PASSWORD}" \
    -XPOST "${ARTIFACTORY_URL}/access/api/v1/tokens" \
    -d "scope=applied-permissions/user" \
    -d "include_reference_token=true" \
    -d "expires_in=86400")

  CURL_EXIT=$?
  if [ $CURL_EXIT -ne 0 ]; then
    echo "❌ Failed to connect to Artifactory (curl exit code: $CURL_EXIT)"
    [ $CURL_EXIT -eq 28 ] && echo "Connection timed out after 30 seconds"
    exit 1
  fi

  # Remove any trailing '%' or whitespace that might interfere with JSON parsing
  ARTIFACTORY_RESPONSE=$(echo "$ARTIFACTORY_RESPONSE" | tr -d '\000-\037' | sed 's/%$//')

  # Extract reference_token from Artifactory API response
  REFERENCE_TOKEN=$(echo "$ARTIFACTORY_RESPONSE" | jq -r '.reference_token // empty')

  if [ -z "$REFERENCE_TOKEN" ]; then
    echo "❌ Failed to get reference_token from Artifactory"
    echo "Response: $ARTIFACTORY_RESPONSE"
    exit 1
  fi

  # Save Artifactory reference_token in KeePassXC for Maven extension
  # Update the existing CDE Artifactory entry with the new token
  # Need to provide both: DB password on stdin, entry password via --password-prompt
  (echo "$KEEPASS_DB_PASSWORD"; echo "$REFERENCE_TOKEN") | keepassxc-cli edit \
    --key-file "${KEEPASS_KEYFILE}" \
    --username "${USERNAME}" \
    --url "https://artifactory.devopsbase.com" \
    --password-prompt \
    "${KEEPASS_DB}" \
    "CDE Artifactory" 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "✓ Saved Artifactory token to KeePassXC"
  else
    echo "⚠️  Failed to save token to KeePassXC (continuing anyway)"
  fi

  # Save Artifactory reference_token in the keychain for maven and other tools.
  # Get the token from the keychain: security find-internet-password -a "jhaynes" -s "artifactory.devopsbase.com" -w
  # Delete existing entry if it exists (ignore errors)
  security delete-internet-password \
    -a "${USERNAME}" \
    -s "${ARTIFACTORY_HOST}" \
    2>/dev/null || true

  # Store for Artifactory
  security add-internet-password \
    -a "${USERNAME}" \
    -s "${ARTIFACTORY_HOST}" \
    -w "${REFERENCE_TOKEN}" \
    -r "htps"  # htps is the 4-character protocol code for HTTPS

  ADD_EXIT=$?
  if [ $ADD_EXIT -ne 0 ]; then
    echo "❌ Failed to add Artifactory token to keychain (exit code: $ADD_EXIT)"
    exit 1
  else
    echo "✓ Saved Artifactory token to keychain"
  fi

  # Save to .artifactory_credentials in DO server folder
  if [ ! -d "${DO_SERVER_FOLDER}" ]; then
    echo "❌ Directory not found: ${DO_SERVER_FOLDER}"
    exit 1
  fi

  cat > "${DO_SERVER_FOLDER}"/.artifactory_credentials <<EOF
ARTIFACTORY_USERNAME=${USERNAME}
ARTIFACTORY_KEY=${REFERENCE_TOKEN}
EOF
  chmod 600 "${DO_SERVER_FOLDER}"/.artifactory_credentials
  echo "✓ Saved Artifactory credentials to ${DO_SERVER_FOLDER}/.artifactory_credentials"
fi

# ============================================================================
# Bitbucket Token
# ============================================================================
if [ "$MODE" = "bitbucket" ] || [ "$MODE" = "both" ]; then
  read -p "Enter SurePass code for Bitbucket: " SUREPASS_CODE_BITBUCKET

  if [ -z "$SUREPASS_CODE_BITBUCKET" ]; then
    echo "❌ SurePass code cannot be empty"
    exit 1
  fi

  FULL_DEVOPS_BASE_PASSWORD="${DEVOPS_BASE_PASSWORD}${SUREPASS_CODE_BITBUCKET}"

  RESPONSE=$(curl -s --max-time 30 -u "${USERNAME}:${FULL_DEVOPS_BASE_PASSWORD}" \
    -X PUT "https://${BITBUCKET_HOST}/rest/access-tokens/1.0/users/${USERNAME}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "daily-git-token",
      "expiryDays": 1,
      "permissions": ["REPO_READ", "REPO_WRITE"]
    }')

  CURL_EXIT=$?
  if [ $CURL_EXIT -ne 0 ]; then
    echo "❌ Failed to connect to Bitbucket (curl exit code: $CURL_EXIT)"
    [ $CURL_EXIT -eq 28 ] && echo "Connection timed out after 30 seconds"
    exit 1
  fi

  # Extract access_token from Bitbucket API response (field name is "token")
  ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get token from Bitbucket"
    echo "Response: $RESPONSE"
    exit 1
  fi

  # Delete existing entry if it exists (ignore errors)
  security delete-internet-password \
    -a "${USERNAME}" \
    -s "${BITBUCKET_HOST}" \
    2>/dev/null || true

  # This allows git commands to pick up the authentication from the macos keychain

  # Store Bitbucket access_token in keychain so git commands can authenticate automatically
  security add-internet-password \
    -a "${USERNAME}" \
    -s "${BITBUCKET_HOST}" \
    -w "${ACCESS_TOKEN}" \
    -r "htps"  # htps is the 4-character protocol code for HTTPS

  ADD_EXIT=$?
  if [ $ADD_EXIT -ne 0 ]; then
    echo "❌ Failed to add token to keychain (exit code: $ADD_EXIT)"
    exit 1
  fi
  echo "✓ Saved Bitbucket token to keychain"
fi
