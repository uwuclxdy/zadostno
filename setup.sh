#!/bin/bash
# Zadostno Complete Setup Script
# Run this from /home/uwuclxdy/zadostno directory

set -e  # Exit on any error

echo "🚀 Zadostno Complete Setup"
echo "=========================="
echo ""

# Configuration variables - CHANGE THESE IF NEEDED
POSTGRES_EXTERNAL_PORT=5433
APP_PORT=8727
USERNAME="uwuclxdy"
PROJECT_DIR="/home/$USERNAME/zadostno"

# Verify we're in the right directory
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$PROJECT_DIR" ]; then
    echo "⚠️  Warning: Not in expected directory"
    echo "Expected: $PROJECT_DIR"
    echo "Current: $CURRENT_DIR"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📁 Working directory: $(pwd)"
echo "🐘 PostgreSQL external port: $POSTGRES_EXTERNAL_PORT"
echo "🌐 Application port: $APP_PORT"
echo ""

# Generate secure passwords
echo "🔐 Generating secure credentials..."
DB_PASSWORD=$(openssl rand -base64 24)

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
echo "✅ .env created (password: $DB_PASSWORD)"

# Create Dockerfile
echo "📝 Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure Apache
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html\n\
    <Directory /var/www/html>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
        DirectoryIndex index.php index.html\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Create entrypoint script to fix permissions
RUN echo '#!/bin/bash\n\
chown -R www-data:www-data /var/www/html\n\
chmod -R 755 /var/www/html\n\
exec apache2-foreground' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /var/www/html
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
EOF

echo "✅ Dockerfile created"

# Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
services:
  zadostno-app:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: zadostno-app
    ports:
      - "${APP_PORT}:80"
    environment:
      - APACHE_DOCUMENT_ROOT=/var/www/html
      - DB_HOST=zadostno-postgres
      - DB_PORT=5432
      - DB_NAME=${POSTGRES_DB}
      - DB_USER=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
    depends_on:
      zadostno-postgres:
        condition: service_healthy
    restart: unless-stopped
    volumes:
      - ./:/var/www/html
      - zadostno-logs:/var/log/apache2
    networks:
      - zadostno-network
    user: root

  zadostno-postgres:
    image: postgres:15-alpine
    container_name: zadostno-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - zadostno-postgres-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - zadostno-network

volumes:
  zadostno-postgres-data:
    driver: local
  zadostno-logs:
    driver: local

networks:
  zadostno-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# Create .dockerignore
echo "📝 Creating .dockerignore..."
cat > .dockerignore << 'EOF'
.git
.gitignore
README.md
docker-compose.yml
Dockerfile
.dockerignore
.env
.env.example
*.log
zadostno-*.sh
deploy.sh
monitor.sh
setup.sh
EOF

echo "✅ .dockerignore created"

# Create PHP configuration
echo "📝 Creating php.ini..."
cat > php.ini << 'EOF'
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_time = 300
memory_limit = 256M
date.timezone = UTC

display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/apache2/php_errors.log

session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

expose_php = Off
EOF

echo "✅ php.ini created"

# Create .htaccess
echo "📝 Creating .htaccess..."
cat > .htaccess << 'EOF'
RewriteEngine On

# Health check
RewriteRule ^health$ index.php [L]

<Files ~ "^\.">
    Order allow,deny
    Deny from all
</Files>

<Files ~ "\.env$">
    Order allow,deny
    Deny from all
</Files>

<Files ~ "\.sql$">
    Order allow,deny
    Deny from all
</Files>
EOF

echo "✅ .htaccess created"

# Create database directory and init script
echo "📝 Creating database initialization..."
mkdir -p database
cat > database/init.sql << 'EOF'
-- Zadostno Database Initialization
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add more tables as needed for your application
EOF

echo "✅ database/init.sql created"

# Create index.php
echo "📝 Creating index.php..."
cat > index.php << 'EOF'
<?php
header('Content-Type: text/html; charset=utf-8');

