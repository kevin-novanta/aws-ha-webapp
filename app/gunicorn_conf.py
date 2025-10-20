

"""
Gunicorn configuration for aws-ha-webapp

Defaults are conservative for small instances (e.g., t3.micro: 2 vCPU, 1 GiB RAM) and
are overridable via environment variables. Works for WSGI or ASGI apps.

Env overrides (optional):
  PORT                 -> bind address (default: 8080)
  GUNICORN_WORKERS     -> number of workers (default: min(3, 2*CPU+1))
  GUNICORN_THREADS     -> threads per worker (default: 1)
  GUNICORN_TIMEOUT     -> worker timeout seconds (default: 30)
  GUNICORN_GRACEFUL    -> graceful timeout seconds (default: 30)
  GUNICORN_KEEPALIVE   -> keepalive seconds (default: 75)
  GUNICORN_LOGLEVEL    -> debug|info|warning|error|critical (default: info)
  GUNICORN_MAX_REQ     -> max-requests before recycle (default: 1000)
  GUNICORN_MAX_JITTER  -> jitter added to max-requests (default: 100)
  GUNICORN_UVICORN     -> if "true", use uvicorn worker class (ASGI); else sync
"""

import os
import multiprocessing

# ---- Bind/port ----
_port = int(os.getenv("PORT", "8080"))
bind = f"0.0.0.0:{_port}"

# ---- Workers/threads ----
# Rule of thumb: workers ≈ 2*CPU + 1, but cap for tiny instances to avoid memory pressure.
_cpu = max(multiprocessing.cpu_count(), 1)
_default_workers = min(3, 2 * _cpu + 1)
workers = int(os.getenv("GUNICORN_WORKERS", str(_default_workers)))

threads = int(os.getenv("GUNICORN_THREADS", "1"))

# ---- Timeouts ----
timeout = int(os.getenv("GUNICORN_TIMEOUT", "30"))            # hard kill
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL", "30"))   # graceful shutdown window
keepalive = int(os.getenv("GUNICORN_KEEPALIVE", "75"))

# ---- Logging ----
loglevel = os.getenv("GUNICORN_LOGLEVEL", "info")
accesslog = "-"   # stdout
errorlog = "-"    # stderr

# ---- Worker class ----
# Use uvicorn worker if running an ASGI app (FastAPI/Starlette). Otherwise sync.
if os.getenv("GUNICORN_UVICORN", "false").lower() in ("1", "true", "yes"):  # ASGI
    worker_class = "uvicorn.workers.UvicornWorker"
else:
    worker_class = "sync"

# ---- Request recycling to mitigate leaks ----
max_requests = int(os.getenv("GUNICORN_MAX_REQ", "1000"))
max_requests_jitter = int(os.getenv("GUNICORN_MAX_JITTER", "100"))

# ---- Preload for faster forks (optional) ----
# If your app opens DB connections at import time, ensure they are lazily created per-worker.
preload_app = False

# ---- Misc ----
# Forwarded-For/Proto headers from ALB are trusted when behind AWS ALB.
forwarded_allow_ips = "*"
proxy_allow_ips = "*"

# Notes:
# - Health checks should return quickly; keep timeouts modest to allow rolling deploys.
# - For CPU-bound workloads, prefer more workers instead of threads.
# - For I/O-bound workloads, you may increase threads slightly (2-4) if memory allows.