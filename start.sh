#!/bin/bash
# Update self-hosted Multica: back up, sync fork + upstream, replay local ops
# commits (this script, backup.sh, .gitignore) on top of upstream main, then
# pull images and restart. Named volumes (your data) are never removed.
set -euo pipefail

cd "$(dirname "$0")"
COMPOSE="docker compose -f docker-compose.selfhost.yml"
BRANCH=multica-backup-setup

if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]; then
  echo "Error: must run on branch $BRANCH" >&2
  exit 1
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: uncommitted changes. Commit or stash them first." >&2
  exit 1
fi

echo "0. Ensuring database is running to perform a pre-update backup..."
$COMPOSE up -d --wait postgres
./backup.sh
echo ""

echo "1. Fetching the latest multica blueprint from GitHub..."
git fetch origin main
git fetch fork
# Fast-forward the fork's main to upstream main (non-force).
git push fork origin/main:main
# Rebase (not merge) so local-only ops commits always stay on top of upstream.
if ! git rebase origin/main; then
  echo "Error: rebase conflict. Resolve it, or run 'git rebase --abort'. Nothing was pushed or restarted." >&2
  exit 1
fi
git push --force-with-lease fork "$BRANCH"

echo "2. Downloading the newest Multica Docker images..."
$COMPOSE pull

echo "3. Starting Multica..."
$COMPOSE up -d --wait

echo "Done! Multica is running with the latest updates."
