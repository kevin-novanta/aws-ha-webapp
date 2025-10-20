

import importlib
import json
import types


def _load_app():
    """Import the app instance from src.app.main as `app` or `application`."""
    mod = importlib.import_module("src.app.main")
    app = getattr(mod, "app", None) or getattr(mod, "application", None)
    assert app is not None, "Expected `app` or `application` in src.app.main"
    return app


def _is_flask_app(app) -> bool:
    return hasattr(app, "test_client") and app.__class__.__module__.startswith("flask")


def _is_fastapi_app(app) -> bool:
    cls_module = app.__class__.__module__
    return cls_module.startswith("fastapi") or cls_module.startswith("starlette")


def test_health_endpoint_returns_200_json():
    app = _load_app()

    if _is_flask_app(app):
        # Flask test client path
        with app.test_client() as client:
            resp = client.get("/health")
            assert resp.status_code == 200
            # Content-Type may include charset; just check the prefix
            assert str(resp.content_type).startswith("application/json")
            # Flask provides get_json(); fall back to json.loads if needed
            data = None
            try:
                data = resp.get_json(silent=True)
            except Exception:
                try:
                    data = json.loads(resp.data.decode("utf-8")) if resp.data else None
                except Exception:
                    data = None
            assert isinstance(data, (dict, list)), "Expected JSON body"

    elif _is_fastapi_app(app):
        # FastAPI/Starlette test client path
        from starlette.testclient import TestClient

        with TestClient(app) as client:
            resp = client.get("/health")
            assert resp.status_code == 200
            assert resp.headers.get("content-type", "").startswith("application/json")
            data = resp.json()
            assert isinstance(data, (dict, list)), "Expected JSON body"

    else:
        raise AssertionError(
            "Unknown app type: expected Flask (has .test_client) or FastAPI/Starlette."
        )