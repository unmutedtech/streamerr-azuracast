#!/usr/bin/env bash
set -eo pipefail

# Default environment variables
STREAMERR_RELEASE_BRANCH="${STREAMERR_RELEASE_BRANCH:-main}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

# Utility functions
dc() {
    docker compose -f $COMPOSE_FILE "$@"
}

check_requirements() {
    echo "Checking system requirements..."

    # Check Docker
    if [[ ! $(command -v docker) ]]; then
        echo "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check Docker Compose
    if [[ ! $(docker compose version) ]]; then
        echo "Docker Compose V2 is not installed. Please install Docker Compose first."
        exit 1
    fi

    # Check architecture
    CURRENT_ARCH=$(uname -m)
    if [[ ! "$CURRENT_ARCH" =~ ^(x86_64|aarch64)$ ]]; then
        echo "Unsupported architecture: ${CURRENT_ARCH}"
        echo "Streamerr supports x86_64 and aarch64 architectures only."
        exit 1
    fi

    echo "✓ All requirements met!"
}

setup_env() {
    if [[ ! -f .env ]]; then
        cp sample.env .env
    fi

    if [[ ! -f azuracast.env ]]; then
        cp azuracast.sample.env azuracast.env
    fi
}

install() {
    check_requirements
    setup_env

    echo "Installing Streamerr..."
    dc pull
    dc up -d
    echo "Installation complete! Your Streamerr instance is now running."
}

update() {
    check_requirements

    echo "Updating Streamerr..."
    dc pull
    dc down
    dc up -d
    echo "Update complete!"
}

restart() {
    dc down
    dc up -d
    echo "Services restarted!"
}

logs() {
    dc logs "$@"
}

backup() {
    local BACKUP_PATH=${1:-./backup}
    mkdir -p "$BACKUP_PATH"
    
    echo "Creating backup in $BACKUP_PATH..."
    dc exec web backup.sh "$BACKUP_PATH"
    echo "Backup complete!"
}

restore() {
    local BACKUP_FILE=$1
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    echo "Restoring from backup..."
    dc exec web restore.sh "$BACKUP_FILE"
    echo "Restore complete!"
}

case "$1" in
    install)
        install
        ;;
    update)
        update
        ;;
    restart)
        restart
        ;;
    logs)
        shift
        logs "$@"
        ;;
    backup)
        shift
        backup "$@"
        ;;
    restore)
        shift
        restore "$@"
        ;;
    *)
        echo "Usage: $0 {install|update|restart|logs|backup|restore}"
        exit 1
        ;;
esac
