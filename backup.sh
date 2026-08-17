#!/bin/bash
# Backup script for Multica database and uploads

cd /Users/sahilp/Projects/Docker_Operated_Apps/multica || exit

# Create a backup directory with current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/Users/sahilp/Projects/Docker_Operated_Apps/multica/backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "Backing up PostgreSQL Database..."
# Using docker compose exec to run pg_dump inside the running postgres container
# This is completely safe and non-disruptive, allowing backups while the app is live.
docker compose -f docker-compose.selfhost.yml exec -T postgres pg_dump -U multica multica > "$BACKUP_DIR/database.sql"

echo "Backing up Uploads..."
# Using a temporary alpine container to mount the uploads volume and compress it
docker run --rm -v multica_backend_uploads:/uploads -v "$BACKUP_DIR":/backup alpine tar czf /backup/uploads.tar.gz -C /uploads .

echo "Cleaning up old backups (keeping only the last 20)..."
ls -1dt /Users/sahilp/Projects/Docker_Operated_Apps/multica/backups/* 2>/dev/null | tail -n +21 | xargs rm -rf 2>/dev/null

echo "Backup completed successfully!"
echo "Files saved to: $BACKUP_DIR"
