#!/bin/bash
# Zadostno Setup Script
# Run this from your home directory: ~/
# It will automatically create ~/zadostno and set everything up

set -e  # Exit on any error

echo "🚀 Zadostno Setup Script"
echo "========================"
echo ""

# Configuration
GITHUB_REPO="https://github.com/uwuclxdy/zadostno.git"
POSTGRES_EXTERNAL_PORT=5433
APP_PORT=8727
PROJECT_DIR="$HOME/zadostno"

echo "📍 Current directory: $(pwd)"
echo "📁 Project will be installed to: $PROJECT_DIR"
echo "📦 GitHub repository: $GITHUB_REPO"
echo "🐘 PostgreSQL port: $POSTGRES_EXTERNAL_PORT"
echo "🌐 Application port: $APP_PORT"
echo ""

# Check if project directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  Warning: Directory $PROJECT_DIR already exists!"
    echo ""
    ls -la "$PROJECT_DIR"
    echo ""
    read -p "Do you want to remove it and start fresh? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing directory..."
        # Stop any running containers first
        cd "$PROJECT_DIR"
        docker-compose down 2>/dev/null || true
        cd "$HOME"
        rm -rf "$PROJECT_DIR"
        echo "✅ Directory removed"
    else
        echo "❌ Setup cancelled. Please remove or backup $PROJECT_DIR manually."
        exit 1
    fi
fi

# Create project directory
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "✅ Directory created"
echo ""

# Clone repository
echo "📥 Cloning repository from GitHub..."
echo "Repository: $GITHUB_REPO"
echo ""

if git clone "$GITHUB_REPO" .; then
    echo "✅ Repository cloned successfully"
else
    echo "❌ Failed to clone repository"
    echo ""
    echo "Please check:"
    echo "  - Internet connection"
    echo "  - Repository URL is correct"
    echo "  - You have access to the repository"
    exit 1
fi

echo ""

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
    echo "These files are required for Docker setup."
    echo "Please ensure they exist in your GitHub repository."
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Repository structure verified"
echo ""

# Generate secure password (alphanumeric only)
echo "🔐 Generating secure database password..."
DB_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 32 | head -n 1)

# Create .env file
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
echo "It's also stored in: $PROJECT_DIR/.env"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Open editor for .env modifications
echo "📝 You can now customize the configuration..."
echo ""
echo "The .env file will open in your editor where you can:"
echo "  - Review the generated password"
echo "  - Change ports if needed (APP_PORT, POSTGRES_PORT)"
echo "  - Add custom environment variables"
echo ""
read -p "Press Enter to open the editor..."

# Detect available editor (prefer nano, fallback to vi)
if command -v nano &> /dev/null; then
    EDITOR="nano"
elif command -v vim &> /dev/null; then
    EDITOR="vim"
else
    EDITOR="vi"
fi

echo "Opening .env with $EDITOR..."
echo ""
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
    echo "Then logout and login again, and run this setup script again."
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

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "⚠️  Warning: Your user is not in the docker group"
    echo ""
    echo "You may need to run:"
    echo "  sudo usermod -aG docker \$USER"
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

# Clean up old volumes if user wants
echo ""
read -p "Do you want to remove old database data (if exists)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing old volumes..."
    docker volume rm zadostno-postgres-data 2>/dev/null || true
    docker volume rm zadostno-logs 2>/dev/null || true
    echo "✅ Old volumes removed"
fi

# Build and start containers
echo ""
echo "🔨 Building Docker containers..."
echo "This may take a few minutes on first run..."
echo ""

if docker-compose build; then
    echo ""
    echo "✅ Docker images built successfully"
else
    echo ""
    echo "❌ Failed to build Docker images"
    echo ""
    echo "Check the errors above and try again."
    exit 1
fi

echo ""
echo "🚀 Starting containers..."

if docker-compose up -d; then
    echo "✅ Containers started successfully"
else
    echo "❌ Failed to start containers"
    echo ""
    echo "Check logs with: cd $PROJECT_DIR && docker-compose logs"
    exit 1
fi

# Wait for containers to be ready
echo ""
echo "⏳ Waiting for containers to initialize..."
sleep 5

# Show container status
echo ""
echo "📦 Container Status:"
docker-compose ps

# Wait for application to be healthy
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
        echo "  cd $PROJECT_DIR"
        echo "  docker-compose logs zadostno-app"
        break
    fi

    echo "⏳ Attempt $HEALTH_CHECK_ATTEMPTS/$MAX_ATTEMPTS..."
    sleep 3
done

# Set up bash aliases
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

# Create a success indicator file
touch .setup_complete

# Final success message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Application Information:"
echo "   Installation: $PROJECT_DIR"
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
echo "   Password: (stored in $PROJECT_DIR/.env)"
echo ""
echo "🛠️  Quick Commands:"
echo "   Activate aliases first:"
echo "     source ~/.bashrc"
echo ""
echo "   Then use:"
echo "     zs    - Check status"
echo "     zl    - View logs"
echo "     zl -f - Follow logs"
echo "     zr    - Restart"
echo "     zu    - Update from GitHub"
echo "     zsh   - Enter PHP container"
echo "     zdb   - PostgreSQL shell"
echo "     zcd   - Go to app directory"
echo ""
echo "📚 Documentation:"
echo "   cd $PROJECT_DIR"
echo "   cat README.md"
echo "   cat SERVER_SETUP.md"
echo ""
echo "🔄 To activate bash aliases now:"
echo "   source ~/.bashrc"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test application health
echo "🧪 Testing application..."
if curl -s http://localhost:${APP_PORT}/health 2>/dev/null | jq . 2>/dev/null; then
    echo ""
    echo "✅ Application is responding correctly!"
else
    echo ""
    echo "⚠️  Application may still be starting up"
    echo ""
    echo "Check status with:"
    echo "  cd $PROJECT_DIR"
    echo "  docker-compose logs zadostno-app"
fi

echo ""
echo "🎊 Zadostno is ready to use!"
echo ""
echo "Next steps:"
echo "1. Activate aliases: source ~/.bashrc"
echo "2. Check status: zs"
echo "3. View application: curl http://localhost:${APP_PORT}"
echo ""
