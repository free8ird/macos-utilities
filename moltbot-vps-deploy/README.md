# Moltbot VPS Deployment Package

Complete deployment package for running Moltbot on a VPS using Docker + Dokploy.

## What This Includes

This package contains everything needed to deploy Moltbot to a VPS:

- **Dockerfile** - Custom image with OpenClaw, dotenvx, and jq
- **docker-compose.yml** - Production container configuration
- **config.json** - Multi-model LLM configuration template
- **entrypoint.sh** - Startup script with secret merging
- **exec-approvals.json** - Security settings (auto-approve all commands)
- **.env.example** - Template for secrets (API keys, tokens)
- **deploy.sh** - Automated deployment script
- **copy-local-config.sh** - Sync local moltbot config to VPS
- **QUICKSTART.md** - Quick deployment guide

## Pre-Deployment Checklist

### 1. Local Moltbot Setup (Optional but Recommended)
If you have `~/moltbot` configured locally with multi-model setup:
- ✅ OAuth authenticated with Google Antigravity
- ✅ OAuth authenticated with GitHub Copilot
- ✅ Multi-model configuration with fallbacks

This gives you the best experience - all models pre-configured with authentication.

### 2. VPS Requirements
- ✅ Docker installed
- ✅ Dokploy installed (optional, can use plain Docker Compose)
- ✅ SSH access configured
- ✅ Port 18789 available (for gateway)
- ✅ Persistent storage mounted at `/home/moltbot/`

### 3. Secrets Preparation
Create your `.env.prod` file from `.env.example` with:
- **Required**: `MOLTBOT_GATEWAY_TOKEN` (generate with `openssl rand -base64 32`)
- **Optional**: Channel tokens (Discord, Telegram, etc.) if using channels
- **Optional**: LLM API keys if NOT copying from local config

## Deployment Options

### Option A: Deploy with Local Config (Recommended)
**Best for**: Multi-model setup with Google Antigravity + GitHub Copilot

1. **Prepare local environment**:
   ```bash
   cd ~/moltbot
   ./moltbot models status  # Verify all models working
   ```

2. **Copy this package to VPS**:
   ```bash
   cd ~/apps/macos-utilities/moltbot-vps-deploy
   ./deploy.sh
   ```

3. **Sync local config**:
   ```bash
   ./copy-local-config.sh
   ```

This will:
- Deploy the Docker container
- Copy your multi-model configuration
- Transfer OAuth tokens for Google Antigravity + GitHub Copilot
- Preserve VPS-specific settings (channels, gateway)

### Option B: Fresh Deployment
**Best for**: Simple setup with direct API keys

1. **Edit `.env.prod`**:
   ```bash
   cp .env.example .env.prod
   # Add your API keys and tokens
   ```

2. **Encrypt secrets**:
   ```bash
   npx dotenvx encrypt -f .env.prod
   # Save the DOTENV_PRIVATE_KEY_PROD from output
   ```

3. **Deploy**:
   ```bash
   ./deploy.sh
   ```

4. **Set Dokploy environment variable**:
   - In Dokploy UI, add `DOTENV_PRIVATE_KEY_PROD` with the encryption key

## Quick Deploy Commands

### Using Dokploy
```bash
# 1. Upload files to VPS
cd ~/apps/macos-utilities/moltbot-vps-deploy
scp -r * root@YOUR_VPS_IP:/path/to/dokploy/moltbot/

# 2. In Dokploy UI:
#    - Create new service "moltbot"
#    - Set build context to upload directory
#    - Add environment variable: DOTENV_PRIVATE_KEY_PROD
#    - Deploy

# 3. Sync local config (if using local moltbot)
./copy-local-config.sh
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

### Using Plain Docker Compose
```bash
# 1. Upload to VPS
cd ~/apps/macos-utilities/moltbot-vps-deploy
./deploy.sh

# 2. On VPS
ssh root@YOUR_VPS_IP
cd /opt/moltbot
docker compose up -d

# 3. Sync local config (optional)
exit  # Back to local machine
./copy-local-config.sh
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

## Configuration Architecture

### Three-Layer Config System

1. **config.json** (Version Controlled)
   - Your configuration choices
   - Models, channels, behavior
   - NO secrets here
   - Safe to commit to git

2. **.env.prod** (Encrypted, Version Controlled)
   - API keys and tokens only
   - Encrypted with dotenvx
   - Safe to commit (encrypted)
   - Requires `DOTENV_PRIVATE_KEY_PROD` to decrypt

3. **Runtime State** (`/home/moltbot/state/`)
   - Bot's memory and sessions
   - OAuth tokens (if copied from local)
   - Persistent on VPS
   - NOT version controlled

### How Secrets Are Merged
The `entrypoint.sh` script:
1. Decrypts `.env.prod` using dotenvx
2. Merges secrets into `config.json`
3. Creates runtime config in `/home/moltbot/state/`

## Multi-Model Configuration

The default `config.json` includes:

**Primary Model**: `google-antigravity/gemini-3-pro-high`

