import logging
import os
from pathlib import Path

# Load .env from apps/Q2Rmapper/api/ regardless of working directory or which venv is active.
_ENV_FILE = Path(__file__).parent.parent.parent / ".env"
try:
    from dotenv import load_dotenv
    load_dotenv(_ENV_FILE)
except ImportError:
    # python-dotenv not available — fall back to manual parsing
    if _ENV_FILE.exists():
        for line in _ENV_FILE.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())

logging.basicConfig(level=logging.INFO)
_startup_log = logging.getLogger(__name__)
_startup_log.info("FHIR default server : %s", os.environ.get("FHIR_BASE_URL", "(not set — using HAPI public)"))
_sa = os.environ.get("GOOGLE_SERVICE_ACCOUNT_FILE", "")
_startup_log.info("Google service account: %s", _sa if _sa else "(not set — using API key / no auth)")

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from src.server.routers import v1

LOGGER = logging.getLogger(__name__)

app = FastAPI(title="FHIR Questionnaire mapper")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    LOGGER.exception("Unhandled exception")
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


app.include_router(v1.router, prefix="/api/v1")

# Serve the Angular SPA when a pre-built static/ directory is present (Docker image).
# In local development the directory doesn't exist and the API runs as-is.
_static_dir = Path(__file__).parent.parent.parent / "static"
if _static_dir.exists():
    from fastapi.responses import FileResponse
    from fastapi.staticfiles import StaticFiles

    # Serve hashed JS/CSS/assets directly
    app.mount("/", StaticFiles(directory=str(_static_dir)), name="static-files")

    # SPA fallback: any path not matched above returns index.html so Angular routing works
    @app.exception_handler(404)
    async def spa_fallback(request: Request, exc: Exception):
        return FileResponse(str(_static_dir / "index.html"))


# uvicorn src.server.app:app --reload --port 8000
if __name__ == "__main__":
    uvicorn.run("src.server.app:app", host="127.0.0.1", port=8000, reload=True)
