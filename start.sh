#!/bin/bash
cd /Users/sahilp/Projects/Docker_Operated_Apps/multica || exit
echo "0. Ensuring database is running to perform a pre-update backup..."
docker compose -f docker-compose.selfhost.yml up -d postgres
sleep 3
./backup.sh
echo ""

echo "1. Fetching the latest multica blueprint from GitHub..."
# Rebase (not merge) so local-only ops commits on multica-backup-setup
# (this script, backup.sh, .gitignore) always stay on top of upstream main
# instead of producing a merge commit or diverging.
git fetch origin main
git rebase origin/main

echo "2. Downloading the newest Multica Docker images..."
docker compose -f docker-compose.selfhost.yml pull

echo "3. Starting Multica..."
# Using up -d will recreate containers if images changed, but will explicitly NEVER touch or delete your named volumes (your data).
docker compose -f docker-compose.selfhost.yml up -d

echo "Done! Multica is running with the latest updates."
