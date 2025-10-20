

#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# Local helper: build & push image to Amazon ECR
# ---------------------------------------------
# Requirements:
#  - aws CLI configured (with permissions to ECR)
#  - Docker daemon running
#  - VERSION file at repo root (or pass IMAGE_TAG explicitly)
#
# Usage:
#   ./deploy/ecr_publish.sh                # derives IMAGE_TAG = VERSION-branch-sha
#   IMAGE_TAG=1.2.3 ./deploy/ecr_publish.sh
#   AWS_REGION=us-east-1 ECR_REPO_NAME=aws-ha-webapp-app ./deploy/ecr_publish.sh
#
# Outputs:
#   - Pushes image to ECR
#   - Writes the resolved tag to deploy/image_tag

# ---- Config (overrides via env) ----
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_NAME=${PROJECT_NAME:-aws-ha-webapp}
ECR_REPO_NAME=${ECR_REPO_NAME:-aws-ha-webapp-app}
PUSH_LATEST=${PUSH_LATEST:-false}

# ---- Resolve account and repository URI ----
echo "[INFO] Resolving AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

# ---- Determine image tag ----
if [[ -z "${IMAGE_TAG:-}" ]]; then
  if [[ -f VERSION ]]; then
    VERSION_STR=$(cat VERSION)
  else
    echo "[ERROR] VERSION file not found and IMAGE_TAG not provided." >&2
    exit 1
  fi
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")
  BRANCH_SAFE=${BRANCH//\//-}
  SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nosha")
  IMAGE_TAG="${VERSION_STR}-${BRANCH_SAFE}-${SHORT_SHA}"
fi

LOCAL_TAG="${ECR_REPO_NAME}:${IMAGE_TAG}"
REMOTE_TAG="${ECR_URI}:${IMAGE_TAG}"

# ---- Ensure repository exists (idempotent) ----
if ! aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" >/dev/null 2>&1; then
  echo "[INFO] Creating ECR repository: ${ECR_REPO_NAME}"
  aws ecr create-repository --repository-name "${ECR_REPO_NAME}" >/dev/null
fi

# ---- ECR login ----
echo "[INFO] Logging into ECR: ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ---- Build image ----
echo "[INFO] Building Docker image: ${LOCAL_TAG}"
docker build -t "${LOCAL_TAG}" -f app/Dockerfile .

# ---- Tag & push ----
echo "[INFO] Tagging ${LOCAL_TAG} -> ${REMOTE_TAG}"
docker tag "${LOCAL_TAG}" "${REMOTE_TAG}"

echo "[INFO] Pushing ${REMOTE_TAG}"
docker push "${REMOTE_TAG}"

if [[ "${PUSH_LATEST}" == "true" ]]; then
  echo "[INFO] Also tagging/pushing :latest"
  docker tag "${LOCAL_TAG}" "${ECR_URI}:latest"
  docker push "${ECR_URI}:latest"
fi

# ---- Write image tag artifact ----
mkdir -p deploy
echo "${IMAGE_TAG}" > deploy/image_tag
echo "[INFO] Wrote tag to deploy/image_tag"

# ---- Summary ----
echo "[OK] Image pushed: ${REMOTE_TAG}"