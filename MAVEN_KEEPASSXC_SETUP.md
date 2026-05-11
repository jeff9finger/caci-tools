# Maven Authentication with KeePassXC

This guide explains how to configure Maven to authenticate to Artifactory using passwords stored in KeePassXC, eliminating the need to store tokens in plaintext in `settings.xml`.

## Overview

Instead of storing your Artifactory token directly in Maven's `settings.xml`, this setup allows Maven to fetch credentials from KeePassXC at runtime. Benefits include:

- **No plaintext passwords** in configuration files
- **Automatic token rotation** - update the password in KeePassXC and Maven picks it up immediately
- **Cross-platform** - works on macOS and Linux
- **Secure pairing** - one-time authorization between Maven and KeePassXC

## Prerequisites

- **Maven** 3.x installed
- **KeePassXC** installed and configured
  - macOS: `brew install keepassxc`
  - Linux: `sudo apt install keepassxc` (Ubuntu/Debian) or `sudo dnf install keepassxc` (Fedora/RHEL)
- **KeePassXC CLI** (included with KeePassXC installation)
- Your DevOpsBase Artifactory credentials

## Quick Start

### 1. Run the Setup Script

```bash
cd ~/github/caci-tools
chmod +x setup-maven-keepassxc.sh
./setup-maven-keepassxc.sh
```

This script will:
- Download the Maven KeePassXC extension and dependencies
- Update your `~/.mavenrc` to load the extension
- Create/update `~/.m2/settings-security.xml`

### 2. Create KeePassXC Entry

Open KeePassXC and create a new entry:

| Field    | Value                                    |
|----------|------------------------------------------|
| Title    | CDE Artifactory (or any name you prefer) |
| Username | Your DevOpsBase username                 |
| Password | Your Artifactory reference token         |
| URL      | `https://artifactory.devopsbase.com`     |

**Important:** The URL field must include `https://` and match exactly what you'll use in `settings.xml`.

### 3. Update Maven settings.xml

Edit `~/.m2/settings.xml` and add/update the server entry:

```xml
<settings>
  <servers>
    <server>
      <id>int-unclass-distops-nosync-mvn-virtual</id>
      <username>your-devopsbase-username</username>
      <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
    </server>
  </servers>
  
  <!-- Your existing mirrors, profiles, etc. -->
</settings>
```

**Critical:** The server `<id>` must match your mirror ID or repository ID that you're authenticating to.

### 4. First-Time Pairing

1. Make sure KeePassXC is running and your database is unlocked
2. Run any Maven command: `mvn dependency:resolve`
3. KeePassXC will show a popup asking to authorize the connection
4. Give it a name like `maven-access` and approve
5. Check "Remember this decision" to avoid future prompts

### 5. Test

Run a Maven build that requires Artifactory access:

```bash
cd your-maven-project
mvn clean install
```

You should see dependencies downloading without authentication errors.

## How It Works

```
┌─────────────┐
│   Maven     │
│ settings.xml│
│             │
│ password:   │
│ {[type=     │
│ keepassxc]  │
│ https://... │
└──────┬──────┘
       │
       ├─ Maven loads extension from ~/.mavenrc
       │
       ▼
┌──────────────────┐        ┌─────────────┐
│ KeePassXC        │◄───────┤  KeePassXC  │
│ Maven Extension  │ pairing│  Database   │
│                  │        │             │
│ 1. Reads server  │        │ - Username  │
│    config        │        │ - Password  │
│ 2. Searches      │        │ - URL       │
│    KeePassXC     │        └─────────────┘
│ 3. Returns pwd   │
└──────────────────┘
```

1. Maven reads `settings.xml` and encounters `{[type=keepassxc]...}` syntax
2. The extension connects to KeePassXC via native messaging protocol
3. Extension searches for entry matching the URL
4. KeePassXC returns the password to Maven
5. Maven uses the password to authenticate to Artifactory

## Configuration Files

### ~/.mavenrc
```bash
# Load KeePassXC Maven extension
MAVEN_OPTS="$MAVEN_OPTS -Dmaven.ext.class.path=${HOME}/.m2/extensions/keepassxc-extension.jar:${HOME}/.m2/extensions/commons-lang3.jar"
```

### ~/.m2/settings-security.xml
```xml
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
```

### ~/.m2/settings.xml (server section)
```xml
<servers>
  <server>
    <id>int-unclass-distops-nosync-mvn-virtual</id>
    <username>jhaynes</username>
    <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
  </server>
</servers>
```

## Password Syntax Options

The extension supports various search criteria:

**By URL (default):**
```xml
<password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
```

**By Title:**
```xml
<password>{[type=keepassxc,where:title=CDE Artifactory]https://artifactory.devopsbase.com}</password>
```

**By Username:**
```xml
<password>{[type=keepassxc,where:username=jhaynes]https://artifactory.devopsbase.com}</password>
```

