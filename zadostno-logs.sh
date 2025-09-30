#!/bin/bash
cd /home/uwuclxdy/zadostno

case "$1" in
    "-f"|"--follow")
        echo "Following logs (Ctrl+C to exit)..."
        docker-compose logs -f
        ;;
    "-a"|"--app")
        echo "App logs:"
        docker-compose logs zadostno-app
        ;;
    "-d"|"--db")
        echo "DB logs:"
        docker-compose logs zadostno-postgres
        ;;
    *)
        echo "Recent logs:"
        docker-compose logs --tail=50
        echo ""
        echo "Options: -f (follow), -a (app only), -d (database only)"
        ;;
esac
