# macOS Utilities

Collection of utilities and fixes for macOS workflow automation.

## Deskflow Watchdog

Automatic restart solution for Deskflow crashes caused by screensaver bugs.

### Problem

Deskflow (versions up to 1.25.0) crashes intermittently with a `SIGBUS` error in the `OSXScreenSaver::processLaunched()` function. This happens when:
- The screensaver launches
- Certain system processes start
- The system wakes from sleep

**The Critical Issue:** When Deskflow crashes, the process doesn't terminate cleanly - it becomes **hung/frozen** while still running. This blocks all mouse and keyboard input on the server machine, effectively freezing it.

**Crash Details:**
```
Exception: EXC_BAD_ACCESS (SIGBUS)
Function: OSXScreenSaver::processLaunched(ProcessSerialNumber)
Cause: NULL pointer dereference in CFRelease() call
Address: 0x000000000000000d (invalid memory)
Process State: Zombie or Uninterruptible Sleep
```

### Solution

A LaunchAgent watchdog that:
1. Monitors Deskflow's process state every 10 seconds
2. Detects when the process is hung/frozen (Zombie or Uninterruptible Sleep state)
3. Force kills the hung process
4. Automatically restarts Deskflow
5. Tracks crash count and logs all activity

### Installation

```bash
cd ~/apps/macos-utilities
./install.sh
```

The watchdog will:
- Monitor Deskflow's process state every 10 seconds
- Detect hung/frozen processes (not just terminated ones)
- Force kill and restart frozen Deskflow instances
- Track crash count and log all activity
- Start automatically on system boot

### Uninstallation

```bash
./uninstall.sh
```

### Logs

Monitor the watchdog activity:
```bash
tail -f /tmp/deskflow-watchdog.log
```

The log shows:
- Process state checks every 10 seconds
- Detected hangs/crashes
- Force kill and restart actions
- Crash count
- Success/failure of restarts

Example log output:
```
[Mon Feb 2 10:15:23 CST 2026] Checking Deskflow... State: S PID: 12345
[Mon Feb 2 10:15:33 CST 2026] Checking Deskflow... State: Z PID: 12345
[Mon Feb 2 10:15:33 CST 2026] ⚠️  Deskflow is DOWN or HUNG! (State: Z) - Restart #1
[Mon Feb 2 10:15:33 CST 2026] 🔄 Restarting Deskflow...
[Mon Feb 2 10:15:38 CST 2026] ✅ Deskflow restarted successfully
```

### Bug Report

If you want to report this to Deskflow developers:

**Title:** Deskflow crashes with SIGBUS in OSXScreenSaver::processLaunched()

**Description:**
Deskflow server crashes intermittently on macOS 15.2 (Sequoia) when screensaver launches or system processes start.

**Environment:**
- macOS: 15.2 (24C101)
- Deskflow: 1.25.0
- Hardware: MacBook Pro (M1 Pro)

**Crash Location:**
```
OSXScreenSaver::processLaunched(ProcessSerialNumber) + 52
CFRelease + 44
```

**Root Cause:**
NULL pointer being passed to `CFRelease()` in the screensaver monitoring code.

**Crash Reports Available:**
- 2026-02-02 09:59:36
- 2026-01-29 08:24:52

**Workaround:**
Using a LaunchAgent watchdog to auto-restart on crash.

---

## moltbot Fresh Setup

Automated setup for moltbot (OpenClaw AI assistant) with multi-model configuration.

**Location:** `moltbot-setup/`  
**Purpose:** Disaster recovery - fresh install on new/crashed laptop

### Quick Recovery After Laptop Crash

If your laptop crashes and you need to set up moltbot from scratch:

```bash
cd ~/apps/macos-utilities/moltbot-setup
./install.sh
```

Then authenticate:
```bash
cd ~/moltbot
./moltbot models auth login --provider google-antigravity
./moltbot models auth login-github-copilot
./start
```

**Total time: ~5 minutes** (vs 30-60 minutes manual setup)

### What Gets Installed

Fully configured moltbot with:
- ✅ 8 models (Google Antigravity + GitHub Copilot)
- ✅ 6-level automatic fallback chain
- ✅ Automatic retry on rate limits
- ✅ Start/stop scripts
- ✅ All data isolated in `~/moltbot/`

See [moltbot-setup/README.md](moltbot-setup/README.md) for details.

---

## moltbot VPS Deployment

Complete deployment package for running moltbot on a VPS using Docker.

**Location:** `moltbot-vps-deploy/`  
**Purpose:** Deploy moltbot to VPS with multi-model configuration

### Quick Deploy to VPS

Deploy your locally-configured moltbot to a VPS:

```bash
cd ~/apps/macos-utilities/moltbot-vps-deploy
./deploy.sh YOUR_VPS_IP
./copy-local-config.sh  # Sync multi-model config from local
```

**Total time: ~5 minutes** (including multi-model setup)

### What's Included

Complete VPS deployment package:
- ✅ Dockerfile with OpenClaw + dotenvx + jq
- ✅ docker-compose.yml for production
- ✅ Multi-model config (8 models, Google + GitHub)
- ✅ Automated deployment script
- ✅ Config sync from local `~/moltbot`
- ✅ Secret management with dotenvx
- ✅ Comprehensive documentation

### Key Features

- **Multi-Model Setup**: Primary model with 6-level fallback chain
- **OAuth Transfer**: Copies Google Antigravity + GitHub Copilot auth from local
- **Smart Config Merge**: Preserves VPS settings (channels, gateway) while updating LLM config
- **Encrypted Secrets**: dotenvx encryption for API keys/tokens
- **One Secret**: Only `DOTENV_PRIVATE_KEY_PROD` needed in Dokploy
- **Persistent State**: OAuth tokens, sessions, workspace preserved across restarts

### Architecture

```
Local ~/moltbot → copy-local-config.sh → VPS /home/moltbot/state
     ↓                                           ↓
Multi-model config                    Runtime config with OAuth
8 models configured                   All models working
```

### Documentation

- [README.md](moltbot-vps-deploy/README.md) - Complete deployment guide
- [QUICKSTART.md](moltbot-vps-deploy/QUICKSTART.md) - Quick reference

### Default VPS Configuration

- **IP**: 107.174.35.228 (configurable)
- **Port**: 18789 (localhost only, use SSH tunnel)
- **Platform**: Docker Compose + Dokploy
- **State**: `/home/moltbot/state` (persistent)
- **Workspace**: `/home/moltbot/workspace` (persistent)

---

## Future Utilities

This repository will contain additional macOS workflow utilities as needed.
