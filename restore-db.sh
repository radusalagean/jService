#!/bin/bash

set -e

if [ $# -ne 1 ] || [[ ! $1 == *.dump ]]; then
    echo "Usage: $0 <backup-file> (.dump file type)\n\t ensure the backup file is in the mounted directory for backups (e.g. `./backups` for local env, prod env may have a different mount)"
    exit 1
fi

read -p "Warning! This script will remove existing jservice database. Continue? y/N " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

cd "$(dirname "$0")"

BACKUP_FILE="$1"

echo "Stopping jservice..."
docker compose stop jservice

echo "Restoring database from $BACKUP_FILE ..."
docker exec jservice-db sh -c "PGPASSWORD=\$(cat \$POSTGRES_PASSWORD_FILE) pg_restore -U \$POSTGRES_USER -h \$POSTGRES_HOST -d \$POSTGRES_DB --clean --if-exists -F c \"/backups/$BACKUP_FILE\""

echo "Restore complete. Don't forget to start the services again manually."
