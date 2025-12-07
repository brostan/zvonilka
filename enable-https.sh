#!/bin/bash

# Enable HTTPS for Jitsi Meet with Self-Signed Certificate
# This allows camera/microphone access in browsers

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Enabling HTTPS for Jitsi Meet"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root${NC}"
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo -e "${GREEN}Server IP: ${SERVER_IP}${NC}"
echo ""

# Navigate to project directory
cd /opt/zvonilka/docker

echo "Step 1: Stopping Jitsi Meet containers..."
docker compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Step 2: Creating SSL certificates directory..."
mkdir -p ./web/certs
cd ./web/certs
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo "Step 3: Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout privkey.pem \
    -out fullchain.pem \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=Jitsi/OU=IT/CN=${SERVER_IP}" \
    -addext "subjectAltName = IP:${SERVER_IP}"

chmod 644 privkey.pem fullchain.pem
echo -e "${GREEN}✓ Certificate generated${NC}"
echo ""

cd /opt/zvonilka/docker

echo "Step 4: Updating docker-compose.yml for HTTPS..."

# Create backup
cp docker-compose.yml docker-compose.yml.backup

# Update web service to mount certificates
cat > docker-compose-https.yml <<EOF
version: '3'

services:
  prosody:
    image: jitsi/prosody:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    volumes:
      - prosody-config:/config
    environment:
      - XMPP_DOMAIN=\${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=\${XMPP_AUTH_DOMAIN}
      - XMPP_MUC_DOMAIN=\${XMPP_MUC_DOMAIN}
      - XMPP_INTERNAL_MUC_DOMAIN=\${XMPP_INTERNAL_MUC_DOMAIN}
      - XMPP_MODULES=mod_mam
      - PROSODY_AUTH=internal_plain
      - TZ=\${TZ}
      - PUBLIC_URL=https://\${JITSI_DOMAIN}
      - ENABLE_AUTH=\${ENABLE_AUTH}
      - JICOFO_AUTH_PASSWORD=\${JICOFO_AUTH_PASSWORD}
      - JVB_AUTH_PASSWORD=\${JVB_AUTH_PASSWORD}

  jicofo:
    image: jitsi/jicofo:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    volumes:
      - jicofo-config:/config
    environment:
      - XMPP_DOMAIN=\${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=\${XMPP_AUTH_DOMAIN}
      - XMPP_BREWERY=\${XMPP_MUC_DOMAIN}
      - JICOFO_AUTH_USER=\${JICOFO_AUTH_USER}
      - JICOFO_AUTH_PASSWORD=\${JICOFO_AUTH_PASSWORD}
      - TZ=\${TZ}
    depends_on:
      - prosody

  jvb:
    image: jitsi/jvb:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    ports:
      - "\${JVB_PORT}:\${JVB_PORT}/udp"
    volumes:
      - jvb-config:/config
    environment:
      - XMPP_DOMAIN=\${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=\${XMPP_AUTH_DOMAIN}
      - JVB_AUTH_USER=\${JVB_AUTH_USER}
      - JVB_AUTH_PASSWORD=\${JVB_AUTH_PASSWORD}
      - JVB_PORT=\${JVB_PORT}
      - JVB_TCP_HARVESTER_PORT=\${JVB_TCP_HARVESTER_PORT}
      - DOCKER_HOST_ADDRESS=\${DOCKER_HOST_ADDRESS}
      - TZ=\${TZ}
    depends_on:
      - prosody

  web:
    image: jitsi/web:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - web-config:/config
      - ./web/certs:/config/keys:ro
    environment:
      - XMPP_DOMAIN=\${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=\${XMPP_AUTH_DOMAIN}
      - XMPP_MUC_DOMAIN=\${XMPP_MUC_DOMAIN}
      - ENABLE_AUTH=\${ENABLE_AUTH}
      - JWT_SECRET=\${JWT_SECRET}
      - PUBLIC_URL=https://\${JITSI_DOMAIN}
      - TZ=\${TZ}
      - ENABLE_HTTP_REDIRECT=1
    depends_on:
      - prosody

networks:
  jitsi-net:
    driver: bridge

volumes:
  prosody-config:
  jicofo-config:
  jvb-config:
  web-config:
EOF

mv docker-compose-https.yml docker-compose.yml
echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

echo "Step 5: Starting Jitsi Meet with HTTPS..."
docker compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services
echo "Waiting for services to start..."
sleep 15

echo ""
echo "=========================================="
echo -e "${GREEN}✓ HTTPS Enabled Successfully!${NC}"
echo "=========================================="
echo ""
echo "Access Jitsi Meet at:"
echo -e "${GREEN}https://${SERVER_IP}${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "Your browser will show a security warning because"
echo "we're using a self-signed certificate."
echo ""
echo "To proceed:"
echo "1. Click 'Advanced' or 'Show Details'"
echo "2. Click 'Proceed to ${SERVER_IP}' (or similar)"
echo "3. Accept the security exception"
echo ""
echo "After that, camera/microphone will work!"
echo ""
echo "=========================================="
