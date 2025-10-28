#!/bin/bash
# Zadostno Setup Script
# Run this from your home directory: ~/setup.sh

set -e  # Exit on any error

echo "🚀 Zadostno Setup Script"
echo "========================"
echo ""

# Configuration
GITHUB_REPO="https://github.com/uwuclxdy/zadostno.git"
POSTGRES_EXTERNAL_PORT=5433
APP_PORT=8727
INSTALL_DIR="$HOME/zadostno"

echo "📍 Current directory: $(pwd)"
echo "📦 GitHub repository: $GITHUB_REPO"
echo "📁 Installation directory: $INSTALL_DIR"
echo "🐘 PostgreSQL port: $POSTGRES_EXTERNAL_PORT"
echo "🌐 Application port: $APP_PORT"
echo ""

# Check if we're already in the zadostno directory
if [ "$(pwd)" = "$INSTALL_DIR" ]; then
    echo "⚠️  You're already in the zadostno directory!"
    echo "This script should be run from your home directory."
    echo ""
    read -p "Continue anyway and set up in current directory? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please run this script from your home directory:"
        echo "  cd ~"
        echo "  ./setup.sh"
        exit 1
    fi
else
    # Create zadostno directory if it doesn't exist
    if [ -d "$INSTALL_DIR" ]; then
        echo "📁 Directory $INSTALL_DIR already exists"

        # Check if it's empty
        if [ "$(ls -A $INSTALL_DIR | grep -v '^\.git

# Check if required files exist
echo "🔍 Checking repository structure..."
MISSING_FILES=()

if [ ! -f "docker-compose.yml" ]; then
    MISSING_FILES+=("docker-compose.yml")
fi

if [ ! -f "Dockerfile" ]; then
    MISSING_FILES+=("Dockerfile")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "⚠️  Warning: Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "Please ensure these files are in your GitHub repository."
    echo "You can push them first or create them manually."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Generate secure password (alphanumeric only)
echo "🔐 Generating secure database password..."
DB_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 32 | head -n 1)

# Create .env file if it doesn't exist
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing .env file..."
        SKIP_ENV_EDIT=false
    else
        CREATE_ENV=true
    fi
else
    CREATE_ENV=true
fi

if [ "$CREATE_ENV" = true ]; then
    echo "📝 Creating .env file with default configuration..."
    cat > .env << EOF
# Zadostno Environment Configuration
# This file is NOT committed to git - it's in .gitignore

# Database Configuration
POSTGRES_DB=zadostno_db
POSTGRES_USER=zadostno_user
POSTGRES_PASSWORD=$DB_PASSWORD

# Application Settings
APP_ENV=production
APP_DEBUG=false

# Ports Configuration
POSTGRES_PORT=$POSTGRES_EXTERNAL_PORT
APP_PORT=$APP_PORT

# Add your custom environment variables below
# Example:
# API_KEY=your_api_key_here
# SECRET_KEY=your_secret_key_here
EOF

    chmod 600 .env
    echo "✅ .env file created"
fi

# Display the generated password
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Generated Database Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Database: zadostno_db"
echo "Username: zadostno_user"
echo "Password: $DB_PASSWORD"
echo ""
echo "⚠️  IMPORTANT: Save this password securely!"
echo "It's also stored in the .env file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Open editor for .env modifications
echo "📝 Opening .env file for editing..."
echo ""
echo "You can now:"
echo "  - Review the configuration"
echo "  - Change ports if needed"
echo "  - Add custom environment variables"
echo "  - Save and close when done"
echo ""
read -p "Press Enter to open the editor (nano)..."

# Detect available editor (prefer nano, fallback to vi)
if command -v nano &> /dev/null; then
    EDITOR="nano"
elif command -v vim &> /dev/null; then
    EDITOR="vim"
else
    EDITOR="vi"
fi

echo "Opening .env with $EDITOR..."
$EDITOR .env

# Reload configuration from .env in case user changed it
if [ -f ".env" ]; then
    source .env 2>/dev/null || true
fi

echo ""
echo "✅ Configuration saved"
echo ""

# Verify Docker is installed
echo "🐳 Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo ""
    echo "Please install Docker first:"
    echo "  curl -fsSL https://get.docker.com | sh"
    echo "  sudo usermod -aG docker \$USER"
    echo ""
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed!"
    echo ""
    echo "Please install Docker Compose first:"
    echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "  sudo chmod +x /usr/local/bin/docker-compose"
    echo ""
    exit 1
fi

echo "✅ Docker is installed"
echo ""

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "⚠️  Warning: Your user is not in the docker group"
    echo "You may need to run: sudo usermod -aG docker \$USER"
    echo "Then logout and login again"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose down 2>/dev/null || true

