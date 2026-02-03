# Moltbot Configuration Architecture

## Overview

Moltbot uses a **dotenvx-based secret management** approach, following the same pattern as Investronomer backend. All secrets are encrypted in `.env.prod` file and decrypted at runtime using a single decryption key.

## Architecture

### 1. Encrypted Secrets (dotenvx)
**File**: `.env.prod` (committed to git, encrypted)
- Contains all secrets encrypted with dotenvx
- Discord tokens, LLM API keys, gateway auth tokens
- Safe to commit (only encrypted values)
- Decrypted at container startup using `DOTENV_PRIVATE_KEY_PROD`

### 2. Runtime State (Persistent Filesystem)
**Location**: `/home/moltbot/state/` on VPS
- Agent sessions and memory
- Identity and device pairing
- Cron jobs and scheduled tasks
- **Persists across redeployments**

### 3. Workspace (Persistent Filesystem)
**Location**: `/home/moltbot/clawd/` on VPS
- Bot's working directory
- Files and projects bot creates/modifies
- **Persists across redeployments**

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   .env.prod     │────▶│  entrypoint.sh   │────▶│   Moltbot App   │
│  (encrypted)    │     │  dotenvx decrypt │     │   with secrets  │
│                 │     │  load env vars   │     │   loaded        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

1. **Container starts**: Custom Dockerfile with dotenvx installed
2. **entrypoint.sh runs**: Decrypts `.env.prod` using `DOTENV_PRIVATE_KEY_PROD`
3. **Environment loaded**: All secrets available as environment variables
4. **Bot initializes**: Creates initial config if needed from env vars
5. **Bot runs**: With full configuration and secrets

## Benefits

✅ **Secrets Encrypted**: Safe to commit .env.prod to git  
✅ **Single Key**: Only one environment variable needed in Dokploy  
✅ **Configuration as Code**: All settings version-controlled  
✅ **Auto-Recovery**: Initial config auto-generated if missing  
✅ **Memory Persists**: Bot doesn't lose context on redeploy  
✅ **Same as Investronomer**: Consistent pattern across projects  

## File Descriptions

| File | Purpose | Version Control | Encrypted |
|------|---------|-----------------|-----------|
| `.env.example` | Template for secrets | ✅ Git | ❌ |
| `.env.prod` | Encrypted secrets | ✅ Git | ✅ Yes |
| `.env.keys` | Decryption keys | ❌ Gitignored | ❌ |
| `Dockerfile` | Custom image with dotenvx | ✅ Git | ❌ |
| `entrypoint.sh` | Startup script | ✅ Git | ❌ |
| `docker-compose.yml` | Container definition | ✅ Git | ❌ |
| `/home/moltbot/state/` | Runtime state | ❌ | ❌ |
| `/home/moltbot/clawd/` | Workspace | ❌ | ❌ |

## Setting Up Secrets

### Initial Setup (One-Time)

1. **Create `.env.prod` from template**:
   ```bash
   cd apps/moltbot
   cp .env.example .env.prod
   ```

2. **Fill in your actual secrets**:
   ```bash
   # Edit .env.prod with your values
   vim .env.prod
   ```

3. **Encrypt the file**:
   ```bash
   npx dotenvx encrypt -f .env.prod
   ```
   This will:
   - Add `DOTENV_PUBLIC_KEY_PROD` to `.env.prod`
   - Create `.env.keys` with private key
   - Encrypt all values in `.env.prod`

4. **Save the private key**:
   ```bash
   cat .env.keys
   # Copy the DOTENV_PRIVATE_KEY_PROD value
   ```

5. **Set in Dokploy**:
   - Go to Dokploy UI → Moltbot → Environment Variables
   - Add: `DOTENV_PRIVATE_KEY_PROD=<value from .env.keys>`

6. **Commit encrypted file**:
   ```bash
   git add .env.prod
   git commit -m "Add encrypted secrets"
   git push
   ```

7. **Keep .env.keys safe** (DO NOT COMMIT):
   - Store in password manager
   - Backup securely
   - Never commit to git

### Updating Secrets

1. **Decrypt to edit**:
   ```bash
   npx dotenvx decrypt -f .env.prod
   # Edit the decrypted values
   ```

2. **Re-encrypt**:
   ```bash
   npx dotenvx encrypt -f .env.prod
   ```

3. **Commit and redeploy**:
   ```bash
   git add .env.prod
   git commit -m "Update secrets"
   git push
   # Redeploy via Dokploy UI
   ```

