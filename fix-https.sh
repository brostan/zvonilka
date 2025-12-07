#!/bin/bash

# Fix HTTPS configuration for Jitsi Meet
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Fixing HTTPS Configuration"
echo "=========================================="
echo ""

cd /opt/zvonilka/docker

echo "Step 1: Stopping containers..."
docker compose down
echo -e "${GREEN}✓ Stopped${NC}"
echo ""

echo "Step 2: Removing old configuration..."
docker volume rm docker_web-config 2>/dev/null || true
rm -rf web/certs 2>/dev/null || true
echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

echo "Step 3: Restoring working configuration..."
git checkout docker-compose.yml
echo -e "${GREEN}✓ Restored${NC}"
echo ""

echo "Step 4: Starting Jitsi Meet..."
docker compose up -d
echo -e "${GREEN}✓ Started${NC}"
echo ""

sleep 10

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Jitsi Meet is running!${NC}"
echo "=========================================="
echo ""
echo "Access at: ${GREEN}http://95.81.121.77${NC}"
echo ""
echo -e "${YELLOW}For camera/microphone access:${NC}"
echo ""
echo "In Chrome, enable this flag:"
echo "  chrome://flags/#unsafely-treat-insecure-origin-as-secure"
echo ""
echo "Add: http://95.81.121.77"
echo "Set to: Enabled"
echo "Restart Chrome"
echo ""
echo "OR use ngrok/CloudFlare Tunnel for instant HTTPS"
echo "=========================================="
