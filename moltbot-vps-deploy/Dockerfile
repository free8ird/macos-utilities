# =============================================================================
# Moltbot VPS Deployment Dockerfile
# OpenClaw + dotenvx Secret Management + jq Config Merging
# =============================================================================
# syntax=docker/dockerfile:1

# Use Node.js 22 base image
FROM node:22-slim

# Install system dependencies including git (required by npm)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    git \
    openssh-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sfS https://dotenvx.sh/install.sh | sh

# Install OpenClaw globally (latest version)
RUN npm install -g openclaw@latest

# Create app directory and set ownership
RUN mkdir -p /app && chown -R node:node /app

# Copy configuration files
COPY --chown=node:node config.json /app/config.json
COPY --chown=node:node exec-approvals.json /app/exec-approvals.json
COPY --chown=node:node entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy encrypted .env.prod file
COPY --chown=node:node .env.prod /app/.env.prod

# Switch to node user
USER node

# Set working directory
WORKDIR /app

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
