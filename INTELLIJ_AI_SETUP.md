# IntelliJ AI Assistant Setup (DevoxxGenie + claude-agent-acp)

This guide explains how to set up AI assistants in IntelliJ IDEA using the same LiteLLM proxy configuration as Claude Code in the terminal.

## Overview

Two tools work together to bring Claude Agent SDK functionality to IntelliJ:

1. **claude-agent-acp** - Bridge between Claude Agent SDK and Agent Client Protocol (ACP)
2. **DevoxxGenie** - IntelliJ IDEA plugin that provides AI assistant features and supports ACP

**Key Advantage:** Both tools use the **same environment variables** as Claude Code, providing unified configuration across terminal and IDE.

## Prerequisites

- **Node.js and npm** installed
- **IntelliJ IDEA** (Community or Ultimate Edition)
- **Claude Code environment variables** configured (see [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md))
- **LiteLLM proxy access** at `https://litellm.csde.caci.com`

## Part 1: Install claude-agent-acp

### What is claude-agent-acp?

An ACP (Agent Client Protocol) adapter that:
- Wraps the Claude Agent SDK (used by Claude Code)
- Exposes functionality via JSON-RPC 2.0 protocol
- Can be called from any ACP-compatible client (like DevoxxGenie)

### Installation

```bash
# Install globally
npm install -g @agentclientprotocol/claude-agent-acp

# Verify installation
which claude-agent-acp
# Should output: /usr/local/bin/claude-agent-acp (or similar)

# Check version
claude-agent-acp --version
```

**Note:** The npm package name is `@agentclientprotocol/claude-agent-acp` but the executable is `claude-agent-acp` (no leading `@`).

### Configuration

**No additional configuration needed!**

claude-agent-acp automatically reads the same environment variables as Claude Code:
- `ANTHROPIC_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_CUSTOM_HEADERS`
- `ANTHROPIC_MODEL`

**Verify environment variables are set:**

```bash
# These should already be set via ~/.zprofile_ai
echo $ANTHROPIC_BASE_URL
# Output: https://litellm.csde.caci.com

echo $ANTHROPIC_AUTH_TOKEN
# Output: sk-7DSAcjN_fAC9Guw49zQzhw

echo $ANTHROPIC_CUSTOM_HEADERS
# Output: x-litellm-customer-id: <your.email@caci.com>
```

If not set, source the configuration:
```bash
source ~/.zprofile_ai
```

### Testing claude-agent-acp

The tool expects JSON-RPC 2.0 communication over stdin/stdout, so direct CLI testing is limited:

```bash
# Verify it starts without errors (will wait for JSON-RPC input)
claude-agent-acp
# Press Ctrl+C to exit

# Check if it can find the configuration
echo $ANTHROPIC_BASE_URL && claude-agent-acp --help
```

**Full testing requires an ACP client (like DevoxxGenie).**

## Part 2: Install DevoxxGenie Plugin

### What is DevoxxGenie?

- Free, open-source AI code assistant for IntelliJ IDEA
- Supports multiple LLM providers (Anthropic, OpenAI, local models)
- Features: chat interface, agent mode, code completion, RAG, security scanning
- Built-in ACP support for external agents like claude-agent-acp

### Installation

**Method 1: From JetBrains Marketplace**

1. Open IntelliJ IDEA
2. Go to Settings (⌘, on Mac, Ctrl+Alt+S on Windows/Linux)
3. Navigate to Plugins
4. Search for "DevoxxGenie"
5. Click Install
6. Restart IntelliJ IDEA

**Method 2: From Plugin Website**

