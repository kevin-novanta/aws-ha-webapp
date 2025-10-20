

#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# wait_for_db.sh — Block until the database is reachable
# ------------------------------------------------------------
# Usage:
#   ./app/scripts/wait_for_db.sh [timeout_seconds]
#
# Purpose:
#   Used by migrations or app startup to wait until the database
#   is accepting TCP connections. Prevents race conditions during
#   container initialization.
# ------------------------------------------------------------

TIMEOUT=${1:-60}
START=$(date +%s)

DB_URL=${DATABASE_URL:-}

if [[ -z "$DB_URL" ]]; then
  echo "[ERROR] DATABASE_URL is not set. Exiting." >&2
  exit 1
fi

# Parse host and port from DATABASE_URL (expects standard URI form)
DB_HOST=$(echo "$DB_URL" | sed -E 's|.*@([^:/]+):.*|\1|')
DB_PORT=$(echo "$DB_URL" | sed -E 's|.*:([0-9]+)/.*|\1|')

if [[ -z "$DB_HOST" || -z "$DB_PORT" ]]; then
  echo "[ERROR] Failed to parse host/port from DATABASE_URL." >&2
  echo "URL: $DB_URL" >&2
  exit 1
fi

echo "[INFO] Waiting for database at ${DB_HOST}:${DB_PORT} (timeout=${TIMEOUT}s)..."

until nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; do
  sleep 2
  ELAPSED=$(( $(date +%s) - START ))
  if (( ELAPSED >= TIMEOUT )); then
    echo "[ERROR] Timeout waiting for database (${TIMEOUT}s)." >&2
    exit 1
  fi
  echo "[INFO] Still waiting (${ELAPSED}s)..."
done

echo "[OK] Database reachable after $(( $(date +%s) - START ))s."