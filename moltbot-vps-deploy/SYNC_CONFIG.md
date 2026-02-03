# Multi-Model Configuration Sync

## Overview

The `copy-local-config.sh` script syncs **ONLY LLM-related configuration** from your local `~/moltbot` to the VPS moltbot instance.

## What Gets Copied

### ✅ Copied (LLM Config)
- **Multi-model configuration**
  - Primary model setting
  - Fallback chain (6 models)
  - All 8 model definitions
- **Auth profiles**
  - Google Antigravity OAuth tokens
  - GitHub Copilot OAuth tokens
- **Model settings**
  - `agents.defaults.model`
  - `agents.defaults.models`
  - `auth.profiles`

### ❌ NOT Copied (VPS-specific)
- **Channels** (Discord, Telegram, etc.) - Preserved from VPS
- **Gateway settings** - Preserved from VPS
- **Plugins** - Preserved from VPS
- **Tools/Security settings** - Preserved from VPS
- **Workspace path** - Preserved from VPS (`/home/node/clawd`)

## Usage

```bash
cd ~/apps/monorepo/apps/moltbot
./copy-local-config.sh
```

The script will:
1. ✅ Download current VPS config
2. ✅ Extract LLM config from local `~/moltbot`
3. ✅ Merge configs (smart merge, preserves VPS settings)
4. ✅ Show you what will change
5. ⏸️  Ask for confirmation
6. ✅ Upload merged config
7. ✅ Copy auth profiles (OAuth tokens)
8. ✅ Fix permissions

## After Running

Restart the VPS container:
```bash
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

Verify models are configured:
```bash
ssh root@YOUR_VPS_IP 'docker exec moltbot openclaw models status'
```

## What You'll See on VPS

After sync, VPS moltbot will have:

**Models (8 total):**
- google-antigravity/gemini-3-pro-high
- google-antigravity/claude-opus-4-5-thinking
- google-antigravity/gemini-3-flash
- github-copilot/gpt-4o
- github-copilot/claude-sonnet-4-5
- github-copilot/o1
- github-copilot/o1-mini
- github-copilot/gpt-4o-mini

**Fallback Chain:**
```
Primary: gemini-3-pro-high
  ↓
Fallback 1: claude-opus-4-5-thinking
  ↓
Fallback 2: gpt-4o
  ↓
Fallback 3: claude-sonnet-4-5
  ↓
Fallback 4: o1
  ↓
Fallback 5: gemini-3-flash
  ↓
Fallback 6: gpt-4o-mini
```

**Auth Providers:**
- Google Antigravity (OAuth)
- GitHub Copilot (OAuth)

## Troubleshooting

### Auth profiles not working on VPS

You may need to re-authenticate on the VPS:

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Enter container
docker exec -it moltbot sh

# Re-authenticate Google Antigravity
openclaw models auth login --provider google-antigravity

# Re-authenticate GitHub Copilot
openclaw models auth login-github-copilot
```

### Config merge failed

Check if `jq` is installed locally:
```bash
which jq || brew install jq
```

### Models showing as "missing"

This is normal if the VPS hasn't authenticated yet. After copying auth profiles and restarting, run:
```bash
ssh root@YOUR_VPS_IP 'docker exec moltbot openclaw models list'
```

## Example Output

```
🚀 Copying LLM config from local moltbot to VPS...

✅ Using local moltbot from: /Users/pjayswal/moltbot

📁 Creating temp directory for config merge...
⬇️  Downloading current VPS config...
📋 Extracting LLM config from local moltbot...
🔀 Merging with VPS config (preserving channels, gateway, etc.)...
✅ Merged config created

📊 Changes summary:
   - Multi-model configuration (primary + fallbacks)
   - Model list (8 models from Google + GitHub)
   - Auth profiles (Google Antigravity + GitHub Copilot)

🤖 Models that will be configured:
google-antigravity/gemini-3-pro-high
google-antigravity/claude-opus-4-5-thinking
google-antigravity/gemini-3-flash
github-copilot/gpt-4o
github-copilot/claude-sonnet-4-5
github-copilot/o1
github-copilot/o1-mini
github-copilot/gpt-4o-mini

🔄 Fallback chain:
google-antigravity/claude-opus-4-5-thinking
github-copilot/gpt-4o
github-copilot/claude-sonnet-4-5
github-copilot/o1
google-antigravity/gemini-3-flash
github-copilot/gpt-4o-mini

Continue with upload? (y/N) y

📁 Creating directories on VPS...
⬆️  Uploading merged config to VPS...
🔑 Copying auth profiles...
🔧 Setting correct permissions...

✅ LLM config copied successfully!

📋 Configured:
   ✓ 8 models (Google Antigravity + GitHub Copilot)
   ✓ 6-level fallback chain
   ✓ Auth profiles for both providers

🔄 Next step: Restart Moltbot container
   ssh root@YOUR_VPS_IP 'docker restart moltbot'

🧪 Then verify:
   ssh root@YOUR_VPS_IP 'docker exec moltbot openclaw models status'
```

## Files Modified on VPS

```
/home/moltbot/state/
├── agents/
│   └── main/
│       └── agent/
│           ├── openclaw.json          # ← Updated (merged)
│           └── auth-profiles.json     # ← Updated (copied)
```

## Safety

The script:
- ✅ Creates a backup in temp directory
- ✅ Shows you changes before applying
- ✅ Asks for confirmation
- ✅ Preserves all VPS-specific settings
- ✅ Only modifies LLM-related config

Your VPS channels, gateway settings, and other configurations remain untouched!
