#!/bin/bash
cd "$(dirname "$0")"

case "$1" in
    "-f"|"--follow")
        echo "📝 Following logs (Ctrl+C to exit)..."
        docker-compose logs -f
        ;;
    "-a"|"--app")
        echo "📝 Application logs:"
        docker-compose logs zadostno-app --tail 100
        ;;
    "-d"|"--db")
        echo "📝 Database logs:"
        docker-compose logs zadostno-postgres --tail 100
        ;;
    *)
        echo "📝 Recent logs (last 50 lines):"
        docker-compose logs --tail=50
        echo ""
        echo "Options:"
        echo "  -f, --follow    Follow logs in real-time"
        echo "  -a, --app       Show app logs only"
        echo "  -d, --db        Show database logs only"
        ;;
esac
