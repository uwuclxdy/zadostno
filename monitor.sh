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
