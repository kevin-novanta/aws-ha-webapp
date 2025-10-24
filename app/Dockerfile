# app/Dockerfile
FROM python:3.12-slim

# System prep (optional but helpful for healthchecks & debugging)
RUN apt-get update -y && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install deps first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source exactly as your tree shows:
# repo/app/src/app/... -> container /app/src/app/...
COPY src ./src

# Make "src" importable as top-level (so 'src.app.main' and 'app.main' both work)
ENV PYTHONPATH=/app/src
ENV PORT=8080 APP_ENV=dev

EXPOSE 8080

# Optional container-level healthcheck (does NOT replace ALB health checks)
HEALTHCHECK --interval=20s --timeout=3s --retries=5 CMD curl -fsS http://127.0.0.1:${PORT}/health || exit 1

# Start the server. We rely on PORT env so ASG/user_data can override if needed.
# Using ENTRYPOINT+CMD means:
#   - 'docker run -e PORT=9000 image' will run on 9000
#   - ASG user_data only needs to "docker run -e PORT=$APP_PORT image"
ENTRYPOINT ["uvicorn", "src.app.main:app", "--host", "0.0.0.0", "--port"]
CMD ["8080"]