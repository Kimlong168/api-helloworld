#!/bin/bash
cd /var/www/api-helloworld || exit

echo "[🚀] Pulling latest code..."
git reset --hard
git pull origin main

echo "[📦] Installing dependencies..."
npm install

echo "[🏗️] Building and running app..."
npm start

echo "[♻️] Reloading with PM2 (zero downtime)..."
pm2 reload api-server
