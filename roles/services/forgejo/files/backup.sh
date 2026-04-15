#!/bin/bash
set -euo pipefail

STACK_DIR="/opt/stacks/forgejo"
BACKUP_DIR="${STACK_DIR}/backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Stopping Forgejo..."
docker compose -f "$STACK_DIR/docker-compose.yml" stop forgejo

echo "Dumping database..."
docker exec forgejo-postgres pg_dumpall -U forgejo > "$STACK_DIR/forgejo-db.sql"

echo "Creating backup archive..."
tar czf "$BACKUP_DIR/forgejo-backup-$TIMESTAMP.tar.gz" -C "$STACK_DIR" forgejo/ conf/ forgejo-db.sql

rm "$STACK_DIR/forgejo-db.sql"

echo "Starting Forgejo..."
docker compose -f "$STACK_DIR/docker-compose.yml" start forgejo

echo "Backup complete: $BACKUP_DIR/forgejo-backup-$TIMESTAMP.tar.gz"
