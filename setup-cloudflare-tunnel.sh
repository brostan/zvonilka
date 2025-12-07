#!/bin/bash

# Setup CloudFlare Tunnel for Jitsi Meet
# Provides free HTTPS access without SSL certificates

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "CloudFlare Tunnel Setup for Jitsi Meet"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root${NC}"
    exit 1
fi

cd /opt/zvonilka/docker

echo "Step 1: Restoring working HTTP configuration..."
docker compose down 2>/dev/null || true
docker volume rm docker_web-config 2>/dev/null || true
rm -rf web/certs 2>/dev/null || true
git checkout docker-compose.yml 2>/dev/null || true
echo -e "${GREEN}✓ Configuration restored${NC}"
echo ""

echo "Step 2: Starting Jitsi Meet..."
docker compose up -d
sleep 10
echo -e "${GREEN}✓ Jitsi Meet started${NC}"
echo ""

echo "Step 3: Installing CloudFlare Tunnel..."

# Download cloudflared
if [ ! -f "/usr/local/bin/cloudflared" ]; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
    echo -e "${GREEN}✓ CloudFlare Tunnel installed${NC}"
else
    echo -e "${YELLOW}✓ CloudFlare Tunnel already installed${NC}"
fi
echo ""

echo "Step 4: Creating tunnel service..."

# Create systemd service for cloudflared
cat > /etc/systemd/system/cloudflared-jitsi.service <<EOF
[Unit]
Description=CloudFlare Tunnel for Jitsi Meet
After=network.target docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --url http://localhost:80 --no-autoupdate
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cloudflared-jitsi
systemctl start cloudflared-jitsi

echo -e "${GREEN}✓ Tunnel service created and started${NC}"
echo ""

echo "Step 5: Waiting for tunnel to establish..."
sleep 5

# Get the tunnel URL from logs
TUNNEL_URL=""
for i in {1..10}; do
    TUNNEL_URL=$(journalctl -u cloudflared-jitsi -n 50 --no-pager | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' | head -1)
    if [ ! -z "$TUNNEL_URL" ]; then
        break
    fi
    sleep 2
done

echo ""
echo "=========================================="
echo -e "${GREEN}✓ CloudFlare Tunnel Ready!${NC}"
echo "=========================================="
echo ""

if [ ! -z "$TUNNEL_URL" ]; then
    echo -e "Your Jitsi Meet is now available at:"
    echo -e "${GREEN}${TUNNEL_URL}${NC}"
    echo ""
    echo "This URL has HTTPS enabled automatically!"
    echo "Camera and microphone will work!"
else
    echo -e "${YELLOW}Tunnel is starting...${NC}"
    echo ""
    echo "To see your tunnel URL, run:"
    echo "  journalctl -u cloudflared-jitsi -f"
    echo ""
    echo "Look for a line with: https://....trycloudflare.com"
fi

echo ""
echo "Useful commands:"
echo "  View tunnel URL:     journalctl -u cloudflared-jitsi | grep trycloudflare"
echo "  Check tunnel status: systemctl status cloudflared-jitsi"
echo "  Restart tunnel:      systemctl restart cloudflared-jitsi"
echo "  Stop tunnel:         systemctl stop cloudflared-jitsi"
echo ""
echo "=========================================="
