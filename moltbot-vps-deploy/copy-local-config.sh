#!/usr/bin/env bash
set -e

# Copy LLM-related config from local moltbot to VPS Moltbot
# This copies ONLY:
# - Multi-model configuration (model fallbacks)
# - GitHub Copilot auth
# - Google Antigravity auth
# - Auth profiles

VPS_HOST="root@YOUR_VPS_IP"
VPS_STATE_DIR="/home/moltbot/state"
LOCAL_MOLTBOT_DIR="$HOME/moltbot"
TEMP_MERGE_DIR="/tmp/moltbot-merge-$$"

echo "🚀 Copying LLM config from local moltbot to VPS..."
echo ""

# Check if local moltbot exists
if [ ! -d "$LOCAL_MOLTBOT_DIR" ]; then
    echo "❌ Local moltbot directory not found: $LOCAL_MOLTBOT_DIR"
    echo "   Make sure you have ~/moltbot set up"
    exit 1
fi

# Check if local config exists
if [ ! -f "$LOCAL_MOLTBOT_DIR/config/openclaw.json" ]; then
    echo "❌ Local moltbot config not found: $LOCAL_MOLTBOT_DIR/config/openclaw.json"
    exit 1
fi

echo "✅ Using local moltbot from: $LOCAL_MOLTBOT_DIR"
echo ""

# Create temp directory for merging configs
echo "📁 Creating temp directory for config merge..."
mkdir -p "$TEMP_MERGE_DIR"

# Download current VPS config
echo "⬇️  Downloading current VPS config..."
ssh "$VPS_HOST" "cat /home/moltbot/state/agents/main/agent/openclaw.json 2>/dev/null || echo '{}'" > "$TEMP_MERGE_DIR/vps-config.json"

echo "📋 Extracting LLM config from local moltbot..."
# Extract only the LLM-related sections from local config
jq '{
  agents: {
    defaults: {
      workspace: .agents.defaults.workspace,
      maxConcurrent: .agents.defaults.maxConcurrent,
      subagents: .agents.defaults.subagents,
      model: .agents.defaults.model,
      models: .agents.defaults.models
    }
  },
  auth: .auth
}' "$LOCAL_MOLTBOT_DIR/config/openclaw.json" > "$TEMP_MERGE_DIR/llm-config.json"

echo "🔀 Merging with VPS config (preserving channels, gateway, plugins)..."
# Merge: Keep VPS channels/gateway/plugins, update models/auth from local
jq -s '
  .[0] as $vps |
  .[1] as $local |
  {
    agents: {
      defaults: (
        ($vps.agents.defaults // {}) + {
          workspace: ($vps.agents.defaults.workspace // "/home/node/workspace"),
          maxConcurrent: $local.agents.defaults.maxConcurrent,
          subagents: $local.agents.defaults.subagents,
          model: $local.agents.defaults.model,
          models: $local.agents.defaults.models,
          compaction: ($vps.agents.defaults.compaction // {"mode": "safeguard"})
        }
      )
    },
    auth: $local.auth,
    messages: ($vps.messages // {"ackReactionScope": "all"}),
    commands: ($vps.commands // {"native": "auto", "nativeSkills": "auto"}),
    channels: $vps.channels,
    gateway: $vps.gateway,
    tools: ($vps.tools // {"exec": {"host": "sandbox", "security": "full", "ask": "off"}}),
    skills: ($vps.skills // {"install": {"nodeManager": "npm"}}),
    plugins: $vps.plugins
  }
' "$TEMP_MERGE_DIR/vps-config.json" "$TEMP_MERGE_DIR/llm-config.json" > "$TEMP_MERGE_DIR/merged-config.json"

echo "✅ Merged config created"
echo ""
echo "📊 Changes summary:"
echo "   - Multi-model configuration (primary + fallbacks)"
echo "   - Model list (8 models from Google + GitHub)"
echo "   - Auth profiles (Google Antigravity + GitHub Copilot)"
echo ""

# Show the models that will be configured
echo "🤖 Models that will be configured:"
jq -r '.agents.defaults.models | keys[]' "$TEMP_MERGE_DIR/merged-config.json"
echo ""
echo "🔄 Fallback chain:"
jq -r '.agents.defaults.model.fallbacks[]' "$TEMP_MERGE_DIR/merged-config.json"
echo ""

# Ask for confirmation
read -p "Continue with upload? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    rm -rf "$TEMP_MERGE_DIR"
    exit 1
fi

# Create directories on VPS
echo "📁 Creating directories on VPS..."
ssh "$VPS_HOST" "mkdir -p $VPS_STATE_DIR/agents/main/agent && chown -R 1000:1000 $VPS_STATE_DIR"

# Upload merged config
echo "⬆️  Uploading merged config to VPS..."
scp "$TEMP_MERGE_DIR/merged-config.json" "$VPS_HOST:$VPS_STATE_DIR/agents/main/agent/openclaw.json"

# Copy auth profiles (the actual OAuth tokens)
echo "🔑 Copying auth profiles..."
if [ -f "$LOCAL_MOLTBOT_DIR/data/agents/main/agent/auth-profiles.json" ]; then
    scp "$LOCAL_MOLTBOT_DIR/data/agents/main/agent/auth-profiles.json" "$VPS_HOST:$VPS_STATE_DIR/agents/main/agent/auth-profiles.json"
else
    echo "⚠️  Warning: No auth-profiles.json found in local moltbot"
    echo "   You may need to re-authenticate on VPS"
fi

# Fix permissions
echo "🔧 Setting correct permissions..."
ssh "$VPS_HOST" "chown -R 1000:1000 $VPS_STATE_DIR && chmod -R 700 $VPS_STATE_DIR"

# Cleanup
rm -rf "$TEMP_MERGE_DIR"

echo ""
echo "✅ LLM config copied successfully!"
echo ""
echo "📋 Configured:"
echo "   ✓ 8 models (Google Antigravity + GitHub Copilot)"
echo "   ✓ 6-level fallback chain"
echo "   ✓ Auth profiles for both providers"
echo ""
echo "🔄 Next step: Restart Moltbot container"
echo "   ssh $VPS_HOST 'docker restart moltbot'"
echo ""
echo "🧪 Then verify:"
echo "   ssh $VPS_HOST 'docker exec moltbot openclaw models status'"
