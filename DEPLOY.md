# Deployment Guide - Jitsi Meet on VPS

This guide will help you deploy Jitsi Meet to your VPS using Docker Compose.

## Prerequisites

- VPS with Ubuntu 20.04+ or Debian 11+
- At least 2GB RAM, 2 CPU cores
- Domain name pointing to your VPS IP (optional but recommended)
- Ports 80, 443, 10000/udp open in firewall

## Step 1: Prepare Your VPS

SSH into your VPS:
```bash
ssh root@YOUR_VPS_IP
```

Update the system:
```bash
apt update && apt upgrade -y
```

Install Docker and Docker Compose:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

## Step 2: Clone the Repository

```bash
cd /opt
git clone https://github.com/brostan/zvonilka.git
cd zvonilka/docker
```

## Step 3: Configure Environment Variables

Create the `.env` file from the example:
```bash
cp .env.example .env
nano .env
```

Update the following variables:
- `JITSI_DOMAIN`: Your domain name (e.g., meet.example.com) or VPS IP
- `DOCKER_HOST_ADDRESS`: Your VPS public IP address
- `JICOFO_AUTH_PASSWORD`: Generate a strong password
- `JVB_AUTH_PASSWORD`: Generate a strong password
- `JWT_SECRET`: Generate a random secret (if using authentication)
- `TZ`: Your timezone (e.g., Europe/Moscow)

Example for generating passwords:
```bash
openssl rand -hex 16
```

## Step 4: Configure Firewall

Allow necessary ports:
```bash
# UFW (Ubuntu)
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10000/udp
ufw enable

# OR firewalld (CentOS/RHEL)
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=10000/udp
firewall-cmd --reload
```

## Step 5: Deploy Jitsi Meet

Start the services:
```bash
docker-compose up -d
```

Check the status:
```bash
docker-compose ps
```

All services should show "Up" status.

View logs:
```bash
docker-compose logs -f
```

## Step 6: Access Your Jitsi Meet Instance

Open your browser and navigate to:
- `http://YOUR_VPS_IP` or
- `https://YOUR_DOMAIN`

You should see the Jitsi Meet welcome page!

## SSL/TLS Configuration (Recommended)

For production use with a domain, set up SSL with Let's Encrypt:

1. Install certbot:
```bash
apt install certbot -y
```

2. Stop the web container temporarily:
```bash
docker-compose stop web
```

3. Obtain SSL certificate:
```bash
certbot certonly --standalone -d YOUR_DOMAIN
```

4. Update docker-compose.yml to mount certificates:
```yaml
web:
  volumes:
    - web-config:/config
    - /etc/letsencrypt:/etc/letsencrypt:ro
```

5. Restart services:
```bash
docker-compose up -d
```

## Useful Commands

### Restart services:
```bash
docker-compose restart
```

### Stop services:
```bash
docker-compose down
```

### View logs for a specific service:
```bash
docker-compose logs -f prosody
docker-compose logs -f jvb
docker-compose logs -f jicofo
docker-compose logs -f web
```

### Update to latest version:
```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Containers keep restarting:
Check logs for errors:
```bash
docker-compose logs
```

### Can't connect to meeting:
- Verify firewall allows UDP port 10000
- Check `DOCKER_HOST_ADDRESS` is set to your public IP
- Ensure ports 80/443 are accessible

### Audio/Video not working:
- Check browser permissions for camera/microphone
- Verify UDP port 10000 is open
- Check JVB logs: `docker-compose logs jvb`

## Security Recommendations

1. Enable authentication in `.env`:
   ```
   ENABLE_AUTH=1
   ```

2. Use strong passwords for all auth variables

3. Keep Docker images updated:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

4. Set up automatic SSL renewal:
   ```bash
   certbot renew --dry-run
   ```

5. Configure UFW/firewall to only allow necessary ports

## Monitoring

Check service health:
```bash
docker-compose ps
docker stats
```

Check disk usage:
```bash
docker system df
```

Clean up unused resources:
```bash
docker system prune -a
```