# Clean up old volumes if they exist (optional)
read -p "Do you want to remove old database data? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing old volumes..."
    docker volume rm zadostno-postgres-data 2>/dev/null || true
    docker volume rm zadostno-logs 2>/dev/null || true
fi

# Build and start containers
echo ""
echo "🔨 Building Docker containers..."
echo "This may take a few minutes on first run..."
echo ""

docker-compose build

echo ""
echo "🚀 Starting containers..."
docker-compose up -d

# Wait for containers to be ready
echo ""
echo "⏳ Waiting for containers to start..."
sleep 5

# Show container status
echo ""
echo "📦 Container Status:"
docker-compose ps

# Wait for application to be ready
echo ""
echo "🏥 Waiting for application to be healthy..."
HEALTH_CHECK_ATTEMPTS=0
MAX_ATTEMPTS=20

while [ $HEALTH_CHECK_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if curl -f http://localhost:${APP_PORT}/health >/dev/null 2>&1; then
        echo "✅ Application is healthy!"
        break
    fi

    HEALTH_CHECK_ATTEMPTS=$((HEALTH_CHECK_ATTEMPTS + 1))

    if [ $HEALTH_CHECK_ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "⚠️  Health check timeout after $MAX_ATTEMPTS attempts"
        echo ""
        echo "Application may still be starting up. Check with:"
        echo "  docker-compose logs zadostno-app"
        break
    fi

    echo "⏳ Attempt $HEALTH_CHECK_ATTEMPTS/$MAX_ATTEMPTS..."
    sleep 3
done

# Final setup steps
echo ""
echo "🔧 Setting up bash aliases..."

# Check if aliases already exist
if ! grep -q "# Zadostno Management Aliases" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Zadostno Management Aliases
alias zs='cd ~/zadostno && ./zadostno-status.sh'
alias zl='cd ~/zadostno && ./zadostno-logs.sh'
alias zr='cd ~/zadostno && ./zadostno-restart.sh'
alias zu='cd ~/zadostno && ./deploy.sh'
alias zsh='cd ~/zadostno && docker-compose exec zadostno-app bash'
alias zdb='cd ~/zadostno && docker-compose exec zadostno-postgres psql -U zadostno_user -d zadostno_db'
alias zcd='cd ~/zadostno'
EOF
    echo "✅ Bash aliases added to ~/.bashrc"
    echo "   Run 'source ~/.bashrc' or restart your shell to use them"
else
    echo "✅ Bash aliases already exist"
fi

# Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x *.sh 2>/dev/null || true

# Final success message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Application Information:"
echo "   Directory: $(pwd)"
echo "   GitHub: $GITHUB_REPO"
echo ""
echo "🌐 Access URLs:"
echo "   Application: http://localhost:${APP_PORT}"
echo "   Health Check: http://localhost:${APP_PORT}/health"
echo "   Database: localhost:${POSTGRES_PORT}"
echo ""
echo "🔐 Database Credentials:"
echo "   Database: zadostno_db"
echo "   Username: zadostno_user"
echo "   Password: (stored in .env file)"
echo ""
echo "🛠️  Quick Commands (after 'source ~/.bashrc'):"
echo "   zs    - Check status"
echo "   zl    - View logs"
echo "   zl -f - Follow logs"
echo "   zr    - Restart"
echo "   zu    - Update from GitHub"
echo "   zsh   - Enter PHP container"
echo "   zdb   - PostgreSQL shell"
echo "   zcd   - Go to app directory"
echo ""
echo "📚 Documentation:"
echo "   cat README.md"
echo "   cat SERVER_SETUP.md"
echo ""
echo "🔄 To use aliases now, run:"
echo "   source ~/.bashrc"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test health endpoint
echo "🧪 Testing application..."
if curl -s http://localhost:${APP_PORT}/health | jq . 2>/dev/null; then
    echo ""
    echo "✅ Application is responding correctly!"
else
    echo ""
    echo "⚠️  Application may still be starting up"
    echo "Check status with: docker-compose logs zadostno-app"
fi

echo ""
echo "🎊 Zadostno is ready to use!"
echo "" | wc -l)" -gt 0 ]; then
            echo "⚠️  Directory is not empty!"
            ls -la "$INSTALL_DIR"
            echo ""
            read -p "Do you want to remove it and start fresh? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🗑️  Removing existing directory..."
                rm -rf "$INSTALL_DIR"
                mkdir -p "$INSTALL_DIR"
            else
                echo "Continuing with existing directory..."
            fi
        fi
    else
        echo "📁 Creating directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    # Navigate to installation directory
    cd "$INSTALL_DIR"
    echo "📂 Switched to: $(pwd)"
    echo ""
fi
