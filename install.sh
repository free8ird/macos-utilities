#!/bin/bash

# Deskflow Watchdog Installation Script
# This script installs a LaunchAgent that automatically restarts Deskflow when it crashes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_FILE="deskflow-watchdog.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
TARGET_PLIST="$LAUNCH_AGENTS_DIR/local.deskflow.watchdog.plist"

echo "🔧 Deskflow Watchdog Installer"
echo "================================"
echo ""

# Check if Deskflow is installed
if [ ! -d "/Applications/Deskflow.app" ]; then
    echo "❌ Error: Deskflow is not installed at /Applications/Deskflow.app"
    exit 1
fi

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENTS_DIR"

# Unload existing watchdog if running
if launchctl list | grep -q "local.deskflow.watchdog"; then
    echo "📋 Unloading existing watchdog..."
    launchctl unload "$TARGET_PLIST" 2>/dev/null || true
fi

# Copy the plist file
echo "📦 Installing watchdog plist..."
cp "$SCRIPT_DIR/$PLIST_FILE" "$TARGET_PLIST"

# Load the LaunchAgent
echo "🚀 Starting watchdog..."
launchctl load "$TARGET_PLIST"

echo ""
echo "✅ Deskflow watchdog installed successfully!"
echo ""
echo "📊 Status:"
if launchctl list | grep -q "local.deskflow.watchdog"; then
    echo "   ✓ Watchdog is running"
else
    echo "   ✗ Watchdog failed to start"
    exit 1
fi

echo ""
echo "📝 The watchdog will:"
echo "   - Monitor Deskflow every 10 seconds"
echo "   - Automatically restart it if it crashes"
echo "   - Start automatically on system boot"
echo ""
echo "📁 Logs are available at:"
echo "   /tmp/deskflow-watchdog.log"
echo "   /tmp/deskflow-watchdog-error.log"
echo ""
echo "To uninstall, run: ./uninstall.sh"
