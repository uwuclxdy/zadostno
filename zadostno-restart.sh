#!/bin/bash
echo "🔄 Restarting Zadostno..."
cd /home/uwuclxdy/zadostno

docker-compose restart

echo "⏳ Waiting for restart..."
sleep 10

echo "✅ Restart complete. Check status:"
./zadostno-status.sh
