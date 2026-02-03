#!/usr/bin/env bash
set -e

# Moltbot VPS Deployment Script
# Deploys Moltbot to VPS using Docker Compose

VPS_IP="${1:-YOUR_VPS_IP}"
VPS_USER="${2:-root}"
VPS_DEPLOY_DIR="/opt/moltbot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying Moltbot to VPS..."
echo ""
echo "VPS: $VPS_USER@$VPS_IP"
echo "Directory: $VPS_DEPLOY_DIR"
echo ""

# Check if .env.prod exists
if [ ! -f "$SCRIPT_DIR/.env.prod" ]; then
    echo "⚠️  Warning: .env.prod not found"
    echo "   Create .env.prod from .env.example before deploying"
    echo "   Or you can deploy without it and copy local config later"
    read -p "Continue without .env.prod? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
    SKIP_ENV=true
else
    SKIP_ENV=false
fi

# Create deployment directory on VPS
echo "📁 Creating deployment directory on VPS..."
ssh "$VPS_USER@$VPS_IP" "mkdir -p $VPS_DEPLOY_DIR"

# Create persistent data directories
echo "📁 Creating persistent data directories..."
ssh "$VPS_USER@$VPS_IP" "mkdir -p /home/moltbot/state /home/moltbot/workspace /home/moltbot/.ssh && chown -R 1000:1000 /home/moltbot"

# Upload files
echo "⬆️  Uploading deployment files..."
scp "$SCRIPT_DIR/Dockerfile" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"
scp "$SCRIPT_DIR/docker-compose.yml" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"
scp "$SCRIPT_DIR/entrypoint.sh" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"
scp "$SCRIPT_DIR/config.json" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"
scp "$SCRIPT_DIR/exec-approvals.json" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"

if [ "$SKIP_ENV" = false ]; then
    echo "🔐 Uploading encrypted secrets..."
    scp "$SCRIPT_DIR/.env.prod" "$VPS_USER@$VPS_IP:$VPS_DEPLOY_DIR/"
else
    echo "⏭️  Skipping .env.prod upload (not found)"
fi

# Set permissions
echo "🔧 Setting permissions..."
ssh "$VPS_USER@$VPS_IP" "chmod +x $VPS_DEPLOY_DIR/entrypoint.sh"

# Build and start container
echo "🏗️  Building Docker image..."
ssh "$VPS_USER@$VPS_IP" "cd $VPS_DEPLOY_DIR && docker compose build"

echo "🚀 Starting Moltbot container..."
ssh "$VPS_USER@$VPS_IP" "cd $VPS_DEPLOY_DIR && docker compose up -d"

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 5

# Check status
echo "📊 Checking container status..."
ssh "$VPS_USER@$VPS_IP" "docker ps | grep moltbot"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo ""
if [ "$SKIP_ENV" = true ]; then
    echo "1️⃣  Copy local moltbot config (recommended):"
    echo "   cd ~/apps/macos-utilities/moltbot-vps-deploy"
    echo "   ./copy-local-config.sh"
    echo ""
fi
echo "2️⃣  Check logs:"
echo "   ssh $VPS_USER@YOUR_VPS_IP 'docker logs moltbot -f'"
echo ""
echo "3️⃣  Verify models:"
echo "   ssh $VPS_USER@YOUR_VPS_IP 'docker exec moltbot openclaw models status'"
echo ""
echo "4️⃣  Access Web UI (via SSH tunnel):"
echo "   ssh -L 18789:localhost:18789 $VPS_USER@YOUR_VPS_IP"
echo "   Then open: http://localhost:18789"
echo ""
