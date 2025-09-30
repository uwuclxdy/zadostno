#!/bin/bash
echo "Restarting..."
cd /home/uwuclxdy/zadostno

docker-compose restart

sleep 10

echo "Restarted ig. Check status:"
./zadostno-status.sh