**By Custom Attribute:**
```xml
<password>{[type=keepassxc,where:customAttr=value]https://artifactory.devopsbase.com}</password>
```

## Token Rotation

When your Artifactory token expires (daily):

1. Run `refresh-token.sh` to get a new token
2. The script automatically updates the KeePassXC entry
3. Maven will use the new token on the next build
4. No changes to `settings.xml` required

## Troubleshooting

### 401 Unauthorized Error

**Problem:** Maven can't authenticate to Artifactory

**Solutions:**
1. Verify the server `<id>` in `settings.xml` matches your mirror or repository ID
2. Check that the username in `settings.xml` matches the KeePassXC entry
3. Verify the token in KeePassXC is current and valid

### No Logins Found Error

**Problem:** Extension can't find the KeePassXC entry

**Solutions:**
1. Verify the URL in KeePassXC entry exactly matches `settings.xml`
2. Must include `https://` in both places
3. Check that KeePassXC is unlocked (not just running)
4. Try searching by title: `{[type=keepassxc,where:title=CDE Artifactory]https://...}`

### KeePassXC Pairing Prompt Every Time

**Problem:** Maven asks to pair with KeePassXC on every run

**Solutions:**
1. Check that `~/.m2/settings-security.xml` exists with KeePassXC configuration
2. Verify `~/.m2/keepassxc-security-maven-extension-credentials` file exists
3. When pairing, make sure to check "Remember this decision"
4. Check file permissions on credentials file: `chmod 600 ~/.m2/keepassxc-security-maven-extension-credentials`

### Extension Not Loading

**Problem:** Maven doesn't recognize the KeePassXC syntax

**Solutions:**
1. Verify `~/.mavenrc` contains the extension configuration
2. Check that JARs exist in `~/.m2/extensions/`
3. Try running `source ~/.mavenrc` then test Maven
4. Restart your terminal/shell

### Database Unlock Timeout

**Problem:** Maven waits 2 minutes for KeePassXC to unlock

**Solutions:**
1. Unlock KeePassXC before running Maven
2. Adjust timeout in `settings-security.xml`:
```xml
<property>
  <name>unlockMaxWaitTime</name>
  <value>PT30S</value>  <!-- 30 seconds -->
</property>
```

## Advanced Configuration

### Custom Credentials File Location

```xml
<settingsSecurity>
  <configurations>
    <configuration>
      <name>keepassxc</name>
      <properties>
        <property>
          <name>credentialsStoreFile</name>
          <value>/path/to/custom/credentials</value>
        </property>
      </properties>
    </configuration>
  </configurations>
</settingsSecurity>
```

### Fail Mode Configuration

Choose what happens when KeePassXC is unavailable:

```xml
<property>
  <name>failMode</name>
  <value>EXCEPTION</value>  <!-- or EMPTY_PASSWORD (default) -->
</property>
```

- `EMPTY_PASSWORD`: Continue with empty password (fails gracefully)
- `EXCEPTION`: Throw error immediately

### Multiple Repositories

You can use the same KeePassXC entry for multiple servers:

```xml
<servers>
  <server>
    <id>central</id>
    <username>jhaynes</username>
    <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
  </server>
  <server>
    <id>snapshots</id>
    <username>jhaynes</username>
    <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
  </server>
  <server>
    <id>int-unclass-distops-nosync-mvn-virtual</id>
    <username>jhaynes</username>
    <password>{[type=keepassxc]https://artifactory.devopsbase.com}</password>
  </server>
</servers>
```

## Uninstalling

To remove the KeePassXC Maven integration:

1. Remove extension configuration from `~/.mavenrc`:
   ```bash
   # Remove or comment out the MAVEN_OPTS line
   ```

2. Restore plaintext passwords in `~/.m2/settings.xml`:
   ```xml
   <password>your-token-here</password>
   ```

3. (Optional) Remove extension files:
   ```bash
   rm -rf ~/.m2/extensions
   rm ~/.m2/keepassxc-security-maven-extension-credentials
   ```

## Security Considerations

- **Pairing credentials** are stored in `~/.m2/keepassxc-security-maven-extension-credentials`
  - This file contains encrypted keys for communicating with KeePassXC
  - Keep it secure (default permissions: 600)
  - If compromised, revoke the pairing in KeePassXC settings

- **Database must be unlocked** for Maven to work
  - KeePassXC must be running with database open
  - Consider auto-lock timeout settings in KeePassXC

- **No plaintext passwords** in Maven configuration
  - Tokens only exist in KeePassXC encrypted database
  - `settings.xml` only contains the search syntax

## References

- [KeePassXC Security Maven Extension](https://github.com/causalnet/keepassxc-security-maven-extension)
- [Maven Password Encryption Guide](https://maven.apache.org/guides/mini/guide-encryption.html)
- [Maven Settings Reference](https://maven.apache.org/settings.html)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the extension documentation: https://github.com/causalnet/keepassxc-security-maven-extension
3. Contact your team's DevOps support
