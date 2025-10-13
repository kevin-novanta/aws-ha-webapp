

#!/bin/bash
set -xe

# Log all output to /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[INFO] Starting bootstrap sequence..."

# ---- Install dependencies ----
yum update -y
yum install -y docker aws-cli
systemctl enable docker
systemctl start docker

# ---- Authenticate to ECR ----
echo "[INFO] Logging into Amazon ECR..."
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_repo_uri%%/*}

# ---- Pull and run application container ----
echo "[INFO] Pulling application image: ${ecr_repo_uri}:${image_tag}"
docker pull ${ecr_repo_uri}:${image_tag}

echo "[INFO] Running container on port ${app_port}..."
docker run -d \
  --name aws-ha-webapp \
  -p ${app_port}:${app_port} \
  --restart always \
  ${ecr_repo_uri}:${image_tag}

echo "[INFO] Application container started successfully."