#!/bin/bash

# moltbot Fresh Setup Script
# Sets up moltbot in ~/moltbot with multi-model configuration

set -e

MOLTBOT_DIR="$HOME/moltbot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🦞 moltbot Fresh Setup"
echo "======================"
echo ""

# Check if moltbot already exists
if [ -d "$MOLTBOT_DIR" ]; then
    echo "⚠️  moltbot directory already exists: $MOLTBOT_DIR"
    read -p "Do you want to REMOVE it and start fresh? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing moltbot..."
        rm -rf "$MOLTBOT_DIR"
    else
        echo "❌ Aborted. Remove $MOLTBOT_DIR manually or choose a different location."
        exit 1
    fi
fi

echo "📁 Creating moltbot directory: $MOLTBOT_DIR"
mkdir -p "$MOLTBOT_DIR"
cd "$MOLTBOT_DIR"

echo "📦 Installing OpenClaw via npm..."
npm init -y
npm install openclaw

echo "📝 Setting up directory structure..."
mkdir -p config data workspace

echo "⚙️  Installing configuration template..."
# Update workspace path to absolute
sed "s|~/moltbot/workspace|$MOLTBOT_DIR/workspace|g" \
    "$SCRIPT_DIR/config-template.json" > "$MOLTBOT_DIR/config/openclaw.json"

echo "🔧 Creating launcher scripts..."

# Create moltbot launcher
cat > "$MOLTBOT_DIR/moltbot" <<'LAUNCHER_EOF'
#!/bin/bash

# OpenClaw (moltbot) Launcher Script
# Runs OpenClaw with all data stored in ~/moltbot

set -e

MOLTBOT_DIR="$HOME/moltbot"
OPENCLAW_BIN="$MOLTBOT_DIR/node_modules/.bin/openclaw"

# Set environment variables to keep all data in ~/moltbot
export OPENCLAW_STATE_DIR="$MOLTBOT_DIR/data"
export OPENCLAW_CONFIG_PATH="$MOLTBOT_DIR/config/openclaw.json"
export OPENCLAW_WORKSPACE="$MOLTBOT_DIR/workspace"

# Create directories if they don't exist
mkdir -p "$OPENCLAW_STATE_DIR"
mkdir -p "$MOLTBOT_DIR/config"
mkdir -p "$OPENCLAW_WORKSPACE"

# Run OpenClaw with all arguments passed through
"$OPENCLAW_BIN" "$@"
LAUNCHER_EOF

chmod +x "$MOLTBOT_DIR/moltbot"

# Create start script
cat > "$MOLTBOT_DIR/start" <<'START_EOF'
#!/bin/bash

# Start moltbot (OpenClaw) gateway
# All memories and data are preserved in ~/moltbot/data/

set -e

MOLTBOT_DIR="$HOME/moltbot"
PID_FILE="$MOLTBOT_DIR/moltbot.pid"
LOG_FILE="$MOLTBOT_DIR/moltbot.log"

cd "$MOLTBOT_DIR"

# Set environment variables to keep all data in ~/moltbot
export OPENCLAW_STATE_DIR="$MOLTBOT_DIR/data"
export OPENCLAW_CONFIG_PATH="$MOLTBOT_DIR/config/openclaw.json"
export OPENCLAW_WORKSPACE="$MOLTBOT_DIR/workspace"

# Create directories if they don't exist
mkdir -p "$OPENCLAW_STATE_DIR"
mkdir -p "$MOLTBOT_DIR/config"
mkdir -p "$OPENCLAW_WORKSPACE"

# Check if already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "❌ moltbot is already running (PID: $PID)"
        echo "   Use './stop' to stop it first"
        exit 1
    else
        # Stale PID file
        rm "$PID_FILE"
    fi
fi

echo "🦞 Starting moltbot..."
echo "   State: $OPENCLAW_STATE_DIR"
echo "   Config: $OPENCLAW_CONFIG_PATH"
echo "   Workspace: $OPENCLAW_WORKSPACE"
echo ""

# Start the gateway in the background
nohup ./node_modules/.bin/openclaw gateway >> "$LOG_FILE" 2>&1 &
GATEWAY_PID=$!

# Save the PID
echo "$GATEWAY_PID" > "$PID_FILE"

# Wait a moment to check if it started successfully
sleep 2

if ps -p "$GATEWAY_PID" > /dev/null 2>&1; then
    echo "✅ moltbot started successfully!"
    echo "   PID: $GATEWAY_PID"
    echo "   Log: $LOG_FILE"
    echo ""
    echo "📝 Commands:"
    echo "   ./stop           - Stop moltbot"
    echo "   ./status         - Check status"
    echo "   tail -f $LOG_FILE  - View logs"
    echo ""
    echo "💾 All memories are saved in: $OPENCLAW_STATE_DIR"
else
    echo "❌ Failed to start moltbot"
    echo "   Check the log: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
