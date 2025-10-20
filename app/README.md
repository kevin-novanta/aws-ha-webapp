# aws-ha-webapp — Application

Minimal Dockerized backend that listens on **PORT=8080** and exposes a health check at `/health`.
Designed to run locally (Docker or Python) and on AWS behind an ALB → ASG.

## Quick Start

### 1) Run locally with Python (no Docker)

```bash
# from repo root
cd app

python -m venv .venv && source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt

# Set env (adjust DATABASE_URL if you have a local DB)
export PORT=8080
export DATABASE_URL="postgresql://user:pass@localhost:5432/appdb"

# Optional: wait for DB & apply migrations
./scripts/wait_for_db.sh
python ./scripts/migrate.py

# Run the app (development server)
python -m src.app.main
```