**Fallback Chain** (auto-retry on rate limits):
1. `google-antigravity/claude-opus-4-5-thinking`
2. `github-copilot/gpt-4o`
3. `github-copilot/claude-sonnet-4-5`
4. `github-copilot/o1`
5. `google-antigravity/gemini-3-flash`
6. `github-copilot/gpt-4o-mini`

**Total**: 8 models configured across 2 providers

## VPS Directory Structure

```
/home/moltbot/
├── state/                    # Runtime state (persistent)
│   ├── agents/main/
│   │   ├── agent/
│   │   │   ├── openclaw.json      # Runtime config
│   │   │   └── auth-profiles.json # OAuth tokens
│   │   └── sessions/
│   │       ├── sessions.json
│   │       └── *.jsonl
│   └── gateway.*.lock
├── clawd/                    # Bot workspace (persistent)
│   ├── skills/
│   ├── projects/
│   └── files/
└── .ssh/                     # SSH keys for git (optional)
    ├── id_rsa
    └── id_rsa.pub
```

## Post-Deployment

### Verify Installation
```bash
ssh root@YOUR_VPS_IP

# Check container is running
docker ps | grep moltbot

# Check logs
docker logs moltbot -f

# Check models
docker exec moltbot openclaw models status

# Check gateway
curl http://localhost:18789
```

### Access Moltbot

**Web UI**:
```bash
# Option 1: SSH tunnel
ssh -L 18789:localhost:18789 root@YOUR_VPS_IP
# Then open: http://localhost:18789

# Option 2: Tailscale (if enabled in config)
# Access directly via Tailscale network
```

**CLI**:
```bash
ssh root@YOUR_VPS_IP
docker exec -it moltbot openclaw agent --local --agent main --message "hello"
```

**TUI** (currently has WebSocket delivery bug):
```bash
ssh root@YOUR_VPS_IP
docker exec -it moltbot openclaw tui
```

### Updating Configuration

**Update LLM config from local moltbot**:
```bash
cd ~/apps/macos-utilities/moltbot-vps-deploy
./copy-local-config.sh
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

**Update secrets**:
```bash
# 1. Edit .env.prod locally
# 2. Re-encrypt
npx dotenvx encrypt -f .env.prod
# 3. Redeploy
./deploy.sh
```

**Update channels/gateway settings**:
```bash
# SSH to VPS and edit config directly
ssh root@YOUR_VPS_IP
docker exec -it moltbot vi /home/node/.clawdbot/clawdbot.json
docker restart moltbot
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs moltbot

# Common issues:
# - Missing DOTENV_PRIVATE_KEY_PROD
# - Port 18789 already in use
# - Volume permissions (should be 1000:1000)
```

### Models Not Working
```bash
# Check model status
docker exec moltbot openclaw models status

# Re-sync from local config
./copy-local-config.sh

# Check auth profiles exist
ssh root@YOUR_VPS_IP 'cat /home/moltbot/state/agents/main/agent/auth-profiles.json'
```

### Gateway Not Accessible
```bash
# Check if running
curl http://localhost:18789

# Check bind address (should be loopback)
docker exec moltbot env | grep GATEWAY

# Create SSH tunnel
ssh -L 18789:localhost:18789 root@YOUR_VPS_IP
```

### Stale Lock Files
```bash
# Entrypoint automatically cleans them, but if needed:
ssh root@YOUR_VPS_IP
docker exec moltbot rm -f /home/node/.clawdbot/gateway.*.lock
docker exec moltbot rm -f /home/node/.clawdbot/agents/main/sessions/*.lock
docker restart moltbot
```

## Security Notes

1. **Gateway Token**: Generate a strong token with `openssl rand -base64 32`
2. **Port Binding**: Default is `127.0.0.1:18789` (localhost only, use SSH tunnel)
3. **Exec Security**: Set to "full" (auto-approve all commands) - bot has full VPS access
4. **Volume Mounts**: Only mount what's needed - state, workspace, SSH keys
5. **Environment Variables**: Only `DOTENV_PRIVATE_KEY_PROD` should be in Dokploy UI

## Files in This Package

| File | Purpose |
|------|---------|
| `README.md` | This file - comprehensive deployment guide |
| `QUICKSTART.md` | Quick reference for common tasks |
| `Dockerfile` | Container image with OpenClaw + dotenvx + jq |
| `docker-compose.yml` | Production container configuration |
| `entrypoint.sh` | Startup script - merges config + secrets |
| `config.json` | Multi-model configuration template |
| `exec-approvals.json` | Security settings (auto-approve) |
| `.env.example` | Template for secrets |
| `.env.prod` | Encrypted secrets (create from example) |
| `deploy.sh` | Automated deployment script |
| `copy-local-config.sh` | Sync local moltbot to VPS |

## License

Same as parent repository.

## Support

For issues or questions:
1. Check logs: `docker logs moltbot -f`
2. Verify models: `docker exec moltbot openclaw models status`
3. Check OpenClaw docs: https://opencode.ai/docs
4. Review local moltbot setup: `~/moltbot/`

---

**Last Updated**: Feb 2, 2026  
**OpenClaw Version**: 2026.2.1
