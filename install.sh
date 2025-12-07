#!/bin/bash

# Jitsi Meet Auto-Installation Script
# For Ubuntu 22.04/20.04

set -e

echo "=========================================="
echo "Jitsi Meet Installation Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get server public IP
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

echo -e "${GREEN}✓ Detected server IP: ${SERVER_IP}${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root (use: sudo bash install.sh)${NC}"
    exit 1
fi

echo "Step 1: Updating system packages..."
apt update && apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo "Step 2: Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${YELLOW}✓ Docker already installed${NC}"
fi
echo ""

echo "Step 3: Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    apt install docker-compose -y
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${YELLOW}✓ Docker Compose already installed${NC}"
fi
echo ""

echo "Step 4: Installing Git..."
if ! command -v git &> /dev/null; then
    apt install git -y
    echo -e "${GREEN}✓ Git installed${NC}"
else
    echo -e "${YELLOW}✓ Git already installed${NC}"
fi
echo ""

echo "Step 5: Cloning Jitsi Meet repository..."
cd /opt
if [ -d "zvonilka" ]; then
    echo -e "${YELLOW}✓ Repository already exists, pulling latest changes${NC}"
    cd zvonilka
    git pull
else
    git clone https://github.com/brostan/zvonilka.git
    cd zvonilka
    echo -e "${GREEN}✓ Repository cloned${NC}"
fi
echo ""

echo "Step 6: Configuring environment variables..."
cd docker

if [ ! -f ".env" ]; then
    cp .env.example .env

    # Generate secure passwords
    JICOFO_PASS=$(openssl rand -hex 16)
    JVB_PASS=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 24)

    # Update .env file
    sed -i "s/JITSI_DOMAIN=.*/JITSI_DOMAIN=${SERVER_IP}/" .env
    sed -i "s/DOCKER_HOST_ADDRESS=.*/DOCKER_HOST_ADDRESS=${SERVER_IP}/" .env
    sed -i "s/JICOFO_AUTH_PASSWORD=.*/JICOFO_AUTH_PASSWORD=${JICOFO_PASS}/" .env
    sed -i "s/JVB_AUTH_PASSWORD=.*/JVB_AUTH_PASSWORD=${JVB_PASS}/" .env
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=${JWT_SECRET}/" .env
    sed -i "s/TZ=.*/TZ=Europe\/Moscow/" .env

    echo -e "${GREEN}✓ Environment configured${NC}"
    echo -e "${YELLOW}Configuration saved to: /opt/zvonilka/docker/.env${NC}"
else
    echo -e "${YELLOW}✓ .env file already exists${NC}"
fi
echo ""

echo "Step 7: Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 10000/udp
    echo -e "${GREEN}✓ Firewall configured${NC}"
else
    echo -e "${YELLOW}! UFW not installed, skipping firewall configuration${NC}"
fi
echo ""

echo "Step 8: Starting Jitsi Meet..."
docker-compose down 2>/dev/null || true
docker-compose pull
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "Access your Jitsi Meet instance at:"
echo -e "${GREEN}http://${SERVER_IP}${NC}"
echo ""
echo "To check status:"
echo "  cd /opt/zvonilka/docker"
echo "  docker-compose ps"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo ""
echo "To stop services:"
echo "  docker-compose down"
echo ""
echo "=========================================="
