

"""
Database connector utility for aws-ha-webapp.

Purpose:
- Parse DATABASE_URL from environment (expected format: postgresql://user:pass@host:port/db)
- Provide a connection helper with basic retry and ping functionality.
- Designed to be swapped with real connection pools (e.g., psycopg2, asyncpg, SQLAlchemy) later.

Safe to import in app start-up (main.py).
"""

import os
import time
import logging
import psycopg2
from psycopg2 import OperationalError

logger = logging.getLogger(__name__)

# Default retry configuration
MAX_RETRIES = int(os.getenv("DB_MAX_RETRIES", "5"))
RETRY_DELAY = int(os.getenv("DB_RETRY_DELAY", "3"))  # seconds


def get_database_url() -> str:
    """Fetch DATABASE_URL from env and validate."""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        raise RuntimeError("DATABASE_URL not set in environment.")
    return db_url


def connect_db():
    """Attempt to connect to DB with retries and return a connection object."""
    db_url = get_database_url()

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            conn = psycopg2.connect(db_url)
            conn.autocommit = True
            logger.info("[db] Connected successfully on attempt %d", attempt)
            return conn
        except OperationalError as e:
            logger.warning(
                "[db] Connection attempt %d/%d failed: %s", attempt, MAX_RETRIES, e
            )
            if attempt == MAX_RETRIES:
                logger.error("[db] Could not connect to database after retries.")
                raise
            time.sleep(RETRY_DELAY)


def ping_db():
    """Run a lightweight SELECT 1 to verify DB availability."""
    try:
        conn = connect_db()
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            result = cur.fetchone()
            logger.info("[db] Ping successful: %s", result)
        conn.close()
        return True
    except Exception as e:
        logger.error("[db] Ping failed: %s", e)
        return False


if __name__ == "__main__":
    # Manual test (for debugging in dev containers or local runs)
    success = ping_db()
    print("DB ping:", "OK" if success else "FAILED")