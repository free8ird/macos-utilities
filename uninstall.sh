#!/bin/bash

# Deskflow Watchdog Uninstallation Script

set -e

TARGET_PLIST="$HOME/Library/LaunchAgents/local.deskflow.watchdog.plist"

echo "🗑️  Deskflow Watchdog Uninstaller"
echo "=================================="
echo ""

if [ ! -f "$TARGET_PLIST" ]; then
    echo "⚠️  Watchdog is not installed"
    exit 0
fi

# Unload the LaunchAgent
if launchctl list | grep -q "local.deskflow.watchdog"; then
    echo "📋 Stopping watchdog..."
    launchctl unload "$TARGET_PLIST"
fi

# Remove the plist file
echo "🗑️  Removing plist file..."
rm "$TARGET_PLIST"

# Clean up log files
echo "🧹 Cleaning up logs..."
rm -f /tmp/deskflow-watchdog.log
rm -f /tmp/deskflow-watchdog-error.log

echo ""
echo "✅ Deskflow watchdog uninstalled successfully!"
