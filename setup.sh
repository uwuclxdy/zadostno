#!/bin/bash
# Zadostno Setup Script
# Run this from home directory on server

set -e  # Exit on error

echo "🚀 Zadostno setup"
echo "================="
echo ""

# Configuration
REPO_URL="https://github.com/uwuclxdy/zadostno.git"
PROJECT_DIR="$HOME/zadostno"
POSTGRES_EXTERNAL_PORT=5433
APP_PORT=8727

# Check if we're in home directory
if [ "$(pwd)" != "$HOME" ]; then
    echo "⚠️  This script must be run from your home directory"
    echo "Current directory: $(pwd)"
    echo "Home directory: $HOME"
    echo ""
    echo "Please run: cd ~ && bash setup.sh"
    exit 1
fi

echo "📁 Working from: $(pwd)"
echo "📦 Install directory: $PROJECT_DIR"
echo "🔗 Repository: $REPO_URL"
echo ""

# Check if directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  Directory $PROJECT_DIR already exists!"
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing directory..."
        rm -rf "$PROJECT_DIR"
    else
        echo "❌ Setup cancelled"
        exit 1
    fi
fi

# Clone repository
echo "📥 Cloning repository from GitHub..."
if ! git clone "$REPO_URL" "$PROJECT_DIR"; then
    echo "❌ Failed to clone repository"
    exit 1
fi

echo "✅ Repository cloned successfully"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR"

# Check if required files exist
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found in repository"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found in repository"
    exit 1
fi

# Generate alphanumeric password (letters and numbers only)
echo "🔐 Generating secure credentials..."
DB_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)

# Create .env file
echo "📝 Creating .env file..."
cat > .env << EOF
# Database Configuration
POSTGRES_DB=zadostno_db
POSTGRES_USER=zadostno_user
POSTGRES_PASSWORD=$DB_PASSWORD

# Application Settings
APP_ENV=production
APP_DEBUG=false

# Ports
POSTGRES_PORT=$POSTGRES_EXTERNAL_PORT
APP_PORT=$APP_PORT
EOF

chmod 600 .env

echo "✅ .env file created"
echo ""
echo "🔐 Generated Credentials:"
echo "   Database: zadostno_db"
echo "   Username: zadostno_user"
echo "   Password: $DB_PASSWORD"
echo ""
printf "Press Enter to open .env for editing..."
read -r

# Open editor (tries in order: nano, vim, vi)
if command -v nano &> /dev/null; then
    nano .env
elif command -v vim &> /dev/null; then
    vim .env
elif command -v vi &> /dev/null; then
    vi .env
else
    echo "⚠️  No editor found. Continuing with generated .env"
    echo "   You can edit it later: nano ~/zadostno/.env"
    read -p "Press Enter to continue..."
fi

echo ""
echo "✅ Configuration done"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    exit 1
fi

# Check if user can run docker without sudo
if ! docker ps >/dev/null 2>&1; then
    echo "⚠️  Cannot run Docker without sudo (run sudo usermod -aG docker \$USER)"
    exit 1
fi

# Build and start containers
echo "🐳 Building Docker containers..."
echo "   This may take a few minutes..."
echo ""

if ! docker-compose up -d --build; then
    echo ""
    echo "❌ Failed to start containers"
    echo ""
    echo "Check logs with: cd ~/zadostno && docker-compose logs"
    exit 1
fi

echo ""
echo "⏳ Waiting for containers to start..."
sleep 25

# Health check
echo ""
echo "🏥 Checking application health..."
HEALTH_URL="http://localhost:$APP_PORT/health"
MAX_ATTEMPTS=15
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -f -s "$HEALTH_URL" >/dev/null 2>&1; then
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "⚠️  Health check timeout after $MAX_ATTEMPTS attempts"
        echo ""
        echo "The application may still be starting. Check:"
        echo "  cd ~/zadostno && docker-compose ps     # Container status"
        echo "  cd ~/zadostno && docker-compose logs   # View logs"
        echo ""
    else
        echo "⏳ Waiting... ($ATTEMPT/$MAX_ATTEMPTS)"
        sleep 4
    fi
done

# Show final status
echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "🌐 Access URLs:"
echo "   Application: http://localhost:$APP_PORT"
echo "   Health Check: http://localhost:$APP_PORT/health"
echo ""
echo "💾 Database Connection:"
echo "   Host: localhost"
echo "   Postgres port: $POSTGRES_EXTERNAL_PORT"
echo "   Database: zadostno_db"
echo "   Username: zadostno_user"
echo "   Password: (stored in ~/zadostno/.env)"
echo ""
echo "📁 Project Location: $PROJECT_DIR"
echo ""
echo "📥 Update from GitHub:"
echo "   cd ~/zadostno && git pull"
echo "   docker-compose down && docker-compose up -d --build"
echo ""
echo "🔧 Scripts:"
echo "   ./zadostno-status.sh              # Check status"
echo "   ./zadostno-logs.sh                # View logs"
echo "   ./zadostno-restart.sh             # Restart app"
echo "   ./deploy.sh                       # Deploy updates"
echo ""

echo "🔄 Automatic Updates"
echo "   Enable auto-updates (pulls from GitHub every minute):"
echo ""

read -p "Would you like to enable automatic updates now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔄 Setting up automatic updates..."
    if [ -f "$PROJECT_DIR/zadostno-autoupdate.sh" ]; then
        bash "$PROJECT_DIR/zadostno-autoupdate.sh"
        echo ""
        echo "✅ Automatic updates enabled!"
        echo "   Check status: sudo systemctl status zadostno-update.timer"
    else
        echo "⚠️  zadostno-autoupdate.sh not found in $PROJECT_DIR"
        echo "   You can run it manually later once it's available"
    fi
fi
echo ""
