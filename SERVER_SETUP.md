# Zadostno Server Setup Documentation

Complete guide to set up and run the Zadostno PHP + PostgreSQL application on a fresh server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Server Setup](#initial-server-setup)
- [Install Docker](#install-docker)
- [Run Setup Script](#run-setup-script)
- [Access Application](#access-application)
- [Management Commands](#management-commands)
- [Configuration](#configuration)
- [Updating Application](#updating-application)
- [Cloudflare Setup](#cloudflare-setup)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Prerequisites

- Ubuntu/Debian server (20.04+ or Debian 11+)
- SSH access with sudo privileges
- At least 2GB RAM and 20GB disk space
- Internet connection
- Optional: Domain name for Cloudflare proxy

---

## Initial Server Setup

### 1. Connect to Your Server

```bash
ssh username@your-server-ip
```

Replace `username` with your actual username (e.g., `uwuclxdy`) and `your-server-ip` with your server's IP address.

### 2. Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Install Essential Tools

```bash
sudo apt install -y curl wget git ufw jq
```

### 4. Configure Firewall (Optional but Recommended)

```bash
# Allow SSH
sudo ufw allow ssh

# Allow application port (8727)
sudo ufw allow 8727

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status
```

---

## Install Docker

### 1. Install Docker

```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Verify Docker is installed
docker --version
```

### 2. Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### 3. Enable Docker on Boot

```bash
sudo systemctl enable docker
```

### 4. **IMPORTANT: Logout and Login Again**

```bash
# Logout to apply docker group changes
exit

# Login again
ssh username@your-server-ip
```

---

## Run Setup Script

### 1. Create Project Directory

```bash
# Create empty directory for the project
mkdir -p ~/zadostno
cd ~/zadostno
```

### 2. Download Setup Script

**Option A: Download directly from GitHub**

```bash
cd ~/zadostno
wget https://raw.githubusercontent.com/uwuclxdy/zadostno/main/setup.sh
chmod +x setup.sh
```

**Option B: Create manually**

```bash
cd ~/zadostno
nano setup.sh
# Paste the setup script content
# Save with Ctrl+X, Y, Enter

chmod +x setup.sh
```

### 3. Run Setup Script

```bash
./setup.sh
```

### 4. Setup Process

The setup script will:

1. **Clone Repository**: Downloads all application files from GitHub
2. **Generate Credentials**: Creates secure database password
3. **Create .env File**: Sets up environment configuration
4. **Open Editor**: Allows you to customize configuration
5. **Build Containers**: Builds Docker images
6. **Start Application**: Launches all services
7. **Health Check**: Verifies everything is working

### 5. Configure Environment (During Setup)

When the editor opens (nano), you can:

- **Review the generated password** (already secure)
- **Change ports** if 8727 or 5433 are in use:
  ```env
  POSTGRES_PORT=5434  # Change if needed
  APP_PORT=8728       # Change if needed
  ```
- **Add custom variables** for your application:
  ```env
  # Your custom variables
  API_KEY=your_api_key
  SECRET_KEY=your_secret
  ```

**Save and close:** Press `Ctrl+X`, then `Y`, then `Enter`

### 6. Save Important Information

The script will display:
```
🔐 Generated Database Credentials:
   Database: zadostno_db
   Username: zadostno_user
   Password: [GENERATED_PASSWORD]

🌐 Access URLs:
   Application: http://localhost:8727
   Health Check: http://localhost:8727/health
   Database: localhost:5433
```

**⚠️ Save the database password! It's also in the `.env` file.**

### 7. Activate Bash Aliases

```bash
# Reload bash configuration
source ~/.bashrc

# Test an alias
zs
```

---

## Access Application

### Local Access (from server)

```bash
# Test health endpoint
curl http://localhost:8727/health

# View full response with jq
curl -s http://localhost:8727/health | jq .
```

### Remote Access

**Option 1: Direct IP Access**
```
http://YOUR-SERVER-IP:8727
```

**Option 2: SSH Tunnel (Secure)**
```bash
# From your local machine
ssh -L 8727:localhost:8727 username@your-server-ip

# Then access in browser
http://localhost:8727
```

**Option 3: Cloudflare Tunnel (Recommended)**

See [Cloudflare Setup](#cloudflare-setup) section below.

---

## Management Commands

After setup completes, you can use these convenient aliases:

### Quick Commands

```bash
zs          # Check application status
zl          # View logs (last 50 lines)
zl -f       # Follow logs in real-time
zl -a       # View app logs only
zl -d       # View database logs only
zr          # Restart application
zu          # Update from GitHub and deploy
zsh         # Enter PHP container shell
zdb         # Access PostgreSQL database
zcd         # Go to project directory
```

### Full Script Commands

```bash
./zadostno-status.sh    # Detailed status check
./zadostno-logs.sh      # View logs
./zadostno-restart.sh   # Restart containers
./deploy.sh             # Deploy/update application
./monitor.sh            # Run health monitoring (if available)
```

### Docker Commands

```bash
# View containers
docker-compose ps

# View all logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Stop containers
docker-compose down

# Start containers
docker-compose up -d

# Rebuild and start
docker-compose up -d --build

# Remove everything including volumes
docker-compose down -v
```

---

## Configuration

### Environment Variables

All configuration is in `.env` file:

```bash
nano ~/zadostno/.env
```

```env
# Database Configuration
POSTGRES_DB=zadostno_db
POSTGRES_USER=zadostno_user
POSTGRES_PASSWORD=your_generated_password

# Application Settings
APP_ENV=production
APP_DEBUG=false

# Ports
POSTGRES_PORT=5433
APP_PORT=8727

# Your custom variables
API_KEY=your_api_key_here
SECRET_KEY=your_secret_here
```

**⚠️ The `.env` file is NOT in git** - it's in `.gitignore` for security.

**After changing `.env`, restart containers:**
```bash
zr
# or
docker-compose down && docker-compose up -d
```

### Change Ports

To change application or database ports:

1. Edit `.env` file:
   ```bash
   nano ~/zadostno/.env
   ```

2. Change port numbers:
   ```env
   POSTGRES_PORT=5434  # New PostgreSQL port
   APP_PORT=8728       # New application port
   ```

3. Update firewall:
   ```bash
   sudo ufw allow 8728
   ```

4. Restart:
   ```bash
   zr
   ```

### Database Connection

**From Host Machine:**
```bash
psql -h localhost -p 5433 -U zadostno_user -d zadostno_db
```

**Using Alias:**
```bash
zdb
```

**In PHP Application:**
```php
$host = getenv('DB_HOST');     // zadostno-postgres
$port = getenv('DB_PORT');     // 5432 (internal)
$dbname = getenv('DB_NAME');   // zadostno_db
$user = getenv('DB_USER');     // zadostno_user
$password = getenv('DB_PASSWORD');

$pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password);
```

---

## Updating Application

### Regular Updates from GitHub

The repository is regularly updated. To get the latest changes:

```bash
# Quick update command
zu

# Or manually
zcd
git pull origin main
./deploy.sh
```

The `zu` command will:
1. Navigate to project directory
2. Pull latest changes from GitHub
3. Rebuild containers if needed
4. Restart application
5. Run health checks

### What Gets Updated

When you run `zu`:
- ✅ Application code (PHP files)
- ✅ Docker configuration
- ✅ Database schema (if init.sql changed)
- ✅ Scripts and tools
- ❌ `.env` file (your local configuration is preserved)

### After Updates

The deployment script will:
- Stop current containers
- Pull latest code
- Rebuild Docker images
- Start new containers
- Perform health checks

### Manual Code Changes

If you make local changes:

```bash
# Save your changes
zcd
git add .
git commit -m "Your changes"

# Update from GitHub (may cause conflicts)
git pull origin main

# Deploy
./deploy.sh
```

---

## Cloudflare Setup

### Method 1: Cloudflare Tunnel (Recommended)

**Benefits:**
- No need to open ports
- Automatic SSL
- Built-in DDoS protection
- Works behind NAT/firewall

**Setup:**

1. Install cloudflared:
   ```bash
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. Login to Cloudflare:
   ```bash
   cloudflared tunnel login
   ```

3. Create tunnel:
   ```bash
   cloudflared tunnel create zadostno
   ```

4. Configure tunnel:
   ```bash
   mkdir -p ~/.cloudflared
   nano ~/.cloudflared/config.yml
   ```
   
   ```yaml
   tunnel: YOUR-TUNNEL-ID
   credentials-file: /home/uwuclxdy/.cloudflared/YOUR-TUNNEL-ID.json
   
   ingress:
     - hostname: zadostno.yourdomain.com
       service: http://localhost:8727
     - service: http_status:404
   ```

5. Run tunnel:
   ```bash
   cloudflared tunnel run zadostno
   ```

6. Create DNS record in Cloudflare dashboard:
   - Type: CNAME
   - Name: zadostno (or subdomain)
   - Target: YOUR-TUNNEL-ID.cfargotunnel.com
   - Proxy: ON (orange cloud)

7. Make tunnel run on startup:
   ```bash
   sudo cloudflared service install
   sudo systemctl enable cloudflared
   sudo systemctl start cloudflared
   ```

### Method 2: Direct Proxy (Alternative)

1. In Cloudflare DNS, create A record:
   - Type: A
   - Name: zadostno (or @)
   - Content: YOUR-SERVER-IP
   - Proxy: ON (orange cloud)

2. Ensure firewall allows port:
   ```bash
   sudo ufw allow 8727
   ```

3. Set SSL/TLS mode to "Full" or "Flexible" in Cloudflare dashboard

4. Access via: `https://zadostno.yourdomain.com`

---

## Troubleshooting

### Application Not Responding

```bash
# Check container status
zs

# View logs
zl

# Check if containers are running
docker-compose ps

# Restart containers
zr

# Full restart with rebuild
zcd
docker-compose down
docker-compose up -d --build
```

### Database Connection Issues

```bash
# Check database is ready
docker-compose exec zadostno-postgres pg_isready -U zadostno_user -d zadostno_db

# View database logs
zl -d

# Restart database
docker-compose restart zadostno-postgres

# Access database shell to test
zdb
```

### Permission Denied Errors

```bash
# Fix directory permissions
sudo chown -R $USER:$USER ~/zadostno
chmod -R 755 ~/zadostno
chmod 600 ~/zadostno/.env

# Rebuild containers
zcd
docker-compose down
docker-compose up -d --build
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :8727

# Kill the process (if safe to do so)
sudo kill -9 PID_NUMBER

# Or change port in .env
nano ~/zadostno/.env
# Change APP_PORT=8728
zr
```

### Git Pull Conflicts

```bash
# If you have local changes and git pull fails
zcd

# Stash your changes
git stash

# Pull updates
git pull origin main

# Apply your changes back
git stash pop

# If conflicts, resolve them manually
nano conflicted-file.php

# Then deploy
./deploy.sh
```

### Container Build Fails

```bash
# Clean Docker cache
docker system prune -af

# Remove old images
docker-compose down
docker rmi zadostno-zadostno-app

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

### Health Check Failing

```bash
# Check if Apache is running
docker-compose exec zadostno-app service apache2 status

# Check Apache error logs
docker-compose exec zadostno-app tail -f /var/log/apache2/error.log

# Check PHP errors
docker-compose exec zadostno-app tail -f /var/log/apache2/php_errors.log

# Test health endpoint manually
curl -v http://localhost:8727/health

# Enter container to debug
zsh
# Inside container:
ls -la /var/www/html/
cat /var/www/html/index.php
```

### .env File Missing After Update

The `.env` file is never committed to git (it's in `.gitignore`). If you need to recreate it:

```bash
zcd

# Recreate .env with new password
cat > .env << EOF
POSTGRES_DB=zadostno_db
POSTGRES_USER=zadostno_user
POSTGRES_PASSWORD=$(openssl rand -base64 24)
APP_ENV=production
APP_DEBUG=false
POSTGRES_PORT=5433
APP_PORT=8727
EOF

chmod 600 .env

# Restart containers
zr
```

### Setup Script Fails

```bash
# If setup.sh fails, try step by step:

# 1. Clone repository manually
cd ~/zadostno
git clone https://github.com/uwuclxdy/zadostno.git .

# 2. Create .env manually
nano .env
# Add configuration as shown above

# 3. Build containers manually
docker-compose build
docker-compose up -d

# 4. Check status
docker-compose ps
docker-compose logs
```

---

## Maintenance

### View Logs

```bash
# All logs
zl

# Follow logs in real-time
zl -f

# Application logs only
zl -a

# Database logs only
zl -d

# Last 100 lines
docker-compose logs --tail 100

# Specific container
docker-compose logs zadostno-app --tail 50
```

### Regular Updates

```bash
# Update application code from GitHub
zu

# This will:
# 1. Pull latest changes
# 2. Rebuild containers
# 3. Restart services
# 4. Run health checks
```

### Backup Database

```bash
# Create backup
zcd
docker-compose exec zadostno-postgres pg_dump -U zadostno_user zadostno_db > backup_$(date +%Y%m%d).sql

# Verify backup
ls -lh backup_*.sql

# Restore backup
docker-compose exec -T zadostno-postgres psql -U zadostno_user -d zadostno_db < backup_20241028.sql
```

### Backup .env File

```bash
# Backup .env (contains secrets!)
cp ~/zadostno/.env ~/zadostno/.env.backup

# Store securely off-server
scp username@server-ip:~/zadostno/.env ~/local-backups/zadostno-env-backup
```

### Monitor Resources

```bash
# Container resource usage
docker stats

# Disk usage
df -h ~/zadostno

# Memory usage
free -h

# Check logs size
du -sh ~/zadostno/
```

### Clean Up Docker

```bash
# Remove unused Docker resources
docker system prune -f

# Remove old images
docker image prune -a

# Remove unused volumes (CAUTION: may remove database data)
docker volume prune
```

### Regular Maintenance Schedule

**Daily:**
- Check status: `zs`
- Review logs if errors: `zl`

**Weekly:**
- Update application: `zu`
- Check disk space: `df -h`
- Review error logs: `zl | grep -i error`

**Monthly:**
- Backup database
- Backup `.env` file
- Update system: `sudo apt update && sudo apt upgrade`
- Clean Docker: `docker system prune -f`

---

## File Structure

```
/home/uwuclxdy/zadostno/
├── .env                      # Environment config (NOT IN GIT)
├── .gitignore                # Git ignore rules
├── .dockerignore             # Docker ignore rules
├── .htaccess                 # Apache URL rewriting
├── docker-compose.yml        # Container orchestration
├── Dockerfile                # PHP container definition
├── php.ini                   # PHP configuration (if present)
├── index.php                 # Main application file
├── README.md                 # Project documentation
├── SERVER_SETUP.md           # This file
├── setup.sh                  # Setup script
├── deploy.sh                 # Deployment script
├── zadostno-status.sh        # Status check script
├── zadostno-logs.sh          # Log viewing script
├── zadostno-restart.sh       # Restart script
├── database/
│   └── init.sql              # Database initialization
├── .git/                     # Git repository
│   └── hooks/
│       └── post-merge        # Auto-deploy on git pull
└── [other application files]
```

### Files NOT in Git

These files are local only (in `.gitignore`):
- `.env` - Your environment configuration and secrets
- `*.log` - Log files
- `backup_*.sql` - Database backups

---

## Quick Reference Card

### Essential Commands

| Command | Description |
|---------|-------------|
| `zs` | Check status |
| `zl` | View logs |
| `zl -f` | Follow logs |
| `zr` | Restart app |
| `zu` | **Update from GitHub** |
| `zsh` | Enter PHP container |
| `zdb` | PostgreSQL shell |
| `zcd` | Go to app directory |

### URLs

| Service | URL |
|---------|-----|
| Application | `http://localhost:8727` |
| Health Check | `http://localhost:8727/health` |
| Database | `localhost:5433` |

### Important Files

| File | Purpose | In Git? |
|------|---------|---------|
| `.env` | Configuration & secrets | ❌ No |
| `docker-compose.yml` | Container setup | ✅ Yes |
| `index.php` | Application code | ✅ Yes |
| `database/init.sql` | Database schema | ✅ Yes |
| `setup.sh` | Setup script | ✅ Yes |

### Container Commands

| Command | Description |
|---------|-------------|
| `docker-compose ps` | List containers |
| `docker-compose logs` | View all logs |
| `docker-compose up -d` | Start containers |
| `docker-compose down` | Stop containers |
| `docker-compose restart` | Restart all |

---

## Workflow Examples

### Daily Development Workflow

```bash
# 1. Update code from GitHub
zu

# 2. Check if everything is working
zs

# 3. View logs if needed
zl

# 4. Make changes to code
nano ~/zadostno/index.php

# 5. Restart to apply changes
zr

# 6. Test changes
curl http://localhost:8727/health
```

### Deploying New Features

```bash
# 1. On your development machine, push to GitHub
git add .
git commit -m "Add new feature"
git push origin main

# 2. On server, pull and deploy
zu

# 3. Verify deployment
zs
curl http://localhost:8727/health
```

### Troubleshooting Workflow

```bash
# 1. Check status
zs

# 2. If issues, check logs
zl -f

# 3. Try restart
zr

# 4. If still broken, rebuild
zcd
docker-compose down
docker-compose up -d --build

# 5. Check logs again
zl
```

---

## Security Best Practices

1. **Keep `.env` file secure**
   - Never commit to git (already in `.gitignore`)
   - Backup securely off-server
   - Use strong passwords

2. **Regular updates**
   - Run `zu` regularly to get security updates
   - Update system: `sudo apt update && sudo apt upgrade`

3. **Firewall configuration**
   - Only open necessary ports
   - Use Cloudflare tunnel to avoid exposing ports

4. **Database access**
   - PostgreSQL is not exposed publicly
   - Access only through internal network or SSH tunnel

5. **Container security**
   - Containers run with minimal privileges
   - No sensitive data in images

6. **Monitor logs**
   - Check logs regularly: `zl`
   - Look for suspicious activity

7. **Backup strategy**
   - Regular database backups
   - Store backups off-server
   - Backup `.env` file securely

---

## Getting Help

### Check These First

1. **Application status**: `zs`
2. **Recent logs**: `zl`
3. **Health endpoint**: `curl http://localhost:8727/health`
4. **Container status**: `docker-compose ps`

### Common Issues

- **Port conflicts**: Change ports in `.env`
- **Permission errors**: Run permission fix commands above
- **Database connection**: Check `.env` credentials
- **Git conflicts**: Stash changes, pull, reapply

### Useful Commands for Debugging

```bash
# Enter container
zsh

# Check files inside container
ls -la /var/www/html/

# Check Apache status
service apache2 status

# View real-time logs
zl -f

# Test database connection
zdb
\l  # List databases
\dt  # List tables
```

---

## Next Steps

After successful setup:

1. ✅ Verify application is running: `zs`
2. ✅ Access application: `http://localhost:8727`
3. ✅ Set up Cloudflare tunnel (optional)
4. ✅ Customize your application code
5. ✅ Modify `database/init.sql` for your schema
6. ✅ Set up automatic updates workflow
7. ✅ Configure regular backups
8. ✅ Add monitoring (optional)

---

**Setup Information**

- **Setup Date**: _________________
- **Server IP**: _________________
- **Application Port**: 8727
- **Database Port**: 5433
- **GitHub Repository**: https://github.com/uwuclxdy/zadostno
- **Cloudflare Domain**: _________________
- **Database Password**: (in `.env` file)