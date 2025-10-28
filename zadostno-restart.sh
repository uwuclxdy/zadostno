#!/bin/bash
echo "🔄 Restarting Zadostno..."
cd "$(dirname "$0")"

docker-compose restart

echo "⏳ Waiting for restart..."
sleep 10

echo "✅ Restart complete"
./zadostno-status.sh
