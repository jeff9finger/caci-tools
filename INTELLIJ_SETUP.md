# IntelliJ IDEA Setup Guide

Complete setup guide for IntelliJ IDEA with AI assistance and productivity tools for CACI development environment.

## Table of Contents

- [AI Assistant Setup (DevoxxGenie)](#ai-assistant-setup-devoxxgenie)
- [Productivity Tools](#productivity-tools)
  - [Jira Integration](#jira-integration)
- [References](#references)

---

# AI Assistant Setup (DevoxxGenie)

Setup AI code assistant in IntelliJ IDEA using the same LiteLLM proxy configuration as Claude Code in the terminal.

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
# Output: <API_KEY>

echo $ANTHROPIC_CUSTOM_HEADERS
# Output: x-litellm-customer-id: <your.email@caci.com>
```

If not set, source the configuration:
```bash
source ~/.zprofile_ai
```

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

### Step 1: Launch IntelliJ from Terminal

**Important:** IntelliJ must inherit environment variables from the shell.

```bash
# Source the configuration (if not already in current shell)
source ~/.zprofile

# Launch IntelliJ from terminal
open -a "IntelliJ IDEA"
```

**Alternative:** Add environment variables to IntelliJ's launch configuration (see Troubleshooting section)

### Step 2: Configure ACP Runner

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

### Step 3: Use Claude via ACP

1. Open the DevoxxGenie panel (usually on right side of IntelliJ)
2. In the model/provider dropdown, select "Claude (ACP)"
3. Type a query in the chat interface
4. Verify responses come from claude-agent-acp (check for streaming responses)

## Features and Usage

### Chat Interface

1. Open DevoxxGenie panel (View → Tool Windows → DevoxxGenie)
2. Type questions or requests
3. Get streaming responses with syntax highlighting
4. Conversation history maintained per session

### Agent Mode

**Requirements:** Using ACP runner configuration

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

## Advanced DevoxxGenie Features

For comprehensive configuration guide including Agent Mode, RAG, MCP, and all advanced settings, see:

**[DEVOXXGENIE_COMPLETE_SETUP.md](DEVOXXGENIE_COMPLETE_SETUP.md)** - Complete configuration guide

---

# Productivity Tools

## Jira Integration

Integrate Jira issue tracking directly in IntelliJ IDEA for streamlined workflow.

### Jira Integration Plugin (Recommended)

**Third-party plugin with rich UI and advanced features by PLATIS Solutions**

#### Installation

1. Open IntelliJ IDEA
2. Settings (⌘,) → Plugins → Marketplace
3. Search for **"Jira Integration"**
4. Look for publisher: **PLATIS Solutions**
5. Click **Install**
6. Restart IntelliJ IDEA

#### Configuration

1. Settings → Tools → **Jira Integration**
2. Click **+** to add Jira server
3. Configure connection:
   - **Server URL:** Your Jira instance
     - Example: `https://jira.caci.com`
     - Or: `https://caci.atlassian.net`
   - **Username:** Your CACI email
   - **Authentication:** API Token (recommended)
4. Click **Test Connection** to verify
5. Click **OK** to save

**Generate API Token:**
1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Name it: `IntelliJ IDEA`
4. Copy token and paste into IntelliJ settings
5. Store token securely (won't be shown again)

#### Key Features

**Rich Issue Viewer:**
- Browse issues in dedicated tool window
- View/edit issue details (description, comments, attachments)
- Edit fields (status, assignee, priority, labels)
- Add comments and work logs
- View issue history

**JQL Query Support:**
- Run custom JQL queries
- Save favorite queries
- Filter by project, status, assignee
- Example: `project = ABC AND assignee = currentUser() AND status != Done`

**Issue Management:**
- Create new issues from IDE
- Transition issues through workflow
- Log time spent on issues
- Link commits to issues (use `ABC-1234:` format in commit messages)

**Workflow Automation:**
- Start/stop work timers
- Assign issues
- Update custom fields
- Track time automatically

#### Usage Examples

**Open Jira Tool Window:**
- View → Tool Windows → **Jira**
- Or click Jira icon in toolbar

**Browse Issues:**
1. Open Jira tool window
2. Select project from dropdown
3. Use filters or JQL queries
4. Double-click issue to view details

**Link Commit to Issue:**
```
ABC-1234: Fixed authentication bug

- Implemented OAuth2 token refresh
- Added JWT validation
- Updated security configuration
```

#### Integration with DevoxxGenie AI

**Use Jira context in AI prompts:**

1. Open issue in Jira tool window
2. Copy issue description or acceptance criteria
3. Paste into DevoxxGenie chat:

```
Implement this Jira requirement:

[ABC-1234] Add user authentication
- Support OAuth2 and JWT
- Store tokens in HttpOnly cookies
- Implement refresh token rotation

Generate implementation plan and code.
```

**AI-assisted development from Jira:**
- Ask DevoxxGenie to implement features from Jira issues
- Use acceptance criteria as requirements
- Generate tests based on Jira scenarios
- Get code reviews aligned with issue requirements

#### Troubleshooting

**Connection Failed:**
- Verify server URL includes `https://`
- Check API token is valid (regenerate if needed)
- Verify username (email address)
- Ensure VPN connected (if CACI requires it)

**Issues Not Loading:**
- Check JQL query syntax
- Verify project permissions
- Try simpler query: `assignee = currentUser()`
- Refresh issue list

**API Token Not Working:**
- Regenerate at Jira → Profile → Security → API Tokens
- Copy immediately (can't be viewed later)
- For Jira Cloud: Use email as username
- For Jira Server: Use Jira username

#### Security Considerations

**API Token Storage:**
- Stored in IntelliJ credential store (encrypted)
- macOS: Keychain
- Windows: Credential Manager
- Linux: KWallet or GNOME Keyring

**Token Security:**
- API tokens have same permissions as your account
- Can read/write all accessible issues
- Treat like passwords (don't share)
- Rotate every 90 days (recommended)

**VPN Requirements:**
- CACI Jira may require VPN
- Plugin fails if VPN disconnected
- Reconnect VPN and refresh

---

# References

## AI Assistant Documentation
- [DevoxxGenie Documentation](https://genie.devoxx.com/docs)
- [DevoxxGenie Complete Setup](DEVOXXGENIE_COMPLETE_SETUP.md) - Full configuration guide
- [DevoxxGenie RAG Setup](DEVOXXGENIE_RAG_SETUP.md) - Semantic search configuration
- [claude-agent-acp GitHub](https://github.com/agentclientprotocol/claude-agent-acp)
- [Agent Client Protocol Specification](https://github.com/agentclientprotocol/acp-spec)
- [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview)

## Environment Setup
- [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md) - Terminal Claude Code setup
- [MACOS_TROUBLESHOOTING.md](MACOS_TROUBLESHOOTING.md) - macOS-specific issues

## Productivity Tools
- [Jira Integration Plugin](https://plugins.jetbrains.com/search?search=jira%20integration) - JetBrains Marketplace
- [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens) - Generate API tokens

## Getting Help

**For issues with:**
- **claude-agent-acp** - GitHub issues or caci-tools repository
- **DevoxxGenie** - Plugin GitHub or JetBrains support
- **Jira Integration** - PLATIS Solutions support
- **LiteLLM proxy/tokens** - CACI IT Help Desk
- **IntelliJ IDEA** - JetBrains support

---

## Quick Start Summary

### AI Assistant Setup
1. Install claude-agent-acp: `npm install -g @agentclientprotocol/claude-agent-acp`
2. Install DevoxxGenie plugin in IntelliJ
3. Launch IntelliJ from terminal: `source ~/.zprofile && open -a "IntelliJ IDEA"`
4. Configure ACP runner in DevoxxGenie settings
5. Test connection and start using AI features

### Jira Integration Setup
1. Install Jira Integration plugin from Marketplace
2. Generate API token at Atlassian
3. Configure Jira server in Settings → Tools → Jira Integration
4. Test connection and start browsing issues

**Key Advantages:**
- ✅ Same AI configuration as Claude Code (unified environment)
- ✅ Full Claude Agent SDK features (agent mode, autonomous exploration)
- ✅ Parallel sub-agents for complex tasks
- ✅ Jira integration for seamless issue tracking
- ✅ AI-assisted development from Jira requirements
