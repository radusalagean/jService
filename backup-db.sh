#!/bin/bash

set -e

cd "$(dirname "$0")"

BACKUP_FILE="jservice-db-$(date +%Y-%m-%d_%H-%M-%S).dump"

echo "Backing up jservice database..."
docker exec jservice-db sh -c "PGPASSWORD=\$(cat \$POSTGRES_PASSWORD_FILE) pg_dump -U \$POSTGRES_USER -h \$POSTGRES_HOST -d \$POSTGRES_DB -F c -f \"/db-dump/$BACKUP_FILE\""

echo "Backup complete: $BACKUP_FILE"
