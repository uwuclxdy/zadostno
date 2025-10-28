# Zadostno

PHP + PostgreSQL application running in Docker.

## Quick Start

```bash
./deploy.sh          # Deploy/update application
./zadostno-status.sh # Check status
```

## Management Commands

- `zs` - Check status
- `zl` - View logs
- `zl -f` - Follow logs
- `zr` - Restart
- `zu` - Update and deploy
- `zsh` - Enter app container
- `zdb` - PostgreSQL shell
- `zcd` - Go to app directory

## Access URLs

- Application: http://localhost:8727
- Health Check: http://localhost:8727/health
- Database: localhost:5433

## Database Credentials

See `.env` file for credentials.

## File Structure

```
/home/uwuclxdy/zadostno/
├── .env                     # Environment variables
├── docker-compose.yml       # Container configuration
├── Dockerfile              # PHP container
├── index.php               # Application entry point
├── database/               # Database scripts
├── deploy.sh               # Deployment script
└── zadostno-*.sh           # Management scripts
```
