# Claude Code Setup with LiteLLM Proxy

This guide explains how Claude Code is configured to use CACI's LiteLLM proxy service instead of connecting directly to Anthropic's API.

## Overview

Claude Code in the terminal environment is configured to route all requests through the CACI LiteLLM proxy at `https://litellm.csde.caci.com`. This provides:

- **Centralized authentication** - Single API token managed by CACI IT
- **Usage tracking** - Monitor and control AI usage across teams
- **Cost management** - Organization-level billing and quotas
- **Network compliance** - All traffic goes through approved CACI infrastructure

## Current Configuration

### Environment Variables

Configuration is stored in `~/.zprofile_ai` and automatically loaded when shell sessions start.

**Core Settings:**
```bash
export ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
export ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
export ANTHROPIC_CUSTOM_HEADERS="x-litellm-customer-id: <jeff.haynes@caci.com>"
```

**Model Configuration:**
```bash
export ANTHROPIC_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
export ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
export ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
export CLAUDE_CODE_SUBAGENT_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
```

**Privacy Settings:**
```bash
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export DISABLE_BUG_COMMAND=1
export DISABLE_AUTOUPDATER=1
```

### How It Loads

1. User logs in to macOS
2. `~/.zprofile` is sourced (login shell)
3. `~/.zprofile` contains: `test -e "${HOME}/.zprofile_ai" && source "${HOME}/.zprofile_ai"`
4. Environment variables are set
5. Claude Code reads these variables when launched

## Setup Instructions

### Initial Setup

If you don't already have this configuration:

1. **Create the configuration file:**
   ```bash
   touch ~/.zprofile_ai
   chmod 600 ~/.zprofile_ai  # Secure the file
   ```

2. **Add the configuration:**
   ```bash
   cat >> ~/.zprofile_ai <<'EOF'
   # Claude Code LiteLLM Proxy Configuration
   export ANTHROPIC_BASE_URL=https://litellm.csde.caci.com
   export ANTHROPIC_AUTH_TOKEN=sk-7DSAcjN_fAC9Guw49zQzhw
   export ANTHROPIC_CUSTOM_HEADERS="x-litellm-customer-id: <your.email@caci.com>"
   
   # Model Configuration
   export ANTHROPIC_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
   export ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
   export ANTHROPIC_DEFAULT_HAIKU_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
   export ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
   export CLAUDE_CODE_SUBAGENT_MODEL="anthropic.claude-sonnet-4-5-20250929-v1:0"
   
   # Privacy Settings
   export DISABLE_TELEMETRY=1
   export DISABLE_ERROR_REPORTING=1
   export DISABLE_BUG_COMMAND=1
   export DISABLE_AUTOUPDATER=1
   EOF
   ```

3. **Update your shell profile:**
   
   Add to `~/.zprofile` (if not already present):
   ```bash
   echo 'test -e "${HOME}/.zprofile_ai" && source "${HOME}/.zprofile_ai"' >> ~/.zprofile
   ```

4. **Reload configuration:**
   ```bash
   source ~/.zprofile_ai
   ```

5. **Verify:**
   ```bash
   echo $ANTHROPIC_BASE_URL
   # Should output: https://litellm.csde.caci.com
   ```

### Testing

Test that Claude Code uses the proxy:

```bash
# Check environment variables are set
env | grep ANTHROPIC

# Launch Claude Code (if installed)
claude

# In Claude Code, ask a simple question
# Network traffic should go to litellm.csde.caci.com, not api.anthropic.com
```

## Configuration Details

### Base URL

**Purpose:** Points Claude Code to the LiteLLM proxy instead of Anthropic's API

**Value:** `https://litellm.csde.caci.com`

**How it works:** 
- Claude Code prepends this to all API endpoints
- Example: `/v1/messages` becomes `https://litellm.csde.caci.com/v1/messages`
- LiteLLM proxy forwards requests to Anthropic after authentication

### Auth Token

**Purpose:** Authenticates with the LiteLLM proxy

**Format:** `sk-` followed by random characters

**Security:** 
- Static token managed by CACI IT
- Shared across team members
- Rotated periodically by IT
- Stored in plaintext in `~/.zprofile_ai` (file permissions: 600)

**When token expires:**
- Contact CACI IT for updated token
- Update `ANTHROPIC_AUTH_TOKEN` in `~/.zprofile_ai`
- Reload shell or `source ~/.zprofile_ai`

### Custom Headers

**Purpose:** Identifies the user making requests for usage tracking

**Format:** `x-litellm-customer-id: <email@caci.com>`

**How it works:**
- LiteLLM proxy logs this header with each request
- Used for billing, quotas, and usage reports
- Replace `<email@caci.com>` with your actual CACI email

### Model Names

**Current Model:** `anthropic.claude-sonnet-4-5-20250929-v1:0`

**Why this format:**
- LiteLLM uses provider-prefixed model names
- `anthropic.` prefix routes to Anthropic's Claude
- Full version string ensures specific model variant

