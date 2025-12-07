#!/bin/bash

# Setup Domain and Let's Encrypt SSL for Jitsi Meet

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Domain + SSL Setup for Jitsi Meet"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root${NC}"
    exit 1
fi

# Get domain name from user
echo -e "${YELLOW}Enter your domain name (e.g., meet.yourdomain.com):${NC}"
read DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo -e "${RED}✗ Domain name is required${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Domain: ${DOMAIN_NAME}${NC}"
echo ""

# Get email for Let's Encrypt
echo -e "${YELLOW}Enter your email for Let's Encrypt notifications:${NC}"
read EMAIL_ADDRESS

if [ -z "$EMAIL_ADDRESS" ]; then
    echo -e "${RED}✗ Email is required${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Before proceeding, make sure:${NC}"
echo "1. Your domain DNS A record points to: $(curl -s ifconfig.me)"
echo "2. DNS has propagated (you can check with: nslookup $DOMAIN_NAME)"
echo ""
read -p "Press Enter to continue when DNS is ready..."

cd /opt/zvonilka/docker

echo ""
echo "Step 1: Updating .env configuration..."

# Update .env file
sed -i "s/JITSI_DOMAIN=.*/JITSI_DOMAIN=${DOMAIN_NAME}/" .env
echo -e "${GREEN}✓ Domain updated in .env${NC}"
echo ""

echo "Step 2: Stopping containers temporarily..."
docker compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Step 3: Installing Certbot..."
apt update
apt install -y certbot
echo -e "${GREEN}✓ Certbot installed${NC}"
echo ""

echo "Step 4: Obtaining SSL certificate..."
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL_ADDRESS} \
    -d ${DOMAIN_NAME} \
    --preferred-challenges http

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate obtained!${NC}"
else
    echo -e "${RED}✗ Failed to obtain SSL certificate${NC}"
    echo "Please check:"
    echo "1. DNS is correctly configured"
    echo "2. Port 80 is accessible"
    echo "3. Domain is not already in use"
    exit 1
fi
echo ""

echo "Step 5: Creating certificate directory..."
mkdir -p ./web/certs
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo "Step 6: Copying certificates..."
cp /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem ./web/certs/
cp /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem ./web/certs/
chmod 644 ./web/certs/*.pem
echo -e "${GREEN}✓ Certificates copied${NC}"
echo ""

echo "Step 7: Updating docker-compose.yml..."
# Update web service to mount certificates
cat > docker-compose.yml.tmp <<'EOF'
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
      - XMPP_DOMAIN=${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=${XMPP_AUTH_DOMAIN}
      - XMPP_MUC_DOMAIN=${XMPP_MUC_DOMAIN}
      - XMPP_INTERNAL_MUC_DOMAIN=${XMPP_INTERNAL_MUC_DOMAIN}
      - XMPP_MODULES=mod_mam
      - PROSODY_AUTH=internal_plain
      - TZ=${TZ}
      - PUBLIC_URL=https://${JITSI_DOMAIN}
      - ENABLE_AUTH=${ENABLE_AUTH}
      - JICOFO_AUTH_PASSWORD=${JICOFO_AUTH_PASSWORD}
      - JVB_AUTH_PASSWORD=${JVB_AUTH_PASSWORD}

  jicofo:
    image: jitsi/jicofo:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    volumes:
      - jicofo-config:/config
    environment:
      - XMPP_DOMAIN=${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=${XMPP_AUTH_DOMAIN}
      - XMPP_SERVER=prosody
      - XMPP_BREWERY=${XMPP_MUC_DOMAIN}
      - JICOFO_AUTH_USER=${JICOFO_AUTH_USER}
      - JICOFO_AUTH_PASSWORD=${JICOFO_AUTH_PASSWORD}
      - TZ=${TZ}
    depends_on:
      - prosody

  jvb:
    image: jitsi/jvb:stable-9584
    restart: unless-stopped
    networks:
      - jitsi-net
    ports:
      - "${JVB_PORT}:${JVB_PORT}/udp"
    volumes:
      - jvb-config:/config
    environment:
      - XMPP_DOMAIN=${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=${XMPP_AUTH_DOMAIN}
      - XMPP_SERVER=prosody
      - JVB_AUTH_USER=${JVB_AUTH_USER}
      - JVB_AUTH_PASSWORD=${JVB_AUTH_PASSWORD}
      - JVB_PORT=${JVB_PORT}
      - JVB_TCP_HARVESTER_PORT=${JVB_TCP_HARVESTER_PORT}
      - DOCKER_HOST_ADDRESS=${DOCKER_HOST_ADDRESS}
      - TZ=${TZ}
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
      - /etc/letsencrypt:/etc/letsencrypt:ro
    environment:
      - XMPP_DOMAIN=${XMPP_DOMAIN}
      - XMPP_AUTH_DOMAIN=${XMPP_AUTH_DOMAIN}
      - XMPP_MUC_DOMAIN=${XMPP_MUC_DOMAIN}
      - ENABLE_AUTH=${ENABLE_AUTH}
      - JWT_SECRET=${JWT_SECRET}
      - PUBLIC_URL=https://${JITSI_DOMAIN}
      - TZ=${TZ}
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

mv docker-compose.yml.tmp docker-compose.yml
echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

echo "Step 8: Starting Jitsi Meet with HTTPS..."
docker compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

echo "Step 9: Setting up automatic certificate renewal..."
cat > /etc/cron.d/certbot-renew <<EOF
0 3 * * * root certbot renew --quiet --deploy-hook "cd /opt/zvonilka/docker && cp /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem ./web/certs/ && cp /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem ./web/certs/ && docker compose restart web"
EOF
echo -e "${GREEN}✓ Auto-renewal configured${NC}"
echo ""

# Stop CloudFlare tunnel if running
if systemctl is-active --quiet cloudflared-jitsi; then
    echo "Step 10: Stopping CloudFlare Tunnel (no longer needed)..."
    systemctl stop cloudflared-jitsi
    systemctl disable cloudflared-jitsi
    echo -e "${GREEN}✓ CloudFlare Tunnel stopped${NC}"
    echo ""
fi

sleep 10

echo ""
echo "=========================================="
echo -e "${GREEN}✓ SSL Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Your Jitsi Meet is now available at:"
echo -e "${GREEN}https://${DOMAIN_NAME}${NC}"
echo ""
echo "Features enabled:"
echo "  ✓ HTTPS with valid SSL certificate"
echo "  ✓ Camera and microphone access"
echo "  ✓ Automatic certificate renewal"
echo "  ✓ HTTP to HTTPS redirect"
echo ""
echo "Certificate will auto-renew every 90 days."
echo ""
echo "Useful commands:"
echo "  Check SSL expiry: certbot certificates"
echo "  Renew manually:   certbot renew"
echo "  View logs:        docker compose logs -f"
echo ""
echo "=========================================="