START_EOF

chmod +x "$MOLTBOT_DIR/start"

# Create stop script
cat > "$MOLTBOT_DIR/stop" <<'STOP_EOF'
#!/bin/bash

# Stop moltbot (OpenClaw) gateway
# Gracefully shuts down while preserving all memories

MOLTBOT_DIR="$HOME/moltbot"
PID_FILE="$MOLTBOT_DIR/moltbot.pid"

cd "$MOLTBOT_DIR"

if [ ! -f "$PID_FILE" ]; then
    echo "❌ moltbot is not running (no PID file found)"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  moltbot is not running (stale PID file)"
    rm "$PID_FILE"
    exit 0
fi

echo "🛑 Stopping moltbot (PID: $PID)..."

# Try graceful shutdown first (SIGTERM)
kill "$PID" 2>/dev/null

# Wait up to 10 seconds for graceful shutdown
for i in {1..10}; do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ moltbot stopped gracefully"
        rm "$PID_FILE"
        echo "💾 All memories preserved in: $MOLTBOT_DIR/data/"
        exit 0
    fi
    sleep 1
done

# If still running, force kill
echo "⚠️  Graceful shutdown timeout, forcing stop..."
kill -9 "$PID" 2>/dev/null

if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "✅ moltbot stopped (forced)"
    rm "$PID_FILE"
    echo "💾 All memories preserved in: $MOLTBOT_DIR/data/"
else
    echo "❌ Failed to stop moltbot"
    exit 1
fi
STOP_EOF

chmod +x "$MOLTBOT_DIR/stop"

# Create status script
cat > "$MOLTBOT_DIR/status" <<'STATUS_EOF'
#!/bin/bash

# Check moltbot status

MOLTBOT_DIR="$HOME/moltbot"
PID_FILE="$MOLTBOT_DIR/moltbot.pid"
LOG_FILE="$MOLTBOT_DIR/moltbot.log"

echo "🦞 moltbot Status"
echo "================="
echo ""

if [ ! -f "$PID_FILE" ]; then
    echo "Status: ❌ Not running"
    echo ""
    echo "To start: ./start"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    echo "Status: ✅ Running"
    echo "PID: $PID"
    
    # Get process info
    UPTIME=$(ps -p "$PID" -o etime= | xargs)
    MEM=$(ps -p "$PID" -o rss= | awk '{printf "%.1f MB", $1/1024}')
    
    echo "Uptime: $UPTIME"
    echo "Memory: $MEM"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Check if data directory exists and show size
    if [ -d "$MOLTBOT_DIR/data" ]; then
        DATA_SIZE=$(du -sh "$MOLTBOT_DIR/data" 2>/dev/null | cut -f1)
        echo "💾 Data directory: $DATA_SIZE"
    fi
    
    echo ""
    echo "Commands:"
    echo "  ./stop              - Stop moltbot"
    echo "  tail -f $LOG_FILE   - View logs"
else
    echo "Status: ❌ Not running (stale PID file)"
    rm "$PID_FILE"
    echo ""
    echo "To start: ./start"
fi
STATUS_EOF

chmod +x "$MOLTBOT_DIR/status"

# Create .gitignore
cat > "$MOLTBOT_DIR/.gitignore" <<'GITIGNORE_EOF'
# Data directory (contains auth tokens and memories)
/data/

# Workspace
/workspace/

# Config (may contain secrets)
/config/openclaw.json

# Node modules
/node_modules/

# npm
/package-lock.json

# Logs
*.log
*.pid

# macOS
.DS_Store
GITIGNORE_EOF

echo ""
echo "✅ moltbot installation complete!"
echo ""
echo "📁 Directory structure:"
echo "   ~/moltbot/"
echo "   ├── moltbot          # CLI launcher"
echo "   ├── start            # Start script"
echo "   ├── stop             # Stop script"
echo "   ├── status           # Status script"
echo "   ├── config/          # Configuration"
echo "   ├── data/            # Persistent data (NOT in git)"
echo "   └── workspace/       # Agent workspace (NOT in git)"
echo ""
echo "🔐 Next step: Authenticate with providers"
echo ""
echo "1️⃣  Authenticate Google Antigravity:"
echo "   cd ~/moltbot"
echo "   ./moltbot models auth login --provider google-antigravity"
echo ""
echo "2️⃣  Authenticate GitHub Copilot:"
echo "   ./moltbot models auth login-github-copilot"
echo ""
echo "3️⃣  Verify models are configured:"
echo "   ./moltbot models status"
echo ""
echo "4️⃣  Start moltbot:"
echo "   ./start"
echo ""
echo "📚 All configured with:"
echo "   ✓ 8 models (Google Antigravity + GitHub Copilot)"
echo "   ✓ 6-level fallback chain"
echo "   ✓ Automatic retry on rate limits"
echo ""