**Model Mapping:**
All model types (Sonnet, Haiku, Opus) currently map to the same model. This is intentional for:
- Simplified management
- Consistent behavior across contexts
- Cost control (single model tier)

## Troubleshooting

### Authentication Errors

**Symptom:** 401 Unauthorized or 403 Forbidden errors

**Check:**
```bash
# Verify environment variables
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_AUTH_TOKEN
echo $ANTHROPIC_CUSTOM_HEADERS

# Test connection manually
curl -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
     -H "x-litellm-customer-id: <your.email@caci.com>" \
     https://litellm.csde.caci.com/v1/models
```

**Solutions:**
1. Token expired - contact CACI IT for new token
2. Wrong base URL - verify it's `https://litellm.csde.caci.com` (no trailing slash)
3. Custom header format wrong - verify email address is correct

### Environment Variables Not Loading

**Symptom:** Claude Code tries to connect to api.anthropic.com instead of proxy

**Check:**
```bash
# In the terminal where you'll run Claude Code
env | grep ANTHROPIC
```

**Solutions:**
1. **Not in login shell:** Run `source ~/.zprofile_ai`
2. **File doesn't exist:** Create `~/.zprofile_ai` per setup instructions
3. **Not sourced in profile:** Add source line to `~/.zprofile`
4. **Using bash:** Also add to `~/.bash_profile` or `~/.bashrc`

### Model Not Found Errors

**Symptom:** "Model not found" or "Invalid model" errors

**Check:**
```bash
echo $ANTHROPIC_MODEL
```

**Solution:**
Verify model name exactly matches: `anthropic.claude-sonnet-4-5-20250929-v1:0`

### Connection Timeouts

**Symptom:** Requests timeout or hang

**Check:**
1. Network connectivity to CACI infrastructure
2. VPN connection (if required)
3. Firewall rules allowing outbound HTTPS to litellm.csde.caci.com

**Test:**
```bash
curl -I https://litellm.csde.caci.com
```

## Security Considerations

### Token Security

**Risk:** Static token in plaintext file

**Mitigations:**
- File permissions: `chmod 600 ~/.zprofile_ai` (owner read/write only)
- Environment variables not visible to other users
- Token rotated periodically by IT

**Best Practices:**
- Never commit `~/.zprofile_ai` to git
- Don't share your token
- Report suspected token compromise to CACI IT immediately

### Network Security

**All traffic is encrypted:**
- HTTPS connection to LiteLLM proxy (TLS 1.2+)
- LiteLLM proxy uses HTTPS to Anthropic API
- End-to-end encryption for all requests

**Data flow:**
```
Claude Code → https://litellm.csde.caci.com → Anthropic API
    ↑              ↑                                ↑
   TLS        CACI Network                      TLS
```

### Privacy Settings

**Telemetry disabled:**
- `DISABLE_TELEMETRY=1` - No usage data sent to Anthropic
- `DISABLE_ERROR_REPORTING=1` - No crash reports
- `DISABLE_BUG_COMMAND=1` - Bug reporting command disabled
- `DISABLE_AUTOUPDATER=1` - No automatic updates

**Why:** Reduces data exposure and maintains control over updates in enterprise environment

## Advanced Configuration

### Using Different Models

To use a different model (if available in LiteLLM):

```bash
# In ~/.zprofile_ai, change:
export ANTHROPIC_MODEL="anthropic.claude-opus-4-7-20250520-v1:0"
```

**Note:** Check with CACI IT for available models and pricing

### Project-Specific Configuration

Override settings for specific projects using `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_MODEL": "anthropic.claude-haiku-4-5-20250520-v1:0"
  }
}
```

**Priority:** Environment variables < user settings < project settings

### Additional Headers

Add more custom headers if needed:

```bash
export ANTHROPIC_CUSTOM_HEADERS="x-litellm-customer-id: <email@caci.com>, x-project-id: project-123"
```

**Format:** Comma-separated `key: value` pairs

## Related Tools

Other tools that use the same configuration:

- **claude-agent-acp** - See [INTELLIJ_AI_SETUP.md](INTELLIJ_AI_SETUP.md)
- **DevoxxGenie IntelliJ Plugin** - See [INTELLIJ_AI_SETUP.md](INTELLIJ_AI_SETUP.md)

All three tools share the same environment variables for unified configuration.

## Getting Help

**For issues with:**
- **Configuration/setup** - This documentation or caci-tools repository
- **Authentication/tokens** - CACI IT Help Desk
- **Claude Code itself** - https://code.claude.com/docs
- **LiteLLM proxy** - CACI IT/Platform team

## References

- [Claude Code Documentation](https://code.claude.com/docs)
- [LiteLLM Proxy Documentation](https://docs.litellm.ai/docs/proxy/proxy_server)
- [INTELLIJ_AI_SETUP.md](INTELLIJ_AI_SETUP.md) - IntelliJ AI assistant setup
- [MACOS_TROUBLESHOOTING.md](MACOS_TROUBLESHOOTING.md) - General macOS configuration issues
