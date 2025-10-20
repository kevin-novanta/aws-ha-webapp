#!/bin/bash
set -euxo pipefail

# Log to file and console
exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "[INFO] Starting bootstrap sequence..."

# --------------------------
# Capture Terraform variables
# --------------------------
APP_PORT=${app_port}
ECR_REPO_URI="${ecr_repo_uri}"
IMAGE_TAG="${image_tag}"

# --------------------------
# Discover region from IMDSv2
# --------------------------
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
REGION=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | awk -F '"' '/"region"/ {print $4}')

echo "[INFO] Detected region: $REGION"

# --------------------------
# Install Docker & AWS CLI
# --------------------------
if ! command -v docker >/dev/null 2>&1; then
  yum update -y || true
  amazon-linux-extras enable docker || true
  yum install -y docker aws-cli || true
  systemctl enable docker
  systemctl start docker
fi

# --------------------------
# Authenticate to ECR
# --------------------------
REGISTRY=$(echo "$ECR_REPO_URI" | awk -F/ '{print $1}')
echo "[INFO] Logging into Amazon ECR registry: $REGISTRY"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

# --------------------------
# Pull and run application container
# --------------------------
IMAGE_REF="$ECR_REPO_URI:$IMAGE_TAG"
echo "[INFO] Pulling application image: $IMAGE_REF"
/usr/bin/docker pull "$IMAGE_REF"

# Stop/remove any previous container named 'app'
/usr/bin/docker ps -aq --filter name=app | xargs -r /usr/bin/docker rm -f || true

echo "[INFO] Running container on port $APP_PORT..."
/usr/bin/docker run -d \
  --name app \
  -p "$APP_PORT:$APP_PORT" \
  --restart unless-stopped \
  -e PORT="$APP_PORT" \
  "$IMAGE_REF"

echo "[INFO] Application container started successfully."