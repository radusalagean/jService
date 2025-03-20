#!/bin/bash

set -e

cleanup() {
    rm -f ./backups/.restore.dump
    echo "ℹ Reminder: Make sure to restart the stopped services through the ansible playbook. ⚠ Do not run 'docker compose up' from the server command line."
}

if [ $# -ne 1 ] || [[ ! $1 == *.dump ]]; then
    echo "Usage: $0 <backup-file> (.dump file type)"
    exit 1
fi

read -p "Warning! This script will remove existing jservice database. Continue? y/N " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

cd "$(dirname "$0")"

BACKUP_FILE="$1"

BACKUP_PATH=$(realpath "$BACKUP_FILE")

if [ ! -f "$BACKUP_PATH" ]; then
    echo "Backup file $BACKUP_PATH does not exist."
    exit 1
fi

echo "Stopping jservice..."
docker compose stop jservice

trap cleanup EXIT

echo "Restoring database from $BACKUP_PATH ..."
cp "$BACKUP_PATH" ./backups/.restore.dump
docker exec jservice-db sh -c "PGPASSWORD=\$(cat \$POSTGRES_PASSWORD_FILE) pg_restore -U \$POSTGRES_USER -h \$POSTGRES_HOST -d \$POSTGRES_DB --clean --if-exists -F c \"/backups/.restore.dump\""

echo "Restore complete."
