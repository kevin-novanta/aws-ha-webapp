from fastapi import FastAPI
import os, socket

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def root():
    return {
        "app": "ha-webapp",
        "host": socket.gethostname(),
        "env": os.getenv("APP_ENV", "dev")
    }