function getDatabaseConnection() {
    $host = getenv('DB_HOST') ?: 'zadostno-postgres';
    $port = getenv('DB_PORT') ?: '5432';
    $dbname = getenv('DB_NAME') ?: 'zadostno_db';
    $user = getenv('DB_USER') ?: 'zadostno_user';
    $password = getenv('DB_PASSWORD');
    
    try {
        $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo;
    } catch (PDOException $e) {
        return null;
    }
}

if ($_SERVER['REQUEST_URI'] === '/health') {
    header('Content-Type: application/json');
    $db = getDatabaseConnection();
    $status = $db ? 'healthy' : 'database_error';
    echo json_encode([
        'status' => $status,
        'timestamp' => date('c'),
        'service' => 'zadostno',
        'php_version' => PHP_VERSION
    ]);
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zadostno</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        .status { padding: 15px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border-left: 4px solid #28a745; }
        .error { background: #f8d7da; color: #721c24; border-left: 4px solid #dc3545; }
        .info { background: #d1ecf1; color: #0c5460; border-left: 4px solid #17a2b8; }
        h1 { color: #333; }
        h2 { color: #555; margin-top: 30px; }
        ul { line-height: 1.8; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Zadostno is Running!</h1>
        
        <div class="status info">
            <strong>Service Status:</strong> ✅ Web server is operational<br>
            <strong>PHP Version:</strong> <?= PHP_VERSION ?><br>
            <strong>Timestamp:</strong> <?= date('Y-m-d H:i:s T') ?>
        </div>

        <?php
        $db = getDatabaseConnection();
        if ($db) {
            echo '<div class="status success"><strong>Database:</strong> ✅ Connected to PostgreSQL</div>';
            
            try {
                $stmt = $db->query("SELECT version()");
                $version = $stmt->fetchColumn();
                echo '<div class="status info"><strong>PostgreSQL Version:</strong> ' . htmlspecialchars($version) . '</div>';
            } catch (Exception $e) {
                echo '<div class="status error"><strong>Database Query:</strong> ❌ ' . htmlspecialchars($e->getMessage()) . '</div>';
            }
        } else {
            echo '<div class="status error"><strong>Database:</strong> ❌ Connection failed - check your credentials</div>';
        }
        ?>

        <h2>📍 Available Endpoints:</h2>
        <ul>
            <li><a href="/">/</a> - This status page</li>
            <li><a href="/health">/health</a> - JSON health check endpoint</li>
        </ul>

        <h2>🔧 Server Information:</h2>
        <ul>
            <li><strong>Server Software:</strong> <?= $_SERVER['SERVER_SOFTWARE'] ?></li>
            <li><strong>Port:</strong> <?= $_SERVER['SERVER_PORT'] ?></li>
            <li><strong>Document Root:</strong> <?= $_SERVER['DOCUMENT_ROOT'] ?></li>
            <li><strong>Request Method:</strong> <?= $_SERVER['REQUEST_METHOD'] ?></li>
        </ul>

        <h2>💡 Next Steps:</h2>
        <ul>
            <li>Replace this index.php with your application code</li>
            <li>Modify database/init.sql to create your database schema</li>
            <li>Use the management scripts (zs, zl, zr, zu) for easy maintenance</li>
        </ul>
    </div>
</body>
</html>
EOF

echo "✅ index.php created"

# Create deployment script
echo "📝 Creating deploy.sh..."
cat > deploy.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploying Zadostno..."

cd "$(dirname "$0")"

# Pull latest changes if this is a git repo
if [ -d ".git" ]; then
    echo "📥 Pulling latest changes from git..."
    git pull origin main || git pull origin master
fi

# Stop containers
echo "🛑 Stopping containers..."
docker-compose down

# Rebuild and start
echo "🔨 Building and starting containers..."
docker-compose up -d --build

# Wait for startup
echo "⏳ Waiting for containers to start..."
sleep 15

# Health check
echo "🏥 Performing health check..."
for i in {1..12}; do
    if curl -f http://localhost:${APP_PORT:-8727}/health >/dev/null 2>&1; then
        echo "✅ Zadostno is running!"
        docker-compose ps
        exit 0
    fi
    echo "⏳ Waiting... attempt $i/12"
    sleep 5
done

echo "⚠️  Health check timeout - checking logs..."
docker-compose logs --tail 20 zadostno-app
EOF

chmod +x deploy.sh
echo "✅ deploy.sh created"

# Create status script
echo "📝 Creating zadostno-status.sh..."
cat > zadostno-status.sh << 'EOF'
#!/bin/bash
echo "🔍 Zadostno Status"
echo "=================="
echo ""

cd "$(dirname "$0")"

echo "📦 Containers:"
docker-compose ps
echo ""

APP_PORT=$(grep APP_PORT .env | cut -d '=' -f2)
APP_PORT=${APP_PORT:-8727}

echo "🏥 Health Check:"
if curl -s http://localhost:$APP_PORT/health 2>/dev/null | jq . 2>/dev/null; then
    echo "✅ Application responding on port $APP_PORT"
else
    echo "❌ Application not responding"
fi
echo ""

echo "💾 Database Status:"
if docker-compose exec -T zadostno-postgres pg_isready -U zadostno_user -d zadostno_db >/dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL not ready"
fi
echo ""

echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""

POSTGRES_PORT=$(grep POSTGRES_PORT .env | cut -d '=' -f2)
POSTGRES_PORT=${POSTGRES_PORT:-5433}

echo "🌐 Access URLs:"
echo "   Application: http://localhost:$APP_PORT"
echo "   Database: localhost:$POSTGRES_PORT"
echo ""

echo "📁 Working Directory: $(pwd)"
EOF

chmod +x zadostno-status.sh
echo "✅ zadostno-status.sh created"

# Create logs script
echo "📝 Creating zadostno-logs.sh..."
cat > zadostno-logs.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

case "$1" in
    "-f"|"--follow")
        echo "📝 Following logs (Ctrl+C to exit)..."
        docker-compose logs -f
        ;;
    "-a"|"--app")
        echo "📝 Application logs:"
        docker-compose logs zadostno-app --tail 100
        ;;
    "-d"|"--db")
        echo "📝 Database logs:"
        docker-compose logs zadostno-postgres --tail 100
        ;;
    *)
        echo "📝 Recent logs (last 50 lines):"
        docker-compose logs --tail=50
        echo ""
        echo "Options:"
        echo "  -f, --follow    Follow logs in real-time"
        echo "  -a, --app       Show app logs only"
        echo "  -d, --db        Show database logs only"
        ;;
esac
EOF

chmod +x zadostno-logs.sh
echo "✅ zadostno-logs.sh created"

# Create restart script
echo "📝 Creating zadostno-restart.sh..."
cat > zadostno-restart.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting Zadostno..."
cd "$(dirname "$0")"

docker-compose restart

echo "⏳ Waiting for restart..."
sleep 10

echo "✅ Restart complete"
./zadostno-status.sh
EOF

chmod +x zadostno-restart.sh
echo "✅ zadostno-restart.sh created"

# Create monitor script
echo "📝 Creating monitor.sh..."
cat > monitor.sh << 'EOF'
#!/bin/bash
LOG_FILE="$(dirname "$0")/monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

cd "$(dirname "$0")"

APP_PORT=$(grep APP_PORT .env | cut -d '=' -f2)
APP_PORT=${APP_PORT:-8727}

# Check containers
if ! docker-compose ps | grep -q "Up"; then
    log "WARNING: Some containers are down"
fi

# Check health
if ! curl -f http://localhost:$APP_PORT/health >/dev/null 2>&1; then
    log "ERROR: Application health check failed - restarting"
    docker-compose restart zadostno-app
    sleep 15
    if curl -f http://localhost:$APP_PORT/health >/dev/null 2>&1; then
        log "SUCCESS: Application restarted"
    else
        log "CRITICAL: Restart failed"
    fi
fi

# Check disk
DISK_USAGE=$(df $(pwd) | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    log "WARNING: Disk usage at ${DISK_USAGE}%"
fi
EOF

chmod +x monitor.sh
echo "✅ monitor.sh created"

# Create git hooks
echo "📝 Creating git hooks..."
mkdir -p .git/hooks
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/../.."
./deploy.sh
EOF

chmod +x .git/hooks/post-merge
echo "✅ git hooks created"

# Update .bashrc with aliases if not already there
echo "📝 Checking bash aliases..."
if ! grep -q "# Zadostno Management Aliases" $HOME/.bashrc; then
    cat >> $HOME/.bashrc << 'EOF'

# Zadostno Management Aliases
alias zs='cd /home/uwuclxdy/zadostno && ./zadostno-status.sh'
alias zl='cd /home/uwuclxdy/zadostno && ./zadostno-logs.sh'
alias zr='cd /home/uwuclxdy/zadostno && ./zadostno-restart.sh'
alias zu='cd /home/uwuclxdy/zadostno && ./deploy.sh'
alias zsh='cd /home/uwuclxdy/zadostno && docker-compose exec zadostno-app bash'
alias zdb='cd /home/uwuclxdy/zadostno && docker-compose exec zadostno-postgres psql -U zadostno_user -d zadostno_db'
alias zcd='cd /home/uwuclxdy/zadostno'
EOF
    echo "✅ Bash aliases added"
else
    echo "✅ Bash aliases already exist"
fi

# Create README
echo "📝 Creating README.md..."
cat > README.md << EOF
# Zadostno

PHP + PostgreSQL application running in Docker.

## Quick Start

\`\`\`bash
./deploy.sh          # Deploy/update application
./zadostno-status.sh # Check status
\`\`\`

## Management Commands

- \`zs\` - Check status
- \`zl\` - View logs
- \`zl -f\` - Follow logs
- \`zr\` - Restart
- \`zu\` - Update and deploy
- \`zsh\` - Enter app container
- \`zdb\` - PostgreSQL shell
- \`zcd\` - Go to app directory

## Access URLs

- Application: http://localhost:$APP_PORT
- Health Check: http://localhost:$APP_PORT/health
- Database: localhost:$POSTGRES_EXTERNAL_PORT

## Database Credentials

See \`.env\` file for credentials.

## File Structure

\`\`\`
/home/uwuclxdy/zadostno/
├── .env                     # Environment variables
├── docker-compose.yml       # Container configuration
├── Dockerfile              # PHP container
├── index.php               # Application entry point
├── database/               # Database scripts
├── deploy.sh               # Deployment script
└── zadostno-*.sh           # Management scripts
\`\`\`
EOF

echo "✅ README.md created"

# Fix permissions
echo "🔧 Setting proper permissions..."
chmod -R 755 .
chmod 600 .env
find . -type f -name "*.sh" -exec chmod +x {} \;

echo ""
echo "=========================="
echo "✅ Setup Complete!"
echo "=========================="
echo ""
echo "🔐 Database Credentials:"
echo "   Database: zadostno_db"
echo "   Username: zadostno_user"
echo "   Password: $DB_PASSWORD"
echo ""
echo "🌐 Ports:"
echo "   Application: $APP_PORT"
echo "   PostgreSQL: $POSTGRES_EXTERNAL_PORT"
echo ""

# Start containers
echo "🚀 Starting containers..."
docker-compose up -d --build

echo ""
echo "⏳ Waiting for containers to start (this may take a minute)..."
sleep 20

# Final status check
echo ""
echo "🏥 Checking application health..."
for i in {1..10}; do
    if curl -f http://localhost:$APP_PORT/health >/dev/null 2>&1; then
        echo "✅ Application is healthy!"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "⚠️  Health check timeout - check logs with: zl"
    else
        echo "⏳ Attempt $i/10..."
        sleep 3
    fi
done

echo ""
echo "=========================="
echo "🎉 Zadostno is ready!"
echo "=========================="
echo ""
echo "Access your application:"
echo "  🌐 http://localhost:$APP_PORT"
echo ""
echo "Quick commands:"
echo "  zs    - Check status"
echo "  zl    - View logs"
echo "  zr    - Restart"
echo "  zu    - Update & deploy"
echo ""
echo "📁 All files created in: $(pwd)"
echo "💾 Database password saved in .env"
echo ""
echo "Run './zadostno-status.sh' for detailed status"
echo ""
