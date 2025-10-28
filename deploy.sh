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
