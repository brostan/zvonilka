# Server Requirements for Jitsi Meet

## Recommended Operating System

**Ubuntu Server 22.04 LTS** (recommended)
- Alternative: Ubuntu Server 20.04 LTS
- Also compatible: Debian 11 (Bullseye) or Debian 12 (Bookworm)

## Hardware Requirements

### Minimum Requirements (for testing/small meetings)
- **CPU:** 2 cores (2 GHz+)
- **RAM:** 2 GB
- **Storage:** 20 GB SSD
- **Network:** 10 Mbps symmetric
- **Participants:** Up to 5-10 concurrent users

### Recommended Requirements (for production)
- **CPU:** 4 cores (2.5 GHz+)
- **RAM:** 4 GB
- **Storage:** 40 GB SSD
- **Network:** 100 Mbps symmetric
- **Participants:** Up to 20-35 concurrent users

### High Load Requirements (for large deployments)
- **CPU:** 8+ cores (3 GHz+)
- **RAM:** 8 GB+
- **Storage:** 100 GB SSD
- **Network:** 1 Gbps symmetric
- **Participants:** 50+ concurrent users

## CPU and RAM Scaling

Number of participants in a single meeting affects resource usage:

| Participants | CPU Cores | RAM   | Network Bandwidth |
|--------------|-----------|-------|-------------------|
| 5-10         | 2 cores   | 2 GB  | 10 Mbps          |
| 10-20        | 4 cores   | 4 GB  | 50 Mbps          |
| 20-35        | 4 cores   | 8 GB  | 100 Mbps         |
| 35-50        | 8 cores   | 8 GB  | 200 Mbps         |
| 50-100       | 8+ cores  | 16 GB | 500 Mbps         |

**Note:** Multiple simultaneous meetings multiply these requirements.

## Network Requirements

### Required Ports

**TCP Ports:**
- `80` - HTTP (for Let's Encrypt certificate validation)
- `443` - HTTPS (web interface)

**UDP Ports:**
- `10000` - JVB media traffic (required for video/audio)

### Firewall Configuration

```bash
# Ubuntu/Debian (UFW)
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10000/udp
ufw enable

# Check status
ufw status
```

### Network Considerations
- **Public IP required:** Server must have a public IPv4 address
- **Low latency:** <50ms ping time for best quality
- **Stable connection:** Avoid bandwidth fluctuations
- **No NAT issues:** If behind NAT, configure port forwarding correctly

## Storage Requirements

### Disk Space Breakdown
- **OS and system:** ~10 GB
- **Docker images:** ~2.5 GB
  - jitsi/prosody: ~240 MB
  - jitsi/web: ~329 MB
  - jitsi/jicofo: ~677 MB
  - jitsi/jvb: ~829 MB
  - Base images: ~500 MB
- **Logs and configs:** 1-5 GB (grows over time)
- **Free space reserve:** 10+ GB recommended

### Disk Type
- **SSD strongly recommended** for better I/O performance
- NVMe SSD ideal for high-load scenarios

## Software Requirements

### Required Software
- **Docker:** 20.10+ or Docker CE 24.0+
- **Docker Compose:** 1.29+ or 2.0+
- **Git:** For cloning the repository

### Installation on Ubuntu 22.04

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose (if not included)
sudo apt install docker-compose-plugin -y

# Install Git
sudo apt install git -y

# Verify installations
docker --version
docker compose version
git --version
```

## Optional but Recommended

### Domain Name
- **Recommended:** Use a domain name with SSL/TLS
- **Alternative:** Can use IP address (less secure, browser warnings)
- **SSL Certificate:** Let's Encrypt (free) or commercial certificate

### DNS Configuration
If using a domain:
```
A record: meet.yourdomain.com -> YOUR_VPS_IP
```

### Monitoring Tools
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs -y
```

## VPS Provider Recommendations

### Suitable Providers (with approximate pricing)

**Budget Options ($5-10/month):**
- **DigitalOcean** - Droplet (2 vCPU, 2GB RAM, 50GB SSD)
- **Hetzner Cloud** - CX21 (2 vCPU, 4GB RAM, 40GB SSD)
- **Vultr** - Regular Performance (2 vCPU, 4GB RAM, 80GB SSD)
- **Linode** - Shared CPU (2 vCPU, 4GB RAM, 80GB SSD)

**Recommended Options ($15-25/month):**
- **DigitalOcean** - Droplet (2 vCPU, 4GB RAM, 80GB SSD)
- **Hetzner Cloud** - CPX21 (3 vCPU, 4GB RAM, 80GB SSD)
- **AWS Lightsail** - 2 vCPU, 4GB RAM, 80GB SSD
- **Contabo** - VPS M (4 vCPU, 8GB RAM, 200GB SSD) - very affordable

**High Performance ($40-80/month):**
- **DigitalOcean** - Droplet (4 vCPU, 8GB RAM, 160GB SSD)
- **Hetzner Dedicated** - AX41 (8 cores, 64GB RAM, 2x512GB NVMe)
- **OVH** - VPS or Dedicated servers

### Selection Criteria
✅ Good network connectivity and low latency
✅ SSD storage
✅ Hourly billing option (for testing)
✅ IPv4 address included
✅ No traffic limits or high traffic allowance
✅ Good uptime guarantee (99.9%+)

## Security Requirements

### Minimum Security Setup
```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Enable firewall
sudo ufw enable

# (Optional) Disable root SSH login
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd

# (Optional) Install fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

## Performance Testing

### After Installation, Test Performance

```bash
# Check CPU
lscpu

# Check RAM
free -h

# Check disk speed
sudo hdparm -Tt /dev/sda

# Check network speed
sudo apt install speedtest-cli -y
speedtest-cli

# Monitor resources during a meeting
htop
```

## Pre-Deployment Checklist

Before deploying Jitsi Meet, ensure:

- [ ] Ubuntu 22.04 LTS installed
- [ ] At least 2 CPU cores and 4GB RAM
- [ ] SSD storage with 40+ GB free space
- [ ] Public IP address assigned
- [ ] Ports 80, 443, 10000/udp open in firewall
- [ ] Docker and Docker Compose installed
- [ ] (Optional) Domain name configured with A record
- [ ] SSH access to server configured
- [ ] Root or sudo access available

## Estimated Costs

### Monthly Cost Estimates

| Usage Level | Server Specs | Recommended Provider | Est. Cost/Month |
|-------------|--------------|----------------------|-----------------|
| Testing     | 2 vCPU, 2GB  | Hetzner CX11        | $4-5           |
| Small team  | 2 vCPU, 4GB  | Hetzner CX21        | $7-8           |
| Medium team | 4 vCPU, 8GB  | Hetzner CPX31       | $15-20         |
| Large team  | 8 vCPU, 16GB | Hetzner CPX41       | $30-40         |

**Note:** Prices are approximate and may vary by region and provider.

## Additional Recommendations

### For Best Performance
1. Choose a VPS location close to your users
2. Use SSD storage (preferably NVMe)
3. Enable automatic security updates
4. Set up monitoring and alerts
5. Configure log rotation to prevent disk filling
6. Use a CDN if serving users globally
7. Consider dedicated servers for 50+ concurrent users

### For Cost Optimization
1. Start with minimum specs and scale up as needed
2. Use spot instances for testing (AWS, GCP)
3. Monitor actual usage and adjust resources
4. Consider yearly billing for discounts
5. Use providers with flexible scaling options
