#!/bin/bash
echo "Status Check"

cd /home/uwuclxdy/zadostno

echo "Container list:"
docker-compose ps
echo ""

echo "Health Check:"
if curl -s http://localhost:8727/health 2>/dev/null; then
    echo "responding on port 8727"
else
    echo "not responding x/"
fi
echo ""

echo "DB Status:"
if docker-compose exec -T zadostno-postgres pg_isready -U zadostno_user -d zadostno_db >/dev/null 2>&1; then
    echo "PostgreSQL ready"
else
    echo "PostgreSQL not ready"
fi
echo ""

echo "Resources:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""
