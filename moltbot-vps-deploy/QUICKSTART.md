# Moltbot VPS Deployment - Quick Start

## 🚀 Fast Deploy (5 Minutes)

### Prerequisites
- VPS with Docker installed
- `~/moltbot` configured locally (optional but recommended)
- SSH access to VPS

### Step 1: Deploy to VPS
```bash
cd ~/apps/macos-utilities/moltbot-vps-deploy
./deploy.sh YOUR_VPS_IP
```

### Step 2: Sync Local Config (Recommended)
```bash
./copy-local-config.sh
```

### Step 3: Verify
```bash
ssh root@YOUR_VPS_IP 'docker logs moltbot -f'
```

## 📋 Common Commands

### Check Status
```bash
ssh root@YOUR_VPS_IP 'docker ps | grep moltbot'
ssh root@YOUR_VPS_IP 'docker logs moltbot -f'
```

### Verify Models
```bash
ssh root@YOUR_VPS_IP 'docker exec moltbot openclaw models status'
```

### Access Web UI
```bash
# Create SSH tunnel
ssh -L 18789:localhost:18789 root@YOUR_VPS_IP
# Open: http://localhost:18789
```

### Restart Container
```bash
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

### Update Config from Local
```bash
./copy-local-config.sh
ssh root@YOUR_VPS_IP 'docker restart moltbot'
```

## 🔧 Configuration

### VPS Settings (docker-compose.yml)
- **Port**: 127.0.0.1:18789 (localhost only)
- **State**: `/home/moltbot/state` (persistent)
- **Workspace**: `/home/moltbot/clawd` (persistent)
- **Memory**: 2GB limit, 1GB reserved

### Models Configured (config.json)
- **Primary**: `google-antigravity/gemini-3-pro-high`
- **Fallbacks**: 6 models (Google + GitHub)
- **Total**: 8 models across 2 providers

### Secrets (.env.prod)
- **Required**: `MOLTBOT_GATEWAY_TOKEN`
- **Optional**: Channel tokens (Discord, Telegram, etc.)
- **Optional**: LLM API keys (if not using local config)

## 🔑 Dokploy Setup

### Environment Variables
Only ONE variable needed in Dokploy UI:
```
DOTENV_PRIVATE_KEY_PROD=<your-encryption-key>
```

Get this from:
```bash
npx dotenvx encrypt -f .env.prod
# Copy the DOTENV_PRIVATE_KEY_PROD from output
```

## 🐛 Troubleshooting

### Container Won't Start
```bash
docker logs moltbot  # Check error messages
```

### Models Missing
```bash
./copy-local-config.sh  # Sync from local moltbot
```

### Gateway Not Accessible
```bash
ssh -L 18789:localhost:18789 root@YOUR_VPS_IP
```

### Stale Lock Files
```bash
# Automatically cleaned by entrypoint
# Or manually:
docker exec moltbot rm -f /home/node/.clawdbot/gateway.*.lock
docker restart moltbot
```

## 📁 File Locations

| Location | Purpose |
|----------|---------|
| `/home/moltbot/state/` | Runtime state (OAuth, sessions) |
| `/home/moltbot/clawd/` | Bot workspace (files, skills) |
| `/home/moltbot/.ssh/` | SSH keys for git operations |

## 🔄 Update Workflow

1. **Update local moltbot** (`~/moltbot`)
2. **Sync to VPS**: `./copy-local-config.sh`
3. **Restart**: `ssh root@YOUR_VPS_IP 'docker restart moltbot'`
4. **Verify**: `ssh root@YOUR_VPS_IP 'docker exec moltbot openclaw models status'`

## 📖 Full Documentation

See [README.md](README.md) for:
- Architecture details
- Secret management
- Security considerations
- Advanced configuration
- Complete troubleshooting guide

---

**VPS IP**: 107.174.35.228  
**Port**: 18789 (localhost only)  
**Platform**: Dokploy + Docker Compose