## Environment Variables

### Required in Dokploy
Only **ONE** environment variable needed:
- `DOTENV_PRIVATE_KEY_PROD` - Decryption key from `.env.keys`

### Optional in Dokploy
- `MOLTBOT_LLM_MODEL` - Override default model (e.g., `claude-sonnet-4`)
- `DEBUG` - Set to `true` to see full environment on startup

### Encrypted in .env.prod
- `MOLTBOT_GATEWAY_TOKEN` - Gateway authentication token
- `MOLTBOT_DISCORD_TOKEN` - Discord bot token
- `MOLTBOT_DISCORD_ENABLED` - Enable/disable Discord channel
- `MOLTBOT_ANTHROPIC_API_KEY` - Anthropic Claude API key (optional, can configure multiple)
- `MOLTBOT_OPENAI_API_KEY` - OpenAI API key (optional, can configure multiple)
- `MOLTBOT_GEMINI_API_KEY` - Google Gemini API key (optional, can configure multiple)
- `MOLTBOT_GITHUB_COPILOT_TOKEN` - GitHub Copilot token (optional, can configure multiple)

**Note**: You can configure ALL LLM providers at once! See "Using Multiple LLM Providers" section below.

## Troubleshooting

### Bot Won't Start - "dotenvx not found"
The Dockerfile installs dotenvx. If you see this error:
```bash
# Rebuild the image
docker compose build --no-cache
```

### Decryption Failed
- Verify `DOTENV_PRIVATE_KEY_PROD` is set correctly in Dokploy
- Check that `.env.prod` has `DOTENV_PUBLIC_KEY_PROD` at the top
- Ensure the key pair matches (from same `.env.keys` file)

### View Decrypted Secrets (Debugging)
```bash
# Inside container
docker exec moltbot dotenvx run -f /app/.env.prod -- env | grep MOLTBOT
```

### Reset Bot Memory (CAUTION: Loses all memory)
```bash
ssh root@YOUR_VPS_IP
rm -rf /home/moltbot/state/*
docker restart moltbot
```

### View Current Runtime Config
```bash
docker exec moltbot cat /home/node/.clawdbot/clawdbot.json
```

## Deployment Workflow

1. **Local Changes**:
   ```bash
   # Update secrets in .env.prod (unencrypted)
   vim .env.prod
   
   # Re-encrypt
   npx dotenvx encrypt -f .env.prod
   
   # Commit
   git add .env.prod
   git commit -m "Update configuration"
   git push
   ```

2. **Deploy via Dokploy**:
   - Dokploy detects git push
   - Builds new image with updated `.env.prod`
   - Starts container with `DOTENV_PRIVATE_KEY_PROD` from environment
   - Entrypoint decrypts and loads secrets
   - Bot starts with new configuration

3. **Verify**:
   ```bash
   # Check logs
   docker logs moltbot -f
   
   # Should see: "🔐 Decrypting .env.prod with dotenvx..."
   # Should see: "✅ Loaded decrypted secrets."
   ```

## Migration from Old Setup

### Old Architecture
- Base config in repo (`clawdbot.json`)
- Secrets in Dokploy environment variables (multiple)
- Entrypoint merged config with env vars

### New Architecture (Current)
- Encrypted secrets in repo (`.env.prod`)
- Only one key in Dokploy (`DOTENV_PRIVATE_KEY_PROD`)
- Entrypoint decrypts and creates config from env vars

### Migration Steps
1. Create `.env.prod` with all current secrets
2. Encrypt with dotenvx
3. Update Dokploy to only have `DOTENV_PRIVATE_KEY_PROD`
4. Remove old files: `clawdbot.json`, old `entrypoint.sh`
5. Use new `Dockerfile` and `entrypoint.sh`
6. Redeploy

## Security Notes

⚠️ **NEVER commit `.env.keys`** - Contains private decryption key  
⚠️ **NEVER commit unencrypted `.env.prod`** - Only commit after encryption  
✅ **DO commit encrypted `.env.prod`** - Safe to version control  
✅ **DO backup `.env.keys`** - Store in password manager  
✅ **DO rotate keys periodically** - Generate new key pair annually  

## References

- [dotenvx Documentation](https://dotenvx.com/)
- [dotenvx Encryption Guide](https://dotenvx.com/encryption)
- Investronomer backend uses same pattern (`apps/investronomer/backend/`)

