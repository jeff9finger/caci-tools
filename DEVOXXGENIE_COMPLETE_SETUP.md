# DevoxxGenie Complete Setup Guide

Complete configuration guide for DevoxxGenie IntelliJ IDEA plugin using CACI LiteLLM proxy with Claude Sonnet 4.5.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Core Configuration](#core-configuration)
  - [LiteLLM Proxy Setup](#litellm-proxy-setup)
  - [CLI Runners Setup](#cli-runners-setup)
  - [Provider Selection](#provider-selection)
- [Agent Mode Configuration](#agent-mode-configuration)
  - [Agent Tools](#agent-tools)
  - [Sub-Agents](#sub-agents)
  - [Approval Workflows](#approval-workflows)
- [Event Automations](#event-automations)
- [Custom Prompts](#custom-prompts)
- [Inline Completion](#inline-completion)
- [RAG Configuration](#rag-configuration)
- [MCP Settings](#mcp-settings)
- [Web Search](#web-search)
- [Security Scanning](#security-scanning)
- [Advanced Settings](#advanced-settings)
- [Troubleshooting](#troubleshooting)
- [Reference Configuration](#reference-configuration)

## Overview

**What is DevoxxGenie?**
- Free, open-source AI code assistant for IntelliJ IDEA
- Multi-provider support (Anthropic, OpenAI, Ollama, custom endpoints)
- Agent Mode with autonomous code exploration (BETA)
- Features: chat, code completion, RAG, security scanning, event automations

**Architecture:**
```
IntelliJ IDEA
    ↓
DevoxxGenie Plugin
    ↓
CLI Runners (claude-agent-acp)
    ↓
LiteLLM Proxy (https://litellm.csde.caci.com)
    ↓
AWS Bedrock → Claude Sonnet 4.5
```

**Why CLI Runners over Direct API?**
- Bypasses langchain4j library (avoids temperature/top_p parameter conflicts)
- Full Claude Agent SDK features
- Inherits environment variables automatically
- No manual token management in UI
- Better streaming response handling

## Prerequisites

### Required Software

1. **IntelliJ IDEA** (Community or Ultimate)
   - Version 2024.1 or higher recommended
   - Check: Help → About

2. **Node.js and npm**
   ```bash
   node --version  # v18.x or higher
   npm --version   # v9.x or higher
   ```

3. **claude-agent-acp** (ACP bridge for Claude Agent SDK)
   ```bash
   npm install -g @agentclientprotocol/claude-agent-acp
   which claude-agent-acp  # Verify installation
   ```

4. **Docker** (optional, for RAG)
   ```bash
   docker --version  # 24.x or higher
   ```

5. **Ollama** (optional, for inline completion)
   ```bash
   ollama --version
   ollama list  # Check installed models
   ```

### Environment Variables

**Required for CLI Runners:**

Add to `~/.zprofile` (or `~/.zshrc`, `~/.bashrc`):

```bash
# LiteLLM Proxy Configuration
export ANTHROPIC_BASE_URL="https://litellm.csde.caci.com"
export ANTHROPIC_AUTH_TOKEN="sk-7DSAcjN_fAC9Guw49zQzhw"
export ANTHROPIC_CUSTOM_HEADERS="x-litellm-customer-id: your.email@caci.com"
export ANTHROPIC_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
```

**Verify:**
```bash
source ~/.zprofile
echo $ANTHROPIC_BASE_URL     # Should show: https://litellm.csde.caci.com
echo $ANTHROPIC_AUTH_TOKEN   # Should show: sk-7DSAcjN_fAC9Guw49zQzhw
```

### Network Access

Test LiteLLM proxy access:

```bash
# Test authentication
curl -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
     -H "x-litellm-customer-id: your.email@caci.com" \
     https://litellm.csde.caci.com/v1/models

# Expected: JSON list of available models
```

## Installation

### Method 1: JetBrains Marketplace (Recommended)

1. Open IntelliJ IDEA
2. Settings (⌘, on Mac, Ctrl+Alt+S on Windows/Linux)
3. Navigate to **Plugins**
4. Search for **"DevoxxGenie"**
5. Click **Install**
6. Click **OK** and restart IntelliJ IDEA

### Method 2: Manual Installation

1. Download from [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/24169-devoxxgenie)
2. Settings → Plugins → ⚙️ (gear icon) → **Install Plugin from Disk**
3. Select downloaded `.zip` file
4. Restart IntelliJ IDEA

### Verify Installation

1. View → Tool Windows → **DevoxxGenie**
2. Panel should appear (usually right side)
3. Check: Settings → Tools → **DevoxxGenie** (settings available)

## Core Configuration

### LiteLLM Proxy Setup

**Purpose:** Backup configuration and direct API access (not primary method)

**Configuration:**

1. Settings → Tools → DevoxxGenie → **LLM Settings**
2. Find **CustomOpenAI** section:

   - **Custom OpenAI URL:** `https://litellm.csde.caci.com/v1`
   - **API Key:** `sk-7DSAcjN_fAC9Guw49zQzhw`
   - **Model Name:** `anthropic.claude-sonnet-4-5-20250929-v1:0`
   - **Custom Headers:** Add header
     - Key: `x-litellm-customer-id`
     - Value: `your.email@caci.com`

3. **Temperature:** `0.7`
4. **Top P:** `0.0` (important: AWS Bedrock requires this to be 0 when temperature is set)

**Note:** This configuration is for backup only. Primary method uses CLI Runners (see next section).

### CLI Runners Setup

**Purpose:** Primary method using claude-agent-acp for Agent Mode and chat

**Step 1: Launch IntelliJ from Terminal**

IntelliJ must inherit environment variables:

```bash
# Load environment variables
source ~/.zprofile

# Launch IntelliJ
open -a "IntelliJ IDEA"
```

**Step 2: Configure CLI Runner**

1. Settings → Tools → DevoxxGenie → **CLI/ACP Runners**
2. Click **Add** or **+** button
3. Configure:

   **Type:** `Claude` (select from dropdown)

   **Name:** `Claude` (or `Claude (ACP)`)

   **Executable Path:** `claude-agent-acp`
   - Auto-fills when you select "Claude" type
   - If not, use full path: `/usr/local/bin/claude-agent-acp` (or output of `which claude-agent-acp`)

   **Arguments:** Leave empty

   **MCP Config Flag:** `--mcp-config` (auto-filled)

   **Environment Variables:** Leave empty
   - Inherits from shell: `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, etc.
   - Or explicitly set (if not launching from terminal):
     ```
     ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
     ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
     ANTHROPIC_CUSTOM_HEADERS=x-litellm-customer-id: your.email@caci.com
     ANTHROPIC_MODEL=anthropic.claude-sonnet-4-5-20250929-v1:0
     ```

4. Click **Test Connection**
   - Should show "Connection successful" or similar
   - Verifies ACP handshake with claude-agent-acp

5. Click **OK** to save

### Provider Selection

**For Chat and Agent Mode:**

1. Open DevoxxGenie panel (View → Tool Windows → DevoxxGenie)
2. Find provider dropdown at top of panel
3. Select: **CLI Runners** (not CustomOpenAI, not Ollama)
4. Model dropdown should show: **Claude** (or name you configured)

**Important:** Always use **CLI Runners → Claude** for primary work. CustomOpenAI has parameter conflicts with AWS Bedrock backend.

## Agent Mode Configuration

Agent Mode enables autonomous code exploration and tool execution (BETA feature).

### Enabling Agent Mode

1. Settings → Tools → DevoxxGenie → **Agent Mode (BETA)**
2. **Enable Agent Mode:** ✓ Checked
3. **Auto-approve read-only tools:** ✓ Checked (recommended)
   - Approves: `read_file`, `list_files`, `search_files`, `fetch_page`
4. **Enable debug logs:** ✓ Checked (for troubleshooting)

### Agent Tools

**Built-in Tools (all enabled by default):**

| Tool | Description | Risk | Auto-Approve |
|------|-------------|------|--------------|
| `read_file` | Read file contents | None | ✓ Yes |
| `write_file` | Create new files | High | ✗ No |
| `edit_file` | Modify existing files | High | ✗ No |
| `list_files` | List directory contents | None | ✓ Yes |
| `search_files` | Grep-based search | None | ✓ Yes |
| `run_command` | Execute shell commands | High | ✗ No |
| `run_tests` | Execute test commands | Medium | ✗ No |
| `fetch_page` | Fetch web pages | Low | ✓ Yes |

**Recommended Tool Configuration:**

Keep all tools enabled (flexibility for different tasks).

**Tool Execution Limits:**

- **Max tool calls per prompt:** `50` (increase from default 25)
  - Complex tasks may need more iterations
  - Prevents infinite loops
  - Adjust if agent hits limit during legitimate exploration

- **Tool timeout:** `60000` ms (60 seconds, default)
  - Timeout for individual tool executions
  - Increase for slow file operations or network calls

**PSI Tools (Program Structure Interface):**

- **Enable PSI Tools:** ✓ Checked (recommended)
- Provides semantic code intelligence:
  - `find_class` - Locate class definitions
  - `find_method` - Locate method definitions
  - `find_usages` - Find references
  - `get_call_hierarchy` - Analyze call chains
  - `get_type_hierarchy` - Analyze inheritance

**Test Execution:**

- **Test timeout:** `600000` ms (10 minutes recommended, up from default 5 minutes)
  - Maven/Gradle tests can be slow
  - Integration tests may take longer
  - Agent gets better feedback when tests complete

- **Custom test command:** `mvn test -Dtest={target}`
  - `{target}` placeholder replaced with test class/method
  - Adjust for project build tool:
    - Maven: `mvn test -Dtest={target}`
    - Gradle: `./gradlew test --tests {target}`
    - Specific module: `mvn test -pl module-name -Dtest={target}`

### Sub-Agents

Sub-agents enable parallel exploration tasks.

**Configuration:**

1. Settings → Tools → DevoxxGenie → Agent Mode → **Sub-Agents**

2. **Enable sub-agents:** ✓ Checked

3. **Parallelism:** `1` (default)
   - Number of sub-agents that can run concurrently
   - Increase to 2-3 for parallel exploration (higher token costs)
   - Keep at 1 for sequential execution

4. **Max tool calls per sub-agent:** `100` (recommended, down from default 200)
   - Sub-agents do focused tasks, don't need as many iterations
   - Reduces runaway costs

5. **Default sub-agent provider:** `CLI Runners` (recommended, not "None (Auto-detect)")
   - Ensures consistent behavior
   - Uses same claude-agent-acp setup

6. **Default sub-agent model:** `anthropic.claude-3-haiku-20240307-v1:0` (recommended for cost)
   - Sub-agents do simple tasks (read files, search, summarize)
   - Haiku much cheaper than Sonnet
   - Use Sonnet for complex reasoning, Haiku for data gathering

**Sub-Agent Configuration in XML:**

```xml
<option name="subAgentConfigs">
  <list>
    <SubAgentConfig>
      <option name="modelProvider" value="CustomOpenAI" />
      <option name="modelName" value="anthropic.claude-3-haiku-20240307-v1:0" />
    </SubAgentConfig>
  </list>
</option>
<option name="subAgentModelProvider" value="CLI Runners" />
<option name="subAgentParallelism" value="1" />
```

**Note:** GUI may not show model selector for sub-agents (known limitation). Configure via XML if needed.

### Approval Workflows

**Read-Only Operations (auto-approved if enabled):**
- `read_file` - View source code
- `list_files` - Browse directories
- `search_files` - Grep for patterns
- `fetch_page` - Download documentation

**Write Operations (always require approval):**
- `write_file` - Create files (prompt: "Agent wants to create file X, approve?")
- `edit_file` - Modify files (shows diff)
- `run_command` - Execute shell (shows command)
- `run_tests` - Run tests (shows command)

**Approval Prompt Example:**
```
Agent Mode: Permission Request

Tool: edit_file
File: src/main/java/com/example/App.java
Action: Replace line 42 with new implementation

[Show Diff] [Approve] [Deny] [Deny All]
```

**Best Practices:**
- ✓ Auto-approve read-only (safe, speeds up exploration)
- ✓ Always review write operations (check diffs carefully)
- ✓ Be cautious with `run_command` (arbitrary shell execution)
- ✓ Enable debug logs (understand what agent is doing)

## Event Automations

Automatically trigger AI agents on specific IDE events (BETA feature).

### Available Events

Settings → Tools → DevoxxGenie → **Event Automations (BETA)**

**Built-in Event Mappings:**

1. **BEFORE_COMMIT → Code Review Agent**
   - Trigger: Before git commit
   - Agent: `CODE_REVIEW`
   - Prompt: Review code changes for bugs, security, style violations
   - Use case: Pre-commit quality gate

2. **BUILD_FAILED → Build Fix Agent**
   - Trigger: Maven/Gradle build fails
   - Agent: `BUILD_FIX`
   - Prompt: Analyze build errors, identify root cause, propose fix
   - Use case: Automatic build troubleshooting

3. **TEST_FAILED → Debug Agent**
   - Trigger: Test execution fails
   - Agent: `DEBUG`
   - Prompt: Analyze stack trace, identify root cause, suggest fix
   - Use case: Automatic test failure analysis

4. **FILE_OPENED → Explainer Agent**
   - Trigger: Open file in editor
   - Agent: `EXPLAINER`
   - Prompt: Summarize file purpose, key methods, architecture fit
   - Use case: Onboarding, unfamiliar code exploration

### Recommended Configuration

**Enable selectively:**

- **BEFORE_COMMIT:** ✓ Enabled (good pre-commit hook)
  - Catches common bugs before commit
  - Low overhead (only runs on commit, not on every save)

- **BUILD_FAILED:** ✓ Enabled (helpful for build errors)
  - Saves time diagnosing build issues
  - Particularly useful for complex dependency errors

- **TEST_FAILED:** ✓ Enabled (good for test troubleshooting)
  - Helps debug test failures faster
  - Useful for understanding flaky tests

- **FILE_OPENED:** ✗ Disabled (too noisy, recommended)
  - Fires on every file open (high token costs)
  - Interrupts workflow with summaries
  - Better to manually ask for explanations when needed

**How to Disable FILE_OPENED:**

1. Settings → Tools → DevoxxGenie → Event Automations (BETA)
2. Find **FILE_OPENED** mapping
3. Click **Delete** or **Disable** button
4. Click **OK** to save

### Custom Event Prompts

Customize prompts for each event:

1. Settings → Tools → DevoxxGenie → Event Automations
2. Select event mapping
3. Edit **Prompt** field
4. Use variables:
   - `{{context}}` - Event-specific context (diff, errors, file content)
   - `{{files}}` - Affected file paths
   - `{{error}}` - Error message (for failed events)

**Example Custom BEFORE_COMMIT Prompt:**
```
Review the following code changes:

{{context}}

Check for:
1. Null pointer exceptions
2. SQL injection vulnerabilities
3. Hardcoded credentials
4. Missing error handling
5. Style violations (from .editorconfig)

Be specific about file names and line numbers.
Only report actual issues, not nitpicks.
```

## Custom Prompts

Reusable prompt templates for common tasks.

### Default Custom Prompts

Settings → Tools → DevoxxGenie → **Custom Prompts**

**Built-in prompts:**

| Name | Prompt | Usage |
|------|--------|-------|
| `/test` | Write a unit test for this code using JUnit | Select code, run `/test` |
| `/explain` | Break down the code in simple terms for a junior developer | Select code, run `/explain` |
| `/review` | Review the selected code, can it be improved or are there bugs? | Select code, run `/review` |
| `/tdg` | Give me a SINGLE FILE COMPLETE Java implementation that will pass this test | Select test, run `/tdg` |
| `/find` | Perform semantic search using RAG (requires RAG enabled) | Run `/find <query>` |
| `/help` | Display help and available commands | Run `/help` |
| `/init` | Initialize or recreate DEVOXXGENIE.md file | Run `/init` |

### Adding Custom Prompts

**Example: Add "/optimize" command**

1. Settings → Tools → DevoxxGenie → Custom Prompts
2. Click **Add** or **+** button
3. Configure:
   - **Name:** `optimize`
   - **Prompt:** `Analyze this code for performance bottlenecks. Suggest optimizations for time complexity, memory usage, and resource management. Explain trade-offs.`
4. Click **OK** to save

**Usage in chat:**
```
# Select code in editor
/optimize
```

**Variables in Prompts:**

- `{selection}` - Currently selected text in editor
- `{filename}` - Active file name
- `{project}` - Project name
- `{language}` - File language (Java, Kotlin, etc.)

**Example with variables:**
```
Name: document
Prompt: Generate JavaDoc for this {language} code in file {filename}:

{selection}

Include:
- Method description
- @param tags with descriptions
- @return tag
- @throws tags for exceptions
```

## Inline Completion

AI-powered code completion using Fill-in-the-Middle (FIM) models.

### Requirements

- **Ollama** running locally
- **FIM-compatible model** installed (e.g., `deepseek-coder:6.7b`)

### Setup

**Step 1: Install Ollama and Model**

```bash
# Install Ollama (if not installed)
# Download from: https://ollama.com

# Pull FIM-compatible model
ollama pull deepseek-coder:6.7b

# Verify model
ollama list | grep deepseek-coder
```

**Step 2: Configure in DevoxxGenie**

1. Settings → Tools → DevoxxGenie → **Inline Completion**
2. Configure:
   - **Enable inline completion:** ✓ Checked
   - **Provider:** `Ollama`
   - **Model:** `deepseek-coder:6.7b`
   - **Ollama URL:** `http://localhost:11434` (default)
   - **Trigger mode:** `Automatic` (or `Manual` for Ctrl+Space trigger)
   - **Debounce delay:** `500` ms (wait time before triggering)
   - **Max tokens:** `100` (completion length)

3. Click **Test** to verify connection
4. Click **OK** to save

### Supported Models

**Recommended FIM models:**

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| `deepseek-coder:6.7b` | 6.7B | Fast | Good | General coding |
| `deepseek-coder:33b` | 33B | Medium | Excellent | Complex code |
| `codellama:7b-code` | 7B | Fast | Good | General coding |
| `starcoder2:7b` | 7B | Fast | Good | Multi-language |

**Pull model:**
```bash
ollama pull <model-name>
```

### Usage

**Automatic Mode:**
1. Start typing in editor
2. Pause for debounce delay (500ms default)
3. Inline suggestion appears in gray text
4. Press **Tab** to accept, **Esc** to dismiss

**Manual Mode:**
1. Press **Ctrl+Space** (or configured shortcut)
2. Wait for suggestion
3. Press **Tab** to accept

### Performance Tuning

**For faster completions:**
- Use smaller models (6.7B-7B)
- Reduce max tokens (50-75)
- Increase debounce delay (reduce trigger frequency)

**For better quality:**
- Use larger models (13B-33B)
- Increase max tokens (100-150)
- Decrease debounce delay (more responsive)

**Resource considerations:**
- 6.7B model: ~4GB RAM
- 33B model: ~20GB RAM
- GPU acceleration: NVIDIA GPU + CUDA (significant speedup)

## RAG Configuration

Retrieval-Augmented Generation for semantic code search.

### Overview

**What it does:**
- Indexes codebase with embeddings (vector representations)
- Stores in ChromaDB (vector database)
- Enables semantic search: `/find authentication logic`
- Augments Agent Mode with relevant code context

**When to enable:**
- Large codebases (100K+ lines, 1000+ files)
- Semantic/concept-based queries
- Cross-cutting concerns exploration
- Architecture understanding

**When to skip:**
- Small/medium projects (Agent Mode tools sufficient)
- Known file/function names (grep faster)
- Resource constraints (RAM, disk space)
- Rapid development (re-indexing overhead)

### Setup

**See dedicated guide:** [DEVOXXGENIE_RAG_SETUP.md](DEVOXXGENIE_RAG_SETUP.md)

**Quick summary:**

1. **Install ChromaDB:**
   ```bash
   docker pull chromadb/chroma
   docker run -d --name chromadb -p 8000:8000 --restart unless-stopped chromadb/chroma
   ```

2. **Install Nomic Embed model:**
   ```bash
   ollama pull nomic-embed-text
   ```

3. **Configure in IntelliJ:**
   - Settings → Tools → DevoxxGenie → RAG
   - Enable feature: ✓ Checked
   - Chroma DB port: `8000`
   - Minimum score: `0.7`
   - Maximum results: `10`

4. **Index project:**
   - DevoxxGenie panel → Settings → Index Project
   - Wait for completion

5. **Use semantic search:**
   ```
   /find database connection handling
   ```

**Recommendation for most users: Leave RAG disabled**
- Agent Mode + built-in search tools handle most tasks
- RAG adds complexity and resource overhead
- Enable only if you need semantic search capabilities

## MCP Settings

Model Context Protocol for accessing external tools and data sources.

### What is MCP?

- Protocol for connecting LLMs to external tools
- Similar to Function Calling, but standardized
- Supports: STDIO, HTTP SSE, HTTP transport
- Examples: databases, APIs, file systems, web services

### Configuration

Settings → Tools → DevoxxGenie → **MCP Settings**

**Default: Disabled** (no MCP servers configured)

### Adding MCP Servers

**Configuration format (JSON):**

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"],
      "transport": "stdio"
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost/dbname"],
      "transport": "stdio"
    }
  }
}
```

**Configuration location:**

1. Settings → Tools → DevoxxGenie → MCP Settings
2. Click **Edit** or **Import**
3. Paste JSON configuration
4. Click **Save**

### Available MCP Servers

**Official MCP servers:**

- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-postgres` - PostgreSQL database
- `@modelcontextprotocol/server-github` - GitHub API access
- `@modelcontextprotocol/server-google-drive` - Google Drive access
- `@modelcontextprotocol/server-slack` - Slack API access

**Install MCP server:**
```bash
npm install -g @modelcontextprotocol/server-<name>
```

### Security Considerations

**MCP servers have full access to specified resources:**
- File system servers can read/write files
- Database servers can query/modify data
- API servers can make authenticated requests

**Recommendations:**
- Only configure trusted MCP servers
- Use read-only credentials when possible
- Limit file system access to specific directories
- Review agent actions before approval

### Debugging MCP

1. Settings → Tools → DevoxxGenie → MCP Settings
2. **Enable MCP debug logs:** ✓ Checked
3. Help → Show Log in Finder/Explorer → `idea.log`
4. Search for `[MCP]` log entries

## Web Search

Enable web search for documentation, Stack Overflow, API references.

### Configuration

Settings → Tools → DevoxxGenie → **Web search**

**Settings:**

1. **Enable web search:** ✓ Checked (recommended)
   - Allows agent to fetch external documentation
   - Useful for library APIs, framework docs, error messages

2. **Search provider:** Auto-detected
   - DevoxxGenie uses built-in search
   - May integrate with Google, DuckDuckGo, etc.

3. **Max results:** `5` (default)
   - Number of search results to fetch
   - More results = more context but slower

### Usage

**Agent Mode automatically uses web search when needed:**

```
# User query
"How do I use Spring Boot @Transactional annotation?"

# Agent internally:
1. Searches web for "Spring Boot @Transactional annotation"
2. Fetches top 5 results
3. Reads documentation pages
4. Synthesizes answer with code examples
```

**Manual web search (if supported):**
```
/search Spring Boot transactional best practices
```

### Best Practices

- ✓ Enable for modern frameworks (documentation changes frequently)
- ✓ Enable for error message lookup (Stack Overflow, GitHub issues)
- ✗ Disable for air-gapped environments (no internet access)
- ✗ Disable if all documentation is local (internal libraries)

## Security Scanning

Integrate security tools for vulnerability scanning.

### Supported Tools

Settings → Tools → DevoxxGenie → **Security Scanning**

1. **Gitleaks** - Secrets detection
   - Finds hardcoded API keys, passwords, tokens
   - Scans git history and working tree

2. **OpenGrep (Semgrep)** - Static Application Security Testing (SAST)
   - Pattern-based security rules
   - Detects: SQL injection, XSS, insecure deserialization, etc.

3. **Trivy** - Dependency vulnerability scanning
   - Scans dependencies for known CVEs
   - Supports: Maven, Gradle, npm, pip, etc.

### Setup

**Step 1: Install Security Tools**

```bash
# Gitleaks
brew install gitleaks
# or: https://github.com/gitleaks/gitleaks/releases

# Semgrep
pip install semgrep
# or: brew install semgrep

# Trivy
brew install trivy
# or: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
```

**Step 2: Configure in DevoxxGenie**

1. Settings → Tools → DevoxxGenie → Security Scanning
2. For each tool:
   - **Enable:** ✓ Checked
   - **Executable path:** `/usr/local/bin/gitleaks` (or output of `which gitleaks`)
   - **Configuration file:** (optional, custom rules)
   - **Arguments:** (optional, additional flags)

3. Click **Test** to verify each tool
4. Click **OK** to save

### Usage

**From DevoxxGenie Panel:**

1. Open DevoxxGenie panel
2. Click **Security** button or menu
3. Select tool: Gitleaks, Semgrep, or Trivy
4. Wait for scan to complete
5. Review results in panel (findings with file paths and line numbers)

**Agent Mode Integration:**

Agent can automatically run security scans when:
- Reviewing code changes (BEFORE_COMMIT event)
- Analyzing security-sensitive code
- User explicitly requests: "scan for vulnerabilities"

### Interpreting Results

**Gitleaks output:**
```
Finding:     AWS API Key
Secret:      AKIAIOSFODNN7EXAMPLE
File:        src/main/resources/application.properties
Line:        15
Rule:        aws-access-token
```

**Semgrep output:**
```
Finding:     SQL Injection
Severity:    HIGH
File:        src/main/java/com/example/UserDao.java
Line:        42
Rule:        java.sql-injection
Message:     Potential SQL injection vulnerability
```

**Trivy output:**
```
Finding:     CVE-2023-12345
Package:     log4j-core
Version:     2.14.1
Fixed:       2.17.1
Severity:    CRITICAL
Description: Remote code execution vulnerability
```

## Advanced Settings

### LLM Settings

Settings → Tools → DevoxxGenie → **LLM Settings**

**Sampling parameters:**

- **Temperature:** `0.7` (creativity vs consistency)
  - 0.0 = deterministic, repeatable
  - 0.7 = balanced (recommended)
  - 1.0+ = creative, varied

- **Top P:** `0.0` (when using temperature)
  - **Important:** AWS Bedrock requires top_p = 0 when temperature is set
  - Only use one sampling method at a time

- **Max tokens:** Model-dependent
  - Sonnet 4.5: 200K context, 16K output
  - Controls response length

**Streaming:**

- **Enable streaming:** ✓ Checked (recommended)
  - Shows responses as they're generated
  - Better user experience (no waiting for full response)

### Token Cost & Context Window

Settings → Tools → DevoxxGenie → **Token Cost & Context Window**

**Display settings:**

- **Show token calculator button:** ✓ Checked (recommended)
  - Shows token count button in chat
  - Helps estimate costs before submission

- **Show context window warning:** ✓ Checked (recommended)
  - Warns when approaching context limit
  - Prevents truncated responses

**Cost tracking:**

- Displays estimated costs per request
- Based on model pricing (Sonnet 4.5: $3/MTok input, $15/MTok output)
- Track spending over time

### Analytics

Settings → Tools → DevoxxGenie → **Analytics**

**Privacy settings:**

- **Enable analytics:** ❌ Unchecked (recommended)
  - Anonymous usage statistics
  - Helps DevoxxGenie developers improve plugin
  - No code content sent, only event types

- **Analytics client ID:** Auto-generated UUID
  - Anonymous identifier
  - Can reset to new UUID

**Recommendation:** Disable analytics unless you want to support plugin development.

### Appearance

Settings → Tools → DevoxxGenie → **Appearance**

**UI customization:**

- **Show tool activity in chat:** ✓ Checked (recommended)
  - Shows when agent uses tools (read_file, search_files, etc.)
  - Transparency into agent behavior
  - Helpful for understanding agent reasoning

- **Syntax highlighting:** ✓ Enabled (default)
  - Color code in chat responses
  - Language detection automatic

- **Font size:** Inherit from IDE (default)
  - Or set custom size

### System Prompt

Settings → Tools → DevoxxGenie → **System Prompt**

**DEVOXXGENIE.md file:**

- **Create DEVOXXGENIE.md:** ✓ Checked (recommended)
  - Generates project-specific instruction file
  - Located in project root
  - Similar to CLAUDE.md for Claude Code

- **Use DEVOXXGENIE.md in prompt:** ✓ Checked (recommended)
  - Includes file content in system prompt
  - Provides project context to agent
  - Best practices, coding standards, architecture notes

**Example DEVOXXGENIE.md:**
```markdown
# Project: CACI Tools

## Overview
Collection of development tools and documentation for CACI projects.

## Coding Standards
- Java 17
- Spring Boot 3.x
- Maven for builds
- JUnit 5 for tests

## Architecture
- Monorepo structure
- Modular design
- REST APIs using Spring Web
- PostgreSQL database

## Testing
- Run tests: `mvn test`
- Integration tests: `mvn verify`
- Coverage report: `mvn jacoco:report`

## Security
- No hardcoded credentials
- Use application-{env}.properties for config
- All inputs must be validated
- Follow OWASP top 10 guidelines
```

**When to use:**
- Document project-specific patterns
- Define coding standards
- Explain architecture decisions
- List common commands and workflows

## Troubleshooting

### Empty Model Dropdowns

**Symptom:** Sub-agent model/provider dropdowns empty in UI

**Cause:** GUI limitation in DevoxxGenie plugin

**Solution:** Configure via XML (Settings file edit) or use defaults
- Main provider: CLI Runners → Claude (working)
- Sub-agent provider: CustomOpenAI (configured in XML)
- Not critical - functionality works despite UI limitation

### Temperature/Top P Parameter Error

**Symptom:** 
```
litellm.BadRequestError: BedrockException - 
{"message":"The model returned the following errors: 
'temperature' and 'top_p' cannot both be specified for this model. 
Please use only one."}
```

**Cause:** 
- langchain4j library hardcodes both parameters for OpenAI-compatible endpoints
- AWS Bedrock backend rejects this combination

**Solution:** 
- Use **CLI Runners → Claude** provider (not CustomOpenAI)
- CLI Runners uses claude-agent-acp, bypassing langchain4j
- Set Top P to `0.0` in settings

### claude-agent-acp Not Found

**Symptom:** IntelliJ can't find executable

**Check:**
```bash
which claude-agent-acp
# Should output: /usr/local/bin/claude-agent-acp or similar
```

**Solutions:**

1. **Not installed:**
   ```bash
   npm install -g @agentclientprotocol/claude-agent-acp
   ```

2. **npm bin not in PATH:**
   ```bash
   echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.zprofile
   source ~/.zprofile
   ```

3. **Use full path:**
   - Copy output of `which claude-agent-acp`
   - Paste into "Executable Path" field in DevoxxGenie settings

### Environment Variables Not Loaded

**Symptom:** Authentication errors, "ANTHROPIC_BASE_URL not set"

**Cause:** IntelliJ launched without inheriting shell environment

**Solution 1: Launch from Terminal (Recommended)**
```bash
source ~/.zprofile
open -a "IntelliJ IDEA"
```

**Solution 2: Set in CLI Runner Configuration**
- Settings → Tools → DevoxxGenie → CLI/ACP Runners
- Edit "Claude" runner
- Environment Variables section:
  ```
  ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
  ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
  ANTHROPIC_CUSTOM_HEADERS=x-litellm-customer-id: your.email@caci.com
  ```

### Agent Mode Not Working

**Symptom:** Agent tools not executing, no file reads

**Check:**

1. **Agent Mode enabled:**
   - Settings → Tools → DevoxxGenie → Agent Mode (BETA)
   - "Enable Agent Mode" checked

2. **Correct provider selected:**
   - DevoxxGenie panel → Provider dropdown
   - Should show: **CLI Runners** (not CustomOpenAI or Ollama)

3. **claude-agent-acp running:**
   ```bash
   which claude-agent-acp  # Verify installation
   ps aux | grep claude-agent-acp  # Check if running
   ```

4. **Debug logs:**
   - Enable: Settings → Tools → DevoxxGenie → Agent Mode → Enable debug logs
   - View: Help → Show Log in Finder/Explorer → `idea.log`
   - Search for: `[Agent]` or `[ACP]`

### LiteLLM Authentication Errors

**Symptom:** 401 Unauthorized or 403 Forbidden

**Test manually:**
```bash
curl -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
     -H "x-litellm-customer-id: your.email@caci.com" \
     https://litellm.csde.caci.com/v1/models
```

**Solutions:**

1. **Token expired:** Contact CACI IT for new token

2. **Wrong base URL:** Verify `https://litellm.csde.caci.com` (no trailing slash)

3. **Custom header format wrong:** Check email address format

4. **Missing environment variables:**
   ```bash
   env | grep ANTHROPIC
   # Should show ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_CUSTOM_HEADERS
   ```

### DevoxxGenie Panel Not Visible

**Symptom:** Can't find DevoxxGenie in IntelliJ

**Solutions:**

1. View → Tool Windows → **DevoxxGenie**

2. Right-click toolbar → Show "DevoxxGenie"

3. Verify plugin installed: Settings → Plugins → Installed → Search "DevoxxGenie"

4. Restart IntelliJ after installation

## Reference Configuration

### Recommended Settings Summary

**Core:**
- Primary provider: **CLI Runners → Claude**
- Model: **anthropic.claude-sonnet-4-5-20250929-v1:0**
- Temperature: **0.7**
- Top P: **0.0**
- Streaming: **Enabled**

**Agent Mode:**
- Enabled: **Yes**
- Auto-approve read-only: **Yes**
- Max tool calls per prompt: **50**
- Test timeout: **600000 ms** (10 minutes)
- PSI Tools: **Enabled**
- Debug logs: **Enabled**

**Sub-Agents:**
- Provider: **CLI Runners**
- Model: **anthropic.claude-3-haiku-20240307-v1:0**
- Parallelism: **1**
- Max tool calls: **100**

**Event Automations:**
- BEFORE_COMMIT: **Enabled**
- BUILD_FAILED: **Enabled**
- TEST_FAILED: **Enabled**
- FILE_OPENED: **Disabled** (too noisy)

**Optional Features:**
- Inline Completion: **Enabled** (with Ollama + deepseek-coder:6.7b)
- RAG: **Disabled** (unless large codebase)
- Web Search: **Enabled**
- Security Scanning: **Enabled** (if tools installed)
- Analytics: **Disabled**

### XML Configuration File

**Location:**
```
/Users/jeff.haynes_cn/Library/Application Support/JetBrains/IntelliJIdea2026.1/options/DevoxxGenieSettingsPlugin.xml
```

**Key settings to preserve:**
```xml
<application>
  <component name="com.devoxx.genie.ui.SettingsState">
    <!-- Agent Mode -->
    <option name="agentAutoApproveReadOnly" value="true" />
    <option name="agentDebugLogsEnabled" value="true" />
    <option name="agentModeEnabled" value="true" />
    
    <!-- CustomOpenAI Configuration (backup) -->
    <option name="customOpenAIApiKey" value="sk-7DSAcjN_fAC9Guw49zQzhw" />
    <option name="customOpenAIModelName" value="anthropic.claude-sonnet-4-5-20250929-v1:0" />
    <option name="customOpenAIUrl" value="https://litellm.csde.caci.com/v1" />
    
    <!-- CLI Runners (primary) -->
    <option name="cliTools">
      <list>
        <CliToolConfig>
          <option name="executablePath" value="/opt/homebrew/bin/claude" />
          <option name="name" value="Claude" />
          <option name="type" value="CLAUDE" />
        </CliToolConfig>
      </list>
    </option>
    
    <!-- Sampling Parameters -->
    <option name="temperature" value="0.7000000000000001" />
    <option name="topP" value="0.0" />
    
    <!-- Sub-Agents -->
    <option name="subAgentConfigs">
      <list>
        <SubAgentConfig>
          <option name="modelProvider" value="CustomOpenAI" />
        </SubAgentConfig>
      </list>
    </option>
    <option name="subAgentModelProvider" value="CustomOpenAI" />
    <option name="subAgentParallelism" value="1" />
    
    <!-- Test Execution -->
    <option name="testExecutionCustomCommand" value="mvn test -Dtest={target}" />
    
    <!-- MCP -->
    <option name="mcpEnabled" value="true" />
    <option name="mcpDebugLogsEnabled" value="true" />
    
    <!-- Web Search -->
    <option name="isWebSearchEnabled" value="true" />
    
    <!-- UI -->
    <option name="showToolActivityInChat" value="true" />
    <option name="streamMode" value="true" />
    <option name="showCalcTokensButton" value="true" />
    
    <!-- DEVOXXGENIE.md -->
    <option name="createDevoxxGenieMd" value="true" />
    <option name="useDevoxxGenieMdInPrompt" value="true" />
    
    <!-- Analytics -->
    <option name="analyticsEnabled" value="false" />
  </component>
</application>
```

## Related Documentation

- [INTELLIJ_AI_SETUP.md](INTELLIJ_AI_SETUP.md) - Initial DevoxxGenie + claude-agent-acp setup
- [DEVOXXGENIE_RAG_SETUP.md](DEVOXXGENIE_RAG_SETUP.md) - RAG configuration with ChromaDB
- [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md) - Terminal Claude Code setup
- [DevoxxGenie Official Docs](https://genie.devoxx.com/docs)
- [claude-agent-acp GitHub](https://github.com/agentclientprotocol/claude-agent-acp)

## Getting Help

**For issues with:**
- **DevoxxGenie plugin** - [GitHub Issues](https://github.com/devoxx/DevoxxGenieIDEAPlugin/issues)
- **claude-agent-acp** - [GitHub Issues](https://github.com/agentclientprotocol/claude-agent-acp/issues)
- **LiteLLM proxy/tokens** - CACI IT Help Desk
- **IntelliJ IDEA** - [JetBrains Support](https://www.jetbrains.com/support/)

---

## Quick Start Checklist

**Prerequisites:**
- [ ] IntelliJ IDEA installed
- [ ] Node.js and npm installed
- [ ] Environment variables in `~/.zprofile`
- [ ] `npm install -g @agentclientprotocol/claude-agent-acp`

**Installation:**
- [ ] Install DevoxxGenie plugin from Marketplace
- [ ] Restart IntelliJ IDEA

**Configuration:**
- [ ] Launch IntelliJ from terminal: `source ~/.zprofile && open -a "IntelliJ IDEA"`
- [ ] Settings → Tools → DevoxxGenie → CLI/ACP Runners → Add "Claude"
- [ ] Settings → Tools → DevoxxGenie → Agent Mode → Enable
- [ ] DevoxxGenie panel → Select "CLI Runners → Claude"

**Verification:**
- [ ] Chat with agent (ask a simple question)
- [ ] Test Agent Mode (ask to read a file)
- [ ] Check debug logs (Settings → Agent Mode → Enable debug logs)

**Optional:**
- [ ] Configure Ollama for inline completion
- [ ] Install security scanning tools
- [ ] Enable web search
- [ ] Create DEVOXXGENIE.md for project

**You're ready to use DevoxxGenie with full Agent Mode capabilities!**
