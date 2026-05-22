# ── Stage 1: build Angular frontend ─────────────────────────────────────────
FROM node:20-alpine AS frontend-build
WORKDIR /build
COPY apps/Q2Rmapper/web/package*.json ./
RUN npm ci
COPY apps/Q2Rmapper/web/ ./
RUN npm run build

# ── Stage 2: Python runtime ───────────────────────────────────────────────────
FROM python:3.11-slim
WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Install Python dependencies (cached as a separate layer)
COPY apps/Q2Rmapper/api/pyproject.toml apps/Q2Rmapper/api/uv.lock ./
RUN uv sync --frozen --no-dev

# Copy application source
COPY apps/Q2Rmapper/api/src ./src

# Copy Angular build output — served as static files by FastAPI
# Angular 17+ application builder outputs browser files to dist/frontend/browser/
COPY --from=frontend-build /build/dist/frontend/browser ./static

EXPOSE 8000
ENV PYTHONUNBUFFERED=1

CMD ["uv", "run", "uvicorn", "src.server.app:app", "--host", "0.0.0.0", "--port", "8000"]
