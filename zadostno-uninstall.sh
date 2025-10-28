#!/bin/bash
# Zadostno Uninstall Script
# Removes all Zadostno containers, volumes, and optionally the project directory

set -e

echo "🗑️  Zadostno Uninstall"
echo "====================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Check if we're in the zadostno directory
if [[ ! "$PROJECT_DIR" =~ zadostno$ ]]; then
    echo "⚠️  Warning: This doesn't appear to be the zadostno directory"
    echo "Current directory: $PROJECT_DIR"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Uninstall cancelled"
        exit 1
    fi
fi

# Navigate to project directory
cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "⚠️  docker-compose.yml not found"
    echo "This might not be a Zadostno installation"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Uninstall cancelled"
        exit 1
    fi
fi

echo "⚠️  WARNING: This will:"
echo "   1. Stop and remove all Zadostno containers"
echo "   2. Delete all database data (PostgreSQL volumes)"
echo "   3. Remove Docker images built for Zadostno"
echo "   4. Optionally delete the entire project directory"
echo ""
echo "💾 If you want to keep your data, backup first:"
echo "   docker-compose exec -T zadostno-postgres pg_dump -U zadostno_user zadostno_db > backup.sql"
echo ""

read -p "Are you sure you want to continue? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Uninstall cancelled"
    exit 0
fi

echo ""
echo "🛑 Stopping containers..."

# Stop and remove containers
if docker-compose ps -q 2>/dev/null | grep -q .; then
    docker-compose down
    echo "✅ Containers stopped and removed"
else
    echo "ℹ️  No running containers found"
fi

echo ""
echo "🗑️  Removing volumes..."

# Remove volumes with force
if docker volume ls -q | grep -q "zadostno"; then
    docker volume rm -f zadostno-postgres-data 2>/dev/null || echo "ℹ️  Volume zadostno-postgres-data already removed or doesn't exist"
    docker volume rm -f zadostno-logs 2>/dev/null || echo "ℹ️  Volume zadostno-logs already removed or doesn't exist"

    # Try to remove with compose volume names (with directory prefix)
    COMPOSE_PROJECT=$(basename "$PROJECT_DIR")
    docker volume rm -f "${COMPOSE_PROJECT}_zadostno-postgres-data" 2>/dev/null || true
    docker volume rm -f "${COMPOSE_PROJECT}_zadostno-logs" 2>/dev/null || true

    echo "✅ Volumes removed"
else
    echo "ℹ️  No Zadostno volumes found"
fi

echo ""
echo "🐳 Cleaning up Docker images..."

# Remove images built for this project
if docker images | grep -q "zadostno"; then
    docker images | grep zadostno | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
    echo "✅ Docker images removed"
else
    echo "ℹ️  No Zadostno images found"
fi

# Try to remove by compose project name
docker images | grep "^${COMPOSE_PROJECT}" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

echo ""
echo "🧹 Removing stopped containers and unused resources..."

# Clean up any remaining zadostno containers
docker ps -a | grep zadostno | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

echo "✅ Cleanup complete"

echo ""
echo "📁 Project Directory"
echo "==================="
echo ""
echo "The project directory still exists at: $PROJECT_DIR"
echo ""

read -p "Do you want to delete the entire project directory? (yes/no) " -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo ""
    echo "⚠️  FINAL WARNING!"
    echo "This will permanently delete:"
    echo "   - All source code (if not backed up in git)"
    echo "   - Configuration files (.env)"
    echo "   - All scripts and documentation"
    echo "   - Everything in: $PROJECT_DIR"
    echo ""
    read -p "Type 'DELETE' in all caps to confirm: " -r
    echo

    if [[ $REPLY == "DELETE" ]]; then
        echo "🗑️  Deleting project directory..."
        cd "$HOME"
        rm -rf "$PROJECT_DIR"
        echo "✅ Project directory deleted"

        echo ""
        echo "================================"
        echo "✅ Zadostno Completely Removed"
        echo "================================"
        echo ""
        echo "All Zadostno files, containers, and data have been removed"
        echo ""
    else
        echo "❌ Project directory deletion cancelled"
        echo "Directory preserved at: $PROJECT_DIR"
        show_partial_removal
    fi
else
    echo "✅ Project directory preserved at: $PROJECT_DIR"
    show_partial_removal
fi

function show_partial_removal() {
    echo ""
    echo "================================"
    echo "✅ Partial Uninstall Complete"
    echo "================================"
    echo ""
    echo "Removed:"
    echo "  ✅ Docker containers"
    echo "  ✅ Docker volumes (database data)"
    echo "  ✅ Docker images"
    echo ""
    echo "Preserved:"
    echo "  📁 Project directory: $PROJECT_DIR"
    echo "  📝 Source code and configuration"
    echo ""
    echo "To reinstall, run:"
    echo "  cd $PROJECT_DIR && docker-compose up -d --build"
    echo ""
    echo "To completely remove, delete the directory:"
    echo "  rm -rf $PROJECT_DIR"
    echo ""
}

# Check if we're still in the project directory
if [ -d "$PROJECT_DIR" ]; then
    echo "💡 Tips:"
    echo "   - To reinstall: cd ~ && bash setup.sh"
    echo "   - Your .env file is preserved (contains database password)"
    echo "   - To remove .env: rm $PROJECT_DIR/.env"
fi

echo ""
