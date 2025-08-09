# #!/bin/bash
# cd /var/www/api-helloworld || exit

# echo "[🚀] Pulling latest code..."
# git reset --hard
# git pull origin main

# echo "[📦] Installing dependencies..."
# npm install

# echo "[🏗️] Building and running app..."
# npm start

# echo "[♻️] Reloading with PM2 (zero downtime)..."
# pm2 reload api-server


#!/usr/bin/env bash
set -euo pipefail

# Usage: deploy.sh <tag-or-sha>
TAG_OR_SHA="${1:-}"

REPO_DIR="/var/www/api-helloworld"
APP_NAME="api-server"   # your PM2 process name

if [[ -z "$TAG_OR_SHA" ]]; then
  echo "Error: tag/sha not provided. Usage: deploy.sh <tag-or-sha>"
  exit 1
fi

echo "[📍] Target ref: $TAG_OR_SHA"

cd "$REPO_DIR"

echo "[🔄] Fetching repo & tags..."
git fetch --all --tags --prune

# Checkout the exact release ref
if git rev-parse -q --verify "refs/tags/$TAG_OR_SHA" >/dev/null; then
  echo "[📦] Checking out tag $TAG_OR_SHA..."
  git checkout -f "tags/$TAG_OR_SHA"
else
  echo "[📦] Tag not found, checking out commit $TAG_OR_SHA..."
  git checkout -f "$TAG_OR_SHA"
fi

echo "[📦] Installing dependencies..."
# Prefer reproducible installs; falls back to npm install if lockfile missing
if [[ -f package-lock.json ]]; then
  npm ci --omit=dev
else
  npm install --omit=dev
fi

# Build if you have a build script
if npm run | grep -qE ' build'; then
  echo "[🏗️] Building app..."
  npm run build
fi

echo "[🚀] (Re)starting app with PM2..."
# Reload if running; otherwise start via npm start under PM2
if pm2 list | grep -q "$APP_NAME"; then
  pm2 reload "$APP_NAME" --update-env
else
  pm2 start npm --name "$APP_NAME" -- start
fi

pm2 save || true

echo "[✅] Deployed $TAG_OR_SHA"
