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
echo "Step 1: Install Maven KeePassXC Extension"
echo "================================================"

# Extension Maven coordinates
KEEPASSXC_GROUP="au.net.causal.maven.plugins"
KEEPASSXC_ARTIFACT="keepassxc-security-maven-extension"
KEEPASSXC_VERSION="1.0"

echo "Installing KeePassXC Maven extension from Maven Central..."
echo "(This downloads directly from Maven Central, bypassing any mirror configuration)"
mvn dependency:get \
  -DgroupId="$KEEPASSXC_GROUP" \
  -DartifactId="$KEEPASSXC_ARTIFACT" \
  -Dversion="$KEEPASSXC_VERSION" \
  -DremoteRepositories=central::default::https://repo1.maven.org/maven2 \
  -Dtransitive=true

if [ $? -eq 0 ]; then
  echo "✓ Extension installed to local Maven repository"
else
  echo "❌ Failed to download extension"
  echo "If you have a settings.xml with authentication requirements, you may need to"
  echo "temporarily rename it while downloading the extension:"
  echo "  mv ~/.m2/settings.xml ~/.m2/settings.xml.tmp"
  echo "  (re-run this script)"
  echo "  mv ~/.m2/settings.xml.tmp ~/.m2/settings.xml"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 2: Configure extensions.xml"
echo "================================================"

EXTENSIONS_XML="${HOME}/.m2/extensions.xml"

# Backup existing extensions.xml if it exists
if [ -f "$EXTENSIONS_XML" ]; then
  cp "$EXTENSIONS_XML" "${EXTENSIONS_XML}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "✓ Backed up existing extensions.xml"
fi

# Check if KeePassXC extension is already configured
if grep -q "keepassxc-security-maven-extension" "$EXTENSIONS_XML" 2>/dev/null; then
  echo "⚠️  KeePassXC extension already configured in extensions.xml"
else
  # Create or update extensions.xml
  if [ ! -f "$EXTENSIONS_XML" ]; then
    cat > "$EXTENSIONS_XML" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<extensions>
  <extension>
    <groupId>$KEEPASSXC_GROUP</groupId>
    <artifactId>$KEEPASSXC_ARTIFACT</artifactId>
    <version>$KEEPASSXC_VERSION</version>
  </extension>
</extensions>
EOF
    echo "✓ Created $EXTENSIONS_XML"
  else
    # Append to existing extensions.xml
    # This is a simple approach - manual merge may be needed for complex files
    echo "⚠️  $EXTENSIONS_XML exists. Please manually add this extension:"
    echo ""
    echo "  <extension>"
    echo "    <groupId>$KEEPASSXC_GROUP</groupId>"
    echo "    <artifactId>$KEEPASSXC_ARTIFACT</artifactId>"
    echo "    <version>$KEEPASSXC_VERSION</version>"
    echo "  </extension>"
    echo ""
  fi
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
echo "IMPORTANT: This setup uses ~/.m2/extensions.xml which works"
echo "           with both command-line Maven AND IntelliJ IDEA."
echo "           No .mavenrc file is required!"
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
echo "4. INTELLIJ IDEA USERS:"
echo "   - Restart IntelliJ IDEA for it to pick up the extensions.xml"
echo "   - IntelliJ will use the same KeePassXC integration automatically"
echo "   - Make sure KeePassXC is running when using Maven in IntelliJ"
echo ""
echo "5. TROUBLESHOOTING:"
echo "   - If you see '401 Unauthorized': check server ID matches mirror/repository ID"
echo "   - If you see 'No logins found': verify KeePassXC entry URL matches settings.xml"
echo "   - If KeePassXC keeps asking to pair: check ~/.m2/settings-security.xml exists"
echo "   - IntelliJ not working: verify extensions.xml exists and restart IntelliJ"
echo ""
echo "For more details, see: MAVEN_KEEPASSXC_SETUP.md"
echo ""
