#!/bin/bash
# Test script to verify KeePassXC auto-reload functionality
# This script modifies a KeePassXC entry and checks if the GUI detects the change

set -e

echo "================================================"
echo "KeePassXC Auto-Reload Test"
echo "================================================"
echo ""

# Configuration
KEEPASS_DB="${HOME}/.keepassxc/CACI-SecureResources.kdbx"
KEEPASS_KEYFILE="${HOME}/.keepassxc/CACI-SecureResources.keyx"
KEEPASS_ENTRY="CDE Artifactory"
TEST_PASSWORD="TEST-TOKEN-$(date +%s)"

# Get KeePass database password from macOS Keychain
KEEPASS_DB_PASSWORD=$(security find-generic-password -a "CACI-SecureResources" -s "KeePassXC-DB" -w 2>/dev/null)

if [ -z "$KEEPASS_DB_PASSWORD" ]; then
  echo "❌ Failed to retrieve KeePass database password from Keychain"
  exit 1
fi

# Check if KeePassXC is running
if ! pgrep -x "KeePassXC" > /dev/null; then
  echo "❌ KeePassXC is not running"
  echo "   Please start KeePassXC and unlock the database first"
  exit 1
fi

echo "✓ KeePassXC is running"
echo ""

# Get current password
echo "Step 1: Getting current password from KeePassXC entry..."
CURRENT_PASSWORD=$(echo "$KEEPASS_DB_PASSWORD" | keepassxc-cli show \
  --key-file "${KEEPASS_KEYFILE}" \
  -s -a Password \
  "${KEEPASS_DB}" \
  "${KEEPASS_ENTRY}" 2>/dev/null | tail -1)

echo "   Current password: ${CURRENT_PASSWORD}"
echo ""

# Update the entry with test password
echo "Step 2: Updating entry with test password via CLI..."
echo "   Test password: ${TEST_PASSWORD}"

(echo "$KEEPASS_DB_PASSWORD"; echo "$TEST_PASSWORD") | keepassxc-cli edit \
  --key-file "${KEEPASS_KEYFILE}" \
  --username "jhaynes" \
  --url "https://artifactory.devopsbase.com" \
  --password-prompt \
  "${KEEPASS_DB}" \
  "${KEEPASS_ENTRY}" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✓ Entry updated via CLI"
else
  echo "❌ Failed to update entry"
  exit 1
fi

echo ""
echo "Step 3: Waiting for KeePassXC GUI to auto-reload (5 seconds)..."
sleep 5
echo ""

echo "Step 4: Check the KeePassXC GUI now"
echo "================================================"
echo "Instructions:"
echo "1. Look at the '${KEEPASS_ENTRY}' entry in KeePassXC GUI"
echo "2. Check if the password shows: ${TEST_PASSWORD}"
echo ""
echo "If you see the test password, auto-reload works!"
echo "If you see the old password, auto-reload is NOT working."
echo "================================================"
echo ""

# Restore original password
read -p "Press ENTER to restore original password..."
echo ""
echo "Step 5: Restoring original password..."

(echo "$KEEPASS_DB_PASSWORD"; echo "$CURRENT_PASSWORD") | keepassxc-cli edit \
  --key-file "${KEEPASS_KEYFILE}" \
  --username "jhaynes" \
  --url "https://artifactory.devopsbase.com" \
  --password-prompt \
  "${KEEPASS_DB}" \
  "${KEEPASS_ENTRY}" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✓ Original password restored"
else
  echo "❌ Failed to restore password"
  echo "   You may need to manually set it to: ${CURRENT_PASSWORD}"
  exit 1
fi

echo ""
echo "Test complete!"
