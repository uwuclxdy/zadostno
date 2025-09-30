#!/bin/bash
echo "🔍 Zadostno Status"
echo "=================="
echo ""

cd /home/uwuclxdy/zadostno

echo "📦 Containers:"
docker-compose ps
echo ""

echo "🏥 Health Check:"
if curl -s http://localhost:8727/health 2>/dev/null; then
    echo "✅ Application responding on port 8727"
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

echo "🌐 Access URLs:"
echo "   Local: http://localhost:8727"
echo "   Server: http://YOUR-SERVER-IP:8727"