1. Visit [JetBrains Marketplace - DevoxxGenie](https://plugins.jetbrains.com/plugin/24169-devoxxgenie)
2. Download the plugin
3. In IntelliJ: Settings → Plugins → ⚙️ → Install Plugin from Disk
4. Select the downloaded file
5. Restart IntelliJ IDEA

## Part 3: Configure DevoxxGenie with claude-agent-acp

### Approach A: ACP Runner Configuration (Recommended)

This approach uses claude-agent-acp as a bridge, providing full Claude Agent SDK features.

#### Step 1: Launch IntelliJ from Terminal

**Important:** IntelliJ must inherit environment variables from the shell.

```bash
# Source the configuration (if not already in current shell)
source ~/.zprofile

# Launch IntelliJ from terminal
open -a "IntelliJ IDEA"
```

**Alternative:** Add environment variables to IntelliJ's launch configuration (see Troubleshooting section)

#### Step 2: Configure ACP Runner

1. Open IntelliJ IDEA
2. Go to Settings (⌘,) → Tools → DevoxxGenie
3. Find the "CLI/ACP Runners" section
4. Click "Add" or "+" to create a new runner
5. Configure:
   - **Type:** Select "Claude" from dropdown
   - **Name:** `Claude (ACP)` (or any name you prefer)
   - **Executable Path:** `claude-agent-acp`
     - Should auto-fill when you select "Claude" type
     - If not, find path: `which claude-agent-acp`
   - **Arguments:** Leave empty (not needed)
   - **Environment Variables:** Leave empty to inherit from shell
     - Or explicitly set:
       ```
       ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
       ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
       ANTHROPIC_CUSTOM_HEADERS=x-litellm-customer-id: <your.email@caci.com>
       ```
6. Click "Test Connection" to verify ACP handshake
   - Should show "Connection successful" or similar
7. Click OK to save

#### Step 3: Use Claude via ACP

1. Open the DevoxxGenie panel (usually on right side of IntelliJ)
2. In the model/provider dropdown, select "Claude (ACP)"
3. Type a query in the chat interface
4. Verify responses come from claude-agent-acp (check for streaming responses)

### Approach B: Direct Anthropic Configuration (Alternative)

This approach connects DevoxxGenie directly to the LiteLLM proxy without using claude-agent-acp.

#### Configuration

1. Open IntelliJ IDEA
2. Go to Settings (⌘,) → Tools → DevoxxGenie
3. In the main configuration:
   - **LLM Provider:** Select "Anthropic" from dropdown
   - **API Key:** `sk-7DSAcjN_fAC9Guw49zQzhw`
   - **Custom Endpoint URL:** `https://litellm.csde.caci.com`
   - **Custom Headers:**
     - Key: `x-litellm-customer-id`
     - Value: `<your.email@caci.com>`
   - **Model:** `anthropic.claude-sonnet-4-5-20250929-v1:0`
4. Click "Test" or "Validate" to verify connection
5. Click OK to save

#### Usage

1. Open DevoxxGenie panel
2. Select "Anthropic" from provider dropdown
3. Start chatting

**Pros:**
- Simpler setup (no claude-agent-acp dependency)
- Direct connection to LiteLLM
- GUI configuration

**Cons:**
- Manual configuration per IntelliJ installation
- No Agent SDK features (agent mode, parallel sub-agents)
- No automatic sync with terminal environment

## Features and Usage

### Chat Interface

1. Open DevoxxGenie panel (View → Tool Windows → DevoxxGenie)
2. Type questions or requests
3. Get streaming responses with syntax highlighting
4. Conversation history maintained per session

### Agent Mode

**Requirements:** Using ACP runner configuration (Approach A)

1. Enable in DevoxxGenie settings
2. Agent can autonomously explore codebase
3. Read-only tools: `read_file`, `list_files`, `search_files`
4. Write tools: `write_file`, `edit_file`
5. Execution: `run_command`

### Parallel Sub-Agents

Spawn up to 10 concurrent AI assistants, each with different models:

1. Configure multiple ACP runners or LLM providers
2. Use `/spawn` command (check DevoxxGenie docs)
3. Each sub-agent works independently

### Code Completion

**Requires:** Ollama or LM Studio with FIM (Fill-in-the-Middle) models

1. Settings → DevoxxGenie → Inline Completion
2. Configure Ollama endpoint
3. Select FIM-compatible model
4. Enable inline suggestions

### Project Context

Add source code to prompts:

1. Use Project Scanner in DevoxxGenie settings
2. Select directories/files to include
3. Configure filtering (file types, size limits)

## Configuration Comparison

| Feature | Approach A (ACP) | Approach B (Direct) |
|---------|------------------|---------------------|
| Uses claude-agent-acp | ✅ Yes | ❌ No |
| Uses Claude Agent SDK | ✅ Yes | ❌ No |
| Inherits env vars | ✅ Yes | ⚠️ Manual |
| Agent mode | ✅ Full | ⚠️ Limited |
| Parallel sub-agents | ✅ Up to 10 | ⚠️ Limited |
| Streaming responses | ✅ Yes | ✅ Yes |
| Configuration sync | ✅ Automatic | ❌ Manual |
| Setup complexity | ⚠️ Medium | ✅ Simple |

## Troubleshooting

### claude-agent-acp Not Found

**Symptom:** IntelliJ can't find the executable

**Check:**
```bash
which claude-agent-acp
# Should output path like: /usr/local/bin/claude-agent-acp
```

**Solutions:**
1. **Not installed:** Run `npm install -g @agentclientprotocol/claude-agent-acp`
2. **npm bin not in PATH:** Add npm global bin to PATH:
   ```bash
   echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.zprofile
   source ~/.zprofile
   ```
3. **Use full path in DevoxxGenie:** Copy the output of `which claude-agent-acp` and paste into executable path field

### Environment Variables Not Loaded

**Symptom:** Authentication errors, wrong endpoint, or "ANTHROPIC_BASE_URL not set"

**Cause:** IntelliJ launched without inheriting shell environment

**Solution 1: Launch from Terminal (Recommended)**
```bash
source ~/.zprofile  # Load environment variables
open -a "IntelliJ IDEA"  # Launch IntelliJ
```

**Solution 2: Set in ACP Runner Configuration**

In DevoxxGenie ACP runner settings, explicitly set environment variables:
```
ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
ANTHROPIC_CUSTOM_HEADERS=x-litellm-customer-id: <your.email@caci.com>
```

**Solution 3: Add to IntelliJ VM Options**

1. Help → Edit Custom VM Options
2. Add (replace with your values):
   ```
   -Dide.environment.variables=ANTHROPIC_BASE_URL=https://litellm.csde.caci.com;ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
   ```
3. Restart IntelliJ

**Solution 4: LaunchAgent (macOS only)**

Create `~/Library/LaunchAgents/com.jetbrains.intellij.env.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jetbrains.intellij.env</string>
  <key>ProgramArguments</key>
  <array>
    <string>sh</string>
    <string>-c</string>
    <string>launchctl setenv ANTHROPIC_BASE_URL https://litellm.csde.caci.com</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
```

Load: `launchctl load ~/Library/LaunchAgents/com.jetbrains.intellij.env.plist`

### ACP Handshake Failure

**Symptom:** "Connection failed" or "ACP handshake failed" when testing connection

**Check:**
1. claude-agent-acp is installed and in PATH
2. Environment variables are set (claude-agent-acp needs them)
3. IntelliJ logs: Help → Show Log in Finder/Explorer

**Test manually:**
```bash
# Start claude-agent-acp
claude-agent-acp

# Send initialization (JSON-RPC 2.0)
# Should respond with capabilities
# Press Ctrl+C to exit
```

**Solutions:**
1. Restart IntelliJ after installing claude-agent-acp
2. Check IntelliJ logs for error messages
3. Verify environment variables: `env | grep ANTHROPIC`

### LiteLLM Authentication Errors

**Symptom:** 401 Unauthorized or 403 Forbidden

**Check:**
```bash
# Test connection manually
curl -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
     -H "x-litellm-customer-id: <your.email@caci.com>" \
     https://litellm.csde.caci.com/v1/models
```

**Solutions:**
1. Token expired - contact CACI IT for new token
2. Wrong base URL - verify `https://litellm.csde.caci.com` (no trailing slash)
3. Custom header format wrong - check email address

### Model Not Found

**Symptom:** "Model not available" or "Invalid model name"

**Check:** Model name in configuration: `anthropic.claude-sonnet-4-5-20250929-v1:0`

**Solutions:**
1. Verify model name exactly matches (case-sensitive)
2. Check available models:
   ```bash
   curl -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
        https://litellm.csde.caci.com/v1/models
   ```
3. Contact CACI IT if model is not available

### DevoxxGenie Panel Not Visible

**Symptom:** Can't find DevoxxGenie in IntelliJ

**Solutions:**
1. View → Tool Windows → DevoxxGenie
2. Right-click toolbar → Show "DevoxxGenie"
3. Verify plugin is installed: Settings → Plugins → Installed

## Security Considerations

### API Token Exposure

**Same security considerations as Claude Code:**
- Token stored in plaintext (`~/.zprofile_ai` or IntelliJ settings)
- Visible in environment variables
- File permissions: `chmod 600 ~/.zprofile_ai`

**Additional for IntelliJ:**
- Settings stored in IntelliJ config directory
- Not encrypted by default
- Consider using environment variables instead of storing in settings

### Network Security

**All traffic encrypted:**
- TLS connection to LiteLLM proxy
- No direct connection to Anthropic API
- Customer ID header for usage tracking

### Privacy

**DevoxxGenie privacy settings:**
- Anonymous usage analytics (can be disabled in settings)
- Code is sent to LLM provider (via proxy)
- Conversation history stored locally in IntelliJ

**Disable analytics:**
1. Settings → Tools → DevoxxGenie
2. Find Privacy section
3. Uncheck analytics options

## Advanced Features

### Model Context Protocol (MCP)

DevoxxGenie supports MCP for accessing external tools:

1. Settings → Tools → DevoxxGenie → MCP
2. Add MCP servers (STDIO, HTTP SSE, or HTTP transport)
3. Configure with `mcpServers` JSON format
4. Import/export configurations

**Note:** MCP is for external tools, not for AI provider connection

### Custom Prompts

Create custom prompt templates:

1. DevoxxGenie panel → Settings icon
2. Add custom prompts for common tasks
3. Use variables: `{selection}`, `{filename}`, etc.

### Security Scanning

Integrate security tools:

1. Settings → Tools → DevoxxGenie → Security
2. Configure paths for:
   - Gitleaks (secrets detection)
   - OpenGrep (SAST)
   - Trivy (dependency scanning)
3. Scan code directly from DevoxxGenie panel

## References

- [DevoxxGenie Documentation](https://genie.devoxx.com/docs)
- [claude-agent-acp GitHub](https://github.com/agentclientprotocol/claude-agent-acp)
- [Agent Client Protocol Specification](https://github.com/agentclientprotocol/acp-spec)
- [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md) - Terminal Claude Code setup
- [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview)

## Getting Help

**For issues with:**
- **claude-agent-acp** - GitHub issues or caci-tools repository
- **DevoxxGenie** - Plugin GitHub or JetBrains support
- **LiteLLM proxy/tokens** - CACI IT Help Desk
- **IntelliJ IDEA** - JetBrains support

## Summary

**Recommended Setup:**
1. Install claude-agent-acp: `npm install -g @agentclientprotocol/claude-agent-acp`
2. Install DevoxxGenie plugin in IntelliJ
3. Launch IntelliJ from terminal: `source ~/.zprofile && open -a "IntelliJ IDEA"`
4. Configure ACP runner in DevoxxGenie settings
5. Test connection and start using AI features

**Key Advantages:**
- ✅ Same configuration as Claude Code (unified)
- ✅ Full Claude Agent SDK features
- ✅ Agent mode with autonomous exploration
- ✅ Parallel sub-agents for complex tasks
- ✅ Environment variable inheritance (no manual config)
