# moltbot Fresh Setup

## Quick Start (After Laptop Crash)

If your laptop crashes and you need to set up moltbot from scratch:

```bash
cd ~/apps/macos-utilities/moltbot-setup
./install.sh
```

Then authenticate:
```bash
cd ~/moltbot

# Authenticate Google Antigravity
./moltbot models auth login --provider google-antigravity

# Authenticate GitHub Copilot
./moltbot models auth login-github-copilot

# Verify
./moltbot models status
```

Done! Your moltbot is ready with the same multi-model configuration.

## What Gets Installed

The script creates:

```
~/moltbot/
├── moltbot              # CLI launcher
├── start                # Start moltbot
├── stop                 # Stop moltbot
├── status               # Check status
├── package.json         # npm config
├── node_modules/        # OpenClaw installed
├── config/
│   └── openclaw.json    # Pre-configured with multi-model
├── data/                # Created on first run (auth + memories)
└── workspace/           # Created on first run
```

## Pre-Configured Features

✅ **8 Models:**
- google-antigravity/gemini-3-pro-high (Primary)
- google-antigravity/claude-opus-4-5-thinking
- google-antigravity/gemini-3-flash
- github-copilot/gpt-4o
- github-copilot/claude-sonnet-4-5
- github-copilot/o1
- github-copilot/o1-mini
- github-copilot/gpt-4o-mini

✅ **6-Level Fallback Chain:**
```
Primary → claude-opus-4-5-thinking → gpt-4o → 
claude-sonnet-4-5 → o1 → gemini-3-flash → gpt-4o-mini
```

✅ **Automatic Retry:**
- On rate limits → try next model
- On timeouts → try next model
- On errors → try next model

✅ **All Data Isolated:**
- Everything in `~/moltbot/`
- No `~/.openclaw/` pollution
- Easy to backup/restore

## Authentication

The only manual step after install is authenticating with providers.

### Google Antigravity

```bash
cd ~/moltbot
./moltbot models auth login --provider google-antigravity
```

Opens browser → Login with Google → Authorize → Done

### GitHub Copilot

```bash
./moltbot models auth login-github-copilot
```

Displays device code → Opens browser → Enter code → Authorize → Done

## Usage

```bash
cd ~/moltbot

# Start
./start

# Check status
./status

# Stop
./stop

# Chat via terminal
./moltbot tui

# Send command
./moltbot agent --local --agent main --message "Hello"

# View logs
tail -f moltbot.log
```

## Files in This Setup

### `config-template.json`
Pre-configured OpenClaw config with:
- Multi-model setup
- Fallback chains
- Gateway settings
- Plugin config

**NOTE:** Auth profiles are NOT included (you add them by authenticating)

### `install.sh`
Installation script that:
1. Creates `~/moltbot/` directory
2. Installs OpenClaw via npm
3. Copies config template
4. Creates launcher scripts
5. Sets up directory structure

## What's NOT Included (By Design)

❌ **Auth tokens** - You need to authenticate after setup
❌ **Chat history** - Fresh start
❌ **Agent memories** - Fresh start
❌ **Workspace files** - Fresh start

These are created when you authenticate and start using moltbot.

## Backup Strategy

To backup your working moltbot (including auth):

```bash
cd ~
tar -czf moltbot-backup-$(date +%Y%m%d).tar.gz moltbot/
```

To restore:
```bash
cd ~
tar -xzf moltbot-backup-20260202.tar.gz
```

## GitHub Storage

This directory (`~/apps/macos-utilities/moltbot-setup/`) is version controlled:

```
~/apps/macos-utilities/
├── .git/
├── moltbot-setup/           # ← This is in git
│   ├── config-template.json # ← Multi-model config
│   ├── install.sh           # ← Setup script
│   └── README.md            # ← This file
└── ...
```

After laptop crash:
1. Clone macos-utilities repo
2. Run `moltbot-setup/install.sh`
3. Authenticate with providers
4. Start using moltbot

## Testing the Setup

Want to test without removing your current moltbot?

```bash
# Temporarily rename your moltbot
mv ~/moltbot ~/moltbot.backup

# Run install
cd ~/apps/macos-utilities/moltbot-setup
./install.sh

# Test it
cd ~/moltbot
./moltbot models status

# Restore if needed
rm -rf ~/moltbot
mv ~/moltbot.backup ~/moltbot
```

## Comparison: Before vs After

**Before (Manual Setup):**
1. Install OpenClaw: `npm install openclaw`
2. Create directories manually
3. Run `openclaw setup`
4. Run `openclaw onboard` (interactive wizard)
5. Configure multi-model manually
6. Add all 8 models
7. Set up fallback chain
8. Create start/stop scripts
9. Configure workspace paths
10. **Total time: ~30-60 minutes**

**After (This Setup):**
1. Run `./install.sh`
2. Authenticate Google Antigravity
3. Authenticate GitHub Copilot
4. **Total time: ~5 minutes**

All the multi-model configuration is pre-done!

## Next Steps

After running install.sh:
1. Follow the authentication prompts
2. Run `./moltbot models status` to verify
3. Run `./start` to start moltbot
4. Use `./moltbot tui` for interactive chat

Your moltbot is ready with the exact same setup you had before!
