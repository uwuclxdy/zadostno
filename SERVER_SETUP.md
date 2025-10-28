# Zadostno Server Setup Guide

Complete guide to set up Zadostno PHP + PostgreSQL application on a fresh Ubuntu/Debian server.

## Prerequisites

- Ubuntu 20.04+ or Debian 11+ server
- SSH access with sudo privileges
- At least 2GB RAM and 20GB disk space
- Domain name pointed to server IP (optional, for Cloudflare)

---

## Initial Server Setup

### 1. Connect to Your Server

```bash
ssh username@your-server-ip
```

### 2. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Install Essential Packages

```bash
sudo apt install -y curl wget git ufw nano
```

---

## Install Docker

### 1. Install Docker Engine

```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker username

# Verify installation
docker --version
```

### 2. Install Docker Compose

```bash
# Download latest Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### 3. Enable Docker on Boot

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

### 4. Logout and Login Again or Reboot

**Important:** Logout and login again for Docker group changes to take effect.

```bash
exit
# Then SSH back in
ssh username@your-server-ip
```

Verify Docker works without sudo:
```bash
docker ps
```

---

## Configure Firewall

### 1. Set Up UFW Firewall

```bash
# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (very important - don't lock yourself out!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow application port (8727)
sudo ufw allow 8727/tcp

# Allow PostgreSQL port (5433) - only if you need external access
sudo ufw allow 5433/tcp

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status verbose
```

**Note:** If using Cloudflare Tunnel, don't expose ports 8727 or 5433.

---

## Install Zadostno using the Setup Script

From your home directory:

```bash
cd ~
wget https://raw.githubusercontent.com/uwuclxdy/zadostno/main/setup.sh
chmod +x setup.sh
./setup.sh
```

The script will:
1. Clone the repository from GitHub
2. Generate database credentials
3. Create `.env` configuration file
4. Open editor for you to review/modify settings
5. Build Docker containers
6. Start the application
7. Perform health checks

### Review Configuration

When the editor opens (nano by default), review these settings:

```env
# Database Configuration
POSTGRES_DB=zadostno_db
POSTGRES_USER=zadostno_user
POSTGRES_PASSWORD=<generated-secure-password>

# Application Settings
APP_ENV=production
APP_DEBUG=false

# Ports
POSTGRES_PORT=5433
APP_PORT=8727
```

**Save and close** the editor (Ctrl+X, then Y, then Enter in nano).

The script will build and start containers. This takes 2-5 minutes on first run.

### 6. Verify Installation

```bash
# Check container status
cd ~/zadostno
docker-compose ps

# Test application
curl http://localhost:8727/health

# Check logs
docker-compose logs -f
```

You should see:
- ✅ Both containers running
- ✅ Health check returns JSON response
- ✅ No errors in logs

---

## Cloudflare Setup

### Option 1: Cloudflare Tunnel (Recommended)

Cloudflare Tunnel provides secure access without exposing ports.

#### 1. Install cloudflared

```bash
# Download and install
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Verify installation
cloudflared --version
```

#### 2. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser window to authenticate. Follow the prompts.

#### 3. Create Tunnel

```bash
# Create a tunnel named 'zadostno'
cloudflared tunnel create zadostno

# Note the Tunnel ID shown in output
```

#### 4. Configure Tunnel

Create tunnel configuration:

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

Add this configuration (replace `TUNNEL_ID` and `your-domain.com`):

```yaml
tunnel: TUNNEL_ID
credentials-file: /home/uwuclxdy/.cloudflared/TUNNEL_ID.json

ingress:
  - hostname: your-domain.com
    service: http://localhost:8727
  - hostname: www.your-domain.com
    service: http://localhost:8727
  - service: http_status:404
```

#### 5. Route DNS to Tunnel

```bash
cloudflared tunnel route dns zadostno your-domain.com
cloudflared tunnel route dns zadostno www.your-domain.com
```

#### 6. Run Tunnel as Service

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared
```

Visit `https://your-domain.com` - your application should now be accessible!

### Option 2: Direct Cloudflare Proxy

If you prefer traditional DNS setup:

#### 1. Add DNS Records in Cloudflare

In Cloudflare dashboard:
- Go to DNS settings
- Add A record: `@` → Your Server IP (☁️ Proxied)
- Add A record: `www` → Your Server IP (☁️ Proxied)

#### 2. Configure SSL/TLS

In Cloudflare dashboard:
- Go to SSL/TLS → Overview
- Set mode to "Flexible" or "Full"
- Enable "Always Use HTTPS"

#### 3. Ensure Port is Open

Your application on port 8727 must be accessible:

```bash
# Check if port is listening
sudo netstat -tulpn | grep 8727

# Ensure firewall allows it
sudo ufw allow 8727/tcp
```

---

## Helpful notes

### Checking Status

```bash
cd ~/zadostno
./zadostno-status.sh
```

### Restarting Application

```bash
cd ~/zadostno
./zadostno-restart.sh
```

### Updating

```bash
cd ~/zadostno
git pull origin main
docker-compose down
docker-compose up -d --build
```

### Accessing Database

```bash
cd ~/zadostno
docker-compose exec zadostno-postgres psql -U zadostno_user -d zadostno_db
```

### Accessing Application Container

```bash
cd ~/zadostno
docker-compose exec zadostno-app bash

# Example command
docker-compose exec zadostno-app php -m
```

### DB Backups

```bash
cd ~/zadostno

# Create backup
docker-compose exec -T zadostno-postgres pg_dump -U zadostno_user zadostno_db > backup_$(date +%Y%m%d).sql

# Restore backup
docker-compose exec -T zadostno-postgres psql -U zadostno_user zadostno_db < backup_20241028.sql
```

### Reset Everything

If you need to start fresh:

```bash
# Stop and remove containers
cd ~/zadostno
docker-compose down -v

# Remove project directory
cd ~
rm -rf zadostno

# Run setup script again
bash setup.sh
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PHP Documentation](https://www.php.net/docs.php)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
