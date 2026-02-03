#!/usr/bin/env bash
set -eu -o pipefail

# Moltbot Startup with config.json + dotenvx Secrets
export ENV=${ENV:-prod}

echo "🤖 Starting Moltbot ($ENV)..."

# ------------------------------------------------------------------------------
# 1. Load Secrets from dotenvx
# ------------------------------------------------------------------------------
if [ "$ENV" = "prod" ] && [ -f "/app/.env.prod" ]; then
    echo "🔐 Decrypting .env.prod with dotenvx..."
    if command -v dotenvx &> /dev/null; then
        dotenvx run -f /app/.env.prod -- env | grep -E "^[A-Z0-9_]+=" > /tmp/secrets.env
        set -o allexport
        source /tmp/secrets.env
        set +o allexport
        rm /tmp/secrets.env
        echo "✅ Loaded decrypted secrets."
    else
        echo "⚠️  dotenvx not found. Skipping decryption."
    fi
elif [ -f "/app/.env.$ENV" ]; then
    echo "📝 Loading .env.$ENV..."
    set -o allexport
    source "/app/.env.$ENV"
    set +o allexport
fi

# ------------------------------------------------------------------------------
# 2. Load Base Configuration from config.json
# ------------------------------------------------------------------------------
OPENCLAW_CONFIG_DIR="${HOME}/.openclaw"
OPENCLAW_CONFIG_FILE="${OPENCLAW_CONFIG_DIR}/openclaw.json"
CONFIG_TEMPLATE="/app/config.json"

echo "📁 Config directory: ${OPENCLAW_CONFIG_DIR}"
mkdir -p "${OPENCLAW_CONFIG_DIR}"

# Clean up any stale lock files from previous runs
if ls "${OPENCLAW_CONFIG_DIR}"/gateway.*.lock 1> /dev/null 2>&1; then
    echo "🧹 Cleaning up stale gateway lock files..."
    rm -f "${OPENCLAW_CONFIG_DIR}"/gateway.*.lock
    echo "✅ Gateway lock files removed"
fi

# Clean up session lock files
if ls "${OPENCLAW_CONFIG_DIR}"/agents/main/sessions/*.lock 1> /dev/null 2>&1; then
    echo "🧹 Cleaning up stale session lock files..."
    rm -f "${OPENCLAW_CONFIG_DIR}"/agents/main/sessions/*.lock
    echo "✅ Session lock files removed"
fi

# If no runtime config exists, create it from template + secrets
if [ ! -f "${OPENCLAW_CONFIG_FILE}" ]; then
    echo "🆕 Creating initial openclaw.json from config.json + secrets..."
    
    if [ ! -f "${CONFIG_TEMPLATE}" ]; then
        echo "❌ ERROR: config.json not found at ${CONFIG_TEMPLATE}"
        exit 1
    fi
    
    # Use jq to merge secrets into config
    if command -v jq &> /dev/null; then
        jq --arg gateway_token "${MOLTBOT_GATEWAY_TOKEN:-}" \
           --arg discord_token "${MOLTBOT_DISCORD_TOKEN:-}" \
           '.gateway.auth.token = $gateway_token |
            .channels.discord.token = $discord_token' \
           "${CONFIG_TEMPLATE}" > "${OPENCLAW_CONFIG_FILE}"
        
        echo "✅ Config created with secrets merged"
    else
        # Fallback: just copy template
        cp "${CONFIG_TEMPLATE}" "${OPENCLAW_CONFIG_FILE}"
        echo "⚠️  jq not found, using template without secret merging"
    fi
else
    echo "ℹ️  Existing runtime config found, preserving it"
    echo "ℹ️  To reset to config.json template, delete /home/moltbot/state/openclaw.json"
fi

# Copy exec approvals if not exists
EXEC_APPROVALS_FILE="${OPENCLAW_CONFIG_DIR}/exec-approvals.json"
if [ ! -f "${EXEC_APPROVALS_FILE}" ]; then
    if [ -f "/app/exec-approvals.json" ]; then
        echo "📋 Creating exec-approvals.json from template..."
        cp /app/exec-approvals.json "${EXEC_APPROVALS_FILE}"
        echo "✅ Exec approvals configured (security: full, no prompts)"
    fi
fi

# ------------------------------------------------------------------------------
# 3. Debug Output
# ------------------------------------------------------------------------------
echo "--- Environment Check ---"
if [ "${DEBUG:-false}" = "true" ]; then
    echo "⚠️  DEBUG=true: Printing full environment (May contain secrets!)"
    env | sort
else
    echo "ℹ️  Printing keys only (Set DEBUG=true to see values)"
    env | cut -d= -f1 | sort
fi
echo "-------------------------"

# ------------------------------------------------------------------------------
# 4. Start Moltbot Gateway
# ------------------------------------------------------------------------------
echo "🚀 Starting Moltbot Gateway..."

# Start the gateway with the specified port and bind address
exec openclaw gateway
