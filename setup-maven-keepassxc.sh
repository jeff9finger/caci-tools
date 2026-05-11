#!/bin/bash
# Setup Maven to authenticate using KeePassXC password manager
# Works on macOS and Linux

set -e

echo "================================================"
echo "Maven KeePassXC Authentication Setup"
echo "================================================"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
else
  echo "⚠️  Warning: Unknown OS type: $OSTYPE"
  echo "This script is tested on macOS and Linux."
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Check prerequisites
echo "Checking prerequisites..."

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
  echo "❌ Maven not found. Please install Maven first."
  exit 1
fi
echo "✓ Maven found: $(mvn --version | head -1)"

# Check if KeePassXC CLI is installed
if ! command -v keepassxc-cli &> /dev/null; then
  echo "❌ keepassxc-cli not found. Please install KeePassXC first."
  if [[ "$OS" == "macos" ]]; then
    echo "   Install via: brew install keepassxc"
  elif [[ "$OS" == "linux" ]]; then
    echo "   Install via: sudo apt install keepassxc (Ubuntu/Debian)"
    echo "            or: sudo dnf install keepassxc (Fedora/RHEL)"
  fi
  exit 1
fi
echo "✓ keepassxc-cli found"

# Check if curl/wget is available
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
  echo "❌ Neither curl nor wget found. Please install one of them."
  exit 1
fi

echo ""
echo "================================================"
echo "Step 1: Download Maven KeePassXC Extension"
echo "================================================"

EXTENSIONS_DIR="${HOME}/.m2/extensions"
mkdir -p "$EXTENSIONS_DIR"

KEEPASSXC_EXT_URL="https://repo1.maven.org/maven2/au/net/causal/maven/plugins/keepassxc-security-maven-extension/1.0/keepassxc-security-maven-extension-1.0.jar"
COMMONS_LANG3_URL="https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.14.0/commons-lang3-3.14.0.jar"

echo "Downloading KeePassXC Maven extension..."
if command -v curl &> /dev/null; then
  curl -L -o "$EXTENSIONS_DIR/keepassxc-extension.jar" "$KEEPASSXC_EXT_URL"
  curl -L -o "$EXTENSIONS_DIR/commons-lang3.jar" "$COMMONS_LANG3_URL"
else
  wget -O "$EXTENSIONS_DIR/keepassxc-extension.jar" "$KEEPASSXC_EXT_URL"
  wget -O "$EXTENSIONS_DIR/commons-lang3.jar" "$COMMONS_LANG3_URL"
fi

echo "✓ Extensions downloaded to $EXTENSIONS_DIR"
ls -lh "$EXTENSIONS_DIR"

echo ""
echo "================================================"
echo "Step 2: Configure Maven to Load Extension"
echo "================================================"

MAVENRC="${HOME}/.mavenrc"

# Backup existing .mavenrc if it exists
if [ -f "$MAVENRC" ]; then
  cp "$MAVENRC" "${MAVENRC}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "✓ Backed up existing .mavenrc"
fi

# Check if extension is already configured
if grep -q "keepassxc-extension.jar" "$MAVENRC" 2>/dev/null; then
  echo "⚠️  KeePassXC extension already configured in .mavenrc"
else
  cat >> "$MAVENRC" <<'EOF'

# Load KeePassXC Maven extension to fetch passwords from KeePassXC
MAVEN_OPTS="$MAVEN_OPTS -Dmaven.ext.class.path=${HOME}/.m2/extensions/keepassxc-extension.jar:${HOME}/.m2/extensions/commons-lang3.jar"
EOF
  echo "✓ Updated .mavenrc to load KeePassXC extension"
fi

echo ""
echo "================================================"
echo "Step 3: Configure settings-security.xml"
echo "================================================"

SETTINGS_SECURITY="${HOME}/.m2/settings-security.xml"

# Backup existing settings-security.xml if it exists
if [ -f "$SETTINGS_SECURITY" ]; then
  cp "$SETTINGS_SECURITY" "${SETTINGS_SECURITY}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "✓ Backed up existing settings-security.xml"
fi

# Check if KeePassXC configuration already exists
if grep -q "keepassxc" "$SETTINGS_SECURITY" 2>/dev/null; then
  echo "⚠️  KeePassXC configuration already exists in settings-security.xml"
else
  cat > "$SETTINGS_SECURITY" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settingsSecurity>
  <configurations>
    <configuration>
      <name>keepassxc</name>
      <properties>
        <property>
          <name>credentialsStoreFile</name>
          <value>keepassxc-security-maven-extension-credentials</value>
        </property>
      </properties>
    </configuration>
  </configurations>
</settingsSecurity>
EOF
  echo "✓ Created settings-security.xml with KeePassXC configuration"
fi

echo ""
echo "================================================"
echo "✅ Automated Setup Complete!"
echo "================================================"
echo ""
echo "NEXT STEPS (Manual Configuration Required):"
echo ""
echo "1. CREATE KEEPASSXC ENTRY:"
echo "   - Open KeePassXC and unlock your database"
echo "   - Create a new entry with:"
echo "     Title: Artifactory (or any name)"
echo "     Username: <devopsbase-username>"
echo "     Password: <your-artifactory-token>"
echo "     URL: https://artifactory.devopsbase.com"
echo ""
echo "2. UPDATE ~/.m2/settings.xml:"
echo "   Add this server entry (or update existing):"
echo ""
echo "   <servers>"
echo "     <server>"
echo "       <id>int-unclass-distops-nosync-mvn-virtual</id>"
echo "       <username><devopsbase-username></username>"
echo "       <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>"
echo "     </server>"
echo "   </servers>"
echo ""
echo "   Note: The server <id> must match your mirror or repository ID"
echo ""
echo "3. TEST THE SETUP:"
echo "   - Make sure KeePassXC is running and unlocked"
echo "   - Run: mvn dependency:resolve"
echo "   - First time: KeePassXC will ask you to authorize the connection"
echo "   - Give it a name like 'maven-access'"
echo "   - After that, authentication will be automatic"
echo ""
echo "4. TROUBLESHOOTING:"
echo "   - If you see '401 Unauthorized': check server ID matches mirror/repository ID"
echo "   - If you see 'No logins found': verify KeePassXC entry URL matches settings.xml"
echo "   - If KeePassXC keeps asking to pair: check ~/.m2/settings-security.xml exists"
echo ""
echo "For more details, see: MAVEN_KEEPASSXC_SETUP.md"
echo ""
