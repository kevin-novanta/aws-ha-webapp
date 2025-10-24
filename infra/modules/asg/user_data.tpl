# --------------------------
# Install Docker & AWS CLI & SSM Agent (AL2023-friendly)
# --------------------------
PKG="dnf"
if ! command -v dnf >/dev/null 2>&1; then
  PKG="yum"
fi

# Update package index quietly
sudo $PKG -y update || true

# Install docker, awscli, ssm agent
sudo $PKG -y install docker awscli amazon-ssm-agent || true

# Enable and start services
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

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
/usr/bin/docker run -d --name app \
  -p "${APP_PORT}:${APP_PORT}" --restart unless-stopped \
  -e PORT="${APP_PORT}" \
  "${ECR_REPO_URI}:${IMAGE_TAG}" \
  uvicorn src.app.main:app --host 0.0.0.0 --port "${APP_PORT}"

echo "[INFO] Application container started successfully."