# app/src/app/main.py (FastAPI example)
from fastapi import FastAPI
import os, socket

PORT = int(os.getenv("PORT", "8080"))
HOSTNAME = socket.gethostname()

app = FastAPI()

# NOTE: Keep this endpoint FAST and dependency-free (no DB, no network).
# ALB Target Group health checks call this path.
@app.get("/health")
def health():
    return {"status": "ok", "port": PORT, "host": HOSTNAME}

@app.get("/ready")
def ready():
    """Deeper readiness check (optional): tries a lightweight DB ping.
    Keep ALB health checks on /health; use /ready for dashboards or manual checks.
    """
    try:
        from .db import ping  # relative import within the app package
        ok = ping(timeout=1.0)
        return {"status": "ready" if ok else "degraded"}
    except Exception as e:
        return {"status": "degraded", "error": str(e)}

@app.get("/")
def root():
    return {"message": "hello from asg", "host": HOSTNAME}