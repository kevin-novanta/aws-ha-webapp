

#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Run the app container locally on port 8080
# - Builds image from app/Dockerfile
# - Injects env vars (PORT, DATABASE_URL, LOG_LEVEL)
# - Maps host 8080 -> container 8080
# -------------------------------------------------
# Usage:
#   ./app/scripts/run_local.sh                      # uses VERSION for tag
#   IMAGE_TAG=dev ./app/scripts/run_local.sh        # override tag
#   PORT=8080 DATABASE_URL=postgresql://u:p@h:5432/db ./app/scripts/run_local.sh
#
# Optional: if a .env file exists in repo root, it will be loaded.
#

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  echo "[INFO] Loading .env from repo root"
  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | xargs -I{} echo {})
fi

# Default variables
PORT="${PORT:-8080}"
LOG_LEVEL="${LOG_LEVEL:-info}"
DATABASE_URL="${DATABASE_URL:-}"

# Resolve image tag
if [[ -z "${IMAGE_TAG:-}" ]]; then
  if [[ -f VERSION ]]; then
    VERSION_STR=$(cat VERSION)
  else
    VERSION_STR="dev"
  fi
  SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
  IMAGE_TAG="${VERSION_STR}-local-${SHORT_SHA}"
fi

IMAGE_NAME="aws-ha-webapp"
LOCAL_TAG="${IMAGE_NAME}:${IMAGE_TAG}"

# Build image
echo "[INFO] Building image: ${LOCAL_TAG}"
docker build -t "$LOCAL_TAG" -f app/Dockerfile .

# Remove any existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${IMAGE_NAME}$"; then
  echo "[INFO] Removing existing container ${IMAGE_NAME}"
  docker rm -f "$IMAGE_NAME" >/dev/null 2>&1 || true
fi

# Run container
RUN_ARGS=(
  --name "$IMAGE_NAME"
  --rm
  -p "${PORT}:8080"
  -e "PORT=8080"
  -e "LOG_LEVEL=${LOG_LEVEL}"
)

if [[ -n "$DATABASE_URL" ]]; then
  RUN_ARGS+=( -e "DATABASE_URL=${DATABASE_URL}" )
fi

echo "[INFO] Starting container on http://localhost:${PORT}"
docker run -it "${RUN_ARGS[@]}" "$LOCAL_TAG"