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
