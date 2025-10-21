#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy/ecr_publish.sh [env]
# Example: ./deploy/ecr_publish.sh dev
ENV="${1:-dev}"

# ----- Discover version/tag -----
VERSION="$(cat VERSION 2>/dev/null || echo '0.1.0')"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'local')"
TAG="${VERSION}-main-${GIT_SHA}"

# ----- AWS / ECR values -----
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REPO_NAME="aws-ha-webapp-app"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_URI="${ECR_REGISTRY}/${ECR_REPO_NAME}"

echo "[INFO] ENV=${ENV}"
echo "[INFO] Using AWS region: ${AWS_REGION}"
echo "[INFO] Account: ${ACCOUNT_ID}"
echo "[INFO] Repo name: ${ECR_REPO_NAME}"

# Ensure the ECR repository exists (idempotent)
if ! aws ecr describe-repositories --region "${AWS_REGION}" \
  --repository-names "${ECR_REPO_NAME}" >/dev/null 2>&1; then
  echo "[INFO] Creating ECR repository: ${ECR_REPO_NAME}"
  aws ecr create-repository --region "${AWS_REGION}" \
    --repository-name "${ECR_REPO_NAME}" >/dev/null
fi

echo "[INFO] Logging into ECR: ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ----- Build from ./app context (so COPY requirements.txt, COPY src/ work) -----
LOCAL_TAG="${ECR_REPO_NAME}:${TAG}"
IMAGE="${ECR_URI}:${TAG}"

echo "[INFO] Building Docker image locally: ${LOCAL_TAG}"
docker build -t "${LOCAL_TAG}" ./app

# (Optional) run unit tests inside the image
# docker run --rm "${LOCAL_TAG}" pytest -q

echo "[INFO] Tagging ${LOCAL_TAG} -> ${IMAGE}"
docker tag "${LOCAL_TAG}" "${IMAGE}"

echo "[INFO] Pushing ${IMAGE}"
docker push "${IMAGE}"

# ----- Record tag for infra (Terraform ASG user_data pulls this tag) -----
echo "${TAG}" > deploy/image_tag
echo "[INFO] Wrote tag to deploy/image_tag: ${TAG}"

# Helpful summary
echo "[DONE] Image pushed:"
echo "  ECR:  ${ECR_URI}"
echo "  TAG:  ${TAG}"
echo "  FULL: ${IMAGE}"
