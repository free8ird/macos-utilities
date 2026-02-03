# Moltbot Security Setup

## ⚠️ WARNING: Public Access Risk

When you deploy moltbot with a domain (`moltbot.yourdomain.com`), it's **publicly accessible** to anyone who knows the URL!

```
❌ WITHOUT AUTH:
Anyone → https://moltbot.yourdomain.com → Full access to your AI!

✅ WITH AUTH:
Anyone → https://moltbot.yourdomain.com → Password required → Access
```

## Quick Security Checklist

Before deploying:
- [ ] Choose authentication method (see below)
- [ ] Configure authentication in Dokploy OR moltbot config
- [ ] Test that password is required
- [ ] Configure DM pairing for messaging channels
- [ ] Set strong password (use `openssl rand -base64 32`)

## Authentication Methods

### Method 1: Dokploy Basic Auth ⭐ RECOMMENDED

**Easiest and works immediately**

In Dokploy UI:
1. Go to your moltbot app
2. Click "Security" or "Authentication"
3. Enable "Basic Authentication"
4. Set username: `admin`
5. Set password: (generate with `openssl rand -base64 32`)
6. Save and redeploy

Now when anyone visits your domain, they'll see:
```
┌─────────────────────────────────┐
│  Authentication Required        │
│                                 │
│  Username: [        ]           │
│  Password: [        ]           │
│                                 │
│  [Login]                        │
└─────────────────────────────────┘
```

### Method 2: Moltbot Password Auth

**Built-in moltbot authentication**

After deployment:

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Generate password
PASSWORD=$(openssl rand -base64 32)
echo "Save this password: $PASSWORD"

# Edit moltbot config
cat > /home/moltbot/.clawdbot/moltbot.json << EOF
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "gateway": {
    "port": 18789,
    "bind": "loopback",
    "auth": {
      "mode": "password",
      "password": "$PASSWORD"
    }
  }
}
EOF

# Restart
docker restart moltbot
```

### Method 3: IP Allowlist (Most Secure)

**Only allow specific IPs**

Get your IP:
```bash
curl ifconfig.me
```

In Dokploy, add Traefik labels to docker-compose or use Traefik middleware:

```yaml
labels:
  - "traefik.http.middlewares.moltbot-ipwhitelist.ipWhiteList.sourceRange=YOUR.IP.HERE/32"
  - "traefik.http.routers.moltbot.middlewares=moltbot-ipwhitelist"
```

### Method 4: No Public Access (Tailscale Only)

**Most secure - not public at all**

1. **Skip domain setup in Dokploy** - don't add any public domain
2. **Install Tailscale on VPS**:
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   tailscale up
   ```
3. **Access via Tailscale hostname only**:
   ```bash
   # On laptop (with Tailscale)
   npm install -g moltbot@latest
   cat > ~/.clawdbot/moltbot.json << 'EOF'
   {
     "gateway": {
       "mode": "remote",
       "remote": {
         "url": "ws://racknerd-vps:18789"  # Tailscale hostname
       }
     }
   }
   EOF
   ```

## Testing Authentication

After setting up auth, test it:

```bash
# Should require password
curl https://moltbot.yourdomain.com
# Expected: 401 Unauthorized

# With password (Basic Auth)
curl -u admin:your-password https://moltbot.yourdomain.com/health
# Expected: 200 OK

# With moltbot auth
curl https://moltbot.yourdomain.com/health
# Should work (health endpoint usually public)
```

## Messaging Channel Security

Even with web auth, configure DM policies for messaging:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dm": {
        "policy": "pairing"  // ← Requires approval
      }
    },
    "whatsapp": {
      "enabled": true,
      "dm": {
        "policy": "pairing"  // ← Requires approval
      }
    }
  }
}
```

When someone messages your bot:
1. They get a pairing code
2. You approve with: `docker exec -it moltbot node dist/index.js pairing approve telegram CODE`
3. Then they can chat

## Laptop Configuration with Auth

### With Dokploy Basic Auth

```bash
cat > ~/.clawdbot/moltbot.json << 'EOF'
{
  "gateway": {
    "mode": "remote",
    "remote": {
      "url": "wss://moltbot.yourdomain.com",
      "auth": {
        "username": "admin",
        "password": "your-basic-auth-password"
      }
    }
  }
}
EOF
```

### With Moltbot Password

```bash
cat > ~/.clawdbot/moltbot.json << 'EOF'
{
  "gateway": {
    "mode": "remote",
    "remote": {
      "url": "wss://moltbot.yourdomain.com",
      "password": "your-moltbot-password"
    }
  }
}
EOF
```

## Monitoring & Alerts

Check for unauthorized access:

```bash
# Check Dokploy logs
# Look for 401 errors (failed auth attempts)

# Check moltbot logs
docker logs moltbot | grep "auth"

# Set up fail2ban (optional)
# Bans IPs after failed attempts
```

## Recommended Setup

For most users:

1. **Dokploy Basic Auth** - Quick and easy
2. **Moltbot DM pairing** - Approve contacts manually  
3. **Strong password** - Generate with OpenSSL
4. **HTTPS only** - Dokploy handles this
5. **Regular backups** - Weekly backups of `/home/moltbot/`

## FAQs

**Q: Can I use both Dokploy auth AND moltbot auth?**  
A: Yes! Double protection. Dokploy blocks at proxy level, moltbot at app level.

**Q: What if I forget the password?**  
A: SSH to VPS, edit `/home/moltbot/.clawdbot/moltbot.json`, set new password, restart.

**Q: Is HTTPS enough?**  
A: NO! HTTPS encrypts traffic but doesn't stop unauthorized access. You need authentication.

**Q: What about rate limiting?**  
A: Dokploy/Traefik can add rate limiting via middleware.

**Q: Should I use a random subdomain?**  
A: Security through obscurity is weak. Use proper auth instead.

## Resources

- [Moltbot Security Docs](https://docs.molt.bot/gateway/security)
- [Dokploy Security](https://dokploy.com/docs)
- [Traefik Middlewares](https://doc.traefik.io/traefik/middlewares/overview/)
