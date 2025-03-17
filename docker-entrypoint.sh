#!/bin/bash
set -e

if [ -z "$POSTGRES_PASSWORD_FILE" ]; then
  echo "POSTGRES_PASSWORD_FILE is not defined. Exiting."
  exit 1
fi

POSTGRES_PASSWORD=$(cat $POSTGRES_PASSWORD_FILE)

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
>&2 echo "Postgres is up - executing command"

# Create database if it doesn't exist
bundle exec rails db:create

# Run migrations
bundle exec rails db:migrate

# Execute the main command
exec "$@" 