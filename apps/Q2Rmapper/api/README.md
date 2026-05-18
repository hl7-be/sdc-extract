# Q2R Mapper — Backend

FastAPI backend for annotating FHIR Questionnaires with SNOMED CT codes and FHIR element definitions, enabling definition-based extraction of QuestionnaireResponses into structured FHIR resources.

---

## Requirements

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (recommended package manager)

---

## Running locally

From the `Q2Rmapper/api/` directory:

```bash
uv run python -m uvicorn src.server.app:app --reload --port 8000
```

The API will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

> Always run from `api/` — not from a subdirectory. Relative imports and the FHIR cache path depend on this.

---

## uv — package management

[uv](https://docs.astral.sh/uv/) is a fast Python package manager. It reads `pyproject.toml` and manages the virtual environment automatically.

| Task | Command |
|------|---------|
| Install dependencies | `uv sync` |
| Add a dependency | `uv add <package>` |
| Remove a dependency | `uv remove <package>` |
| Update all dependencies | `uv sync --upgrade` |
| Update one dependency | `uv add <package>@latest` |
| Run a script/command | `uv run <command>` |

No need to activate a virtual environment manually — `uv run` handles it.

---

## Connecting to a FHIR server

The backend resolves the target FHIR server in two steps, in order of priority:

```
1. X-FHIR-Base-URL header   ← set by the frontend per request (overrides everything)
2. FHIR_BASE_URL env var    ← your .env file; used when no header is present
```

### Changing the default server

Copy `.env.example` to `.env` and set `FHIR_BASE_URL`:

```bash
cp .env.example .env
```

Then edit `.env`:

```bash
# HAPI FHIR public (default, no auth)
FHIR_BASE_URL=https://hapi.fhir.org/baseR4

# eHealth test server (Belgium)
FHIR_BASE_URL=https://hapi.fhir-testserver.be/fhir/<tenantId>

# Tiro FHIR server
FHIR_BASE_URL=https://<tiro-host>/fhir/r4

# Google Cloud Healthcare API
FHIR_BASE_URL=https://healthcare.googleapis.com/v1/projects/<project>/locations/<location>/datasets/<dataset>/fhirStores/<store>/fhir
```

The `.env` file is loaded automatically on startup via `python-dotenv`.

### Authentication

| Auth method | When it is used | How to configure |
|---|---|---|
| Google service account | `GOOGLE_SERVICE_ACCOUNT_FILE` is set and the file exists | Set `GOOGLE_SERVICE_ACCOUNT_FILE=/path/to/sa.json` in `.env` |
| API key | `FHIR_API_KEY` is set (and no service account) | Set `FHIR_API_KEY=<key>` in `.env`; sent as `?api_key=...` |
| No auth | Neither of the above | Works for public servers (e.g. HAPI public) |

When `GOOGLE_SERVICE_ACCOUNT_FILE` is set the backend uses `google-auth` to obtain short-lived Bearer tokens automatically — no manual token management needed.

### Overriding per request (frontend / curl)

Any request can target a different server by passing the headers directly — this overrides the `.env` default:

```
X-FHIR-Base-URL: https://hapi.fhir-testserver.be/fhir/<tenantId>
X-FHIR-API-Key: <optional key>
```

The settings modal in the web UI exposes these fields. For curl or the `/docs` UI, add the headers manually.

> **Google Cloud Healthcare API**: when this server is selected in the UI, the frontend sends `https://healthcare.googleapis.com` as a sentinel and the backend substitutes the full URL from `FHIR_BASE_URL` in `.env`. Service account auth is applied automatically for any URL starting with `https://healthcare.googleapis.com`.

---

## Project structure

```
Q2Rmapper/api/
├── src/
│   ├── server/
│   │   ├── app.py            # FastAPI app entry point
│   │   ├── fhir_client.py    # FHIR HTTP client
│   │   └── fhir_validator.py # StructureDefinition fetching + caching
│   └── core/
│       ├── processor.py      # Extraction logic (QuestionnaireResponse → Bundle)
│       └── sdc_annotations.py
├── .fhir_cache/              # Local cache of FHIR StructureDefinitions
└── pyproject.toml
```

---

## Extraction implementation — local, not server-native

The `/questionnaire-response/extract` endpoints implement **definition-based extraction in Python** (`src/core/extractor.py`). This is **not** a proxy to the FHIR server's native `$extract` operation.

### What this means in practice

| Aspect | This tool | Native FHIR `$extract` |
|---|---|---|
| Who runs the logic | Python backend (this repo) | The FHIR server itself |
| SDC conformance | Best-effort implementation of SDC v4 definition-based extraction | Server-specific (may vary) |
| Output Bundle | Transaction Bundle built locally, then optionally POSTed | Server-generated Bundle |
| Validation | Structural validation only | Full server-side validation |

The preview result is useful for verifying that your questionnaire mapping targets the right FHIR elements. However, the exact Bundle structure, error handling, and resource content produced by a real FHIR server's `$extract` operation may differ.

## API endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/hello` | Health check |
| GET | `/api/v1/list_questionnaires` | List Questionnaires from FHIR server |
| GET | `/api/v1/questionnaire/{id}` | Get latest Questionnaire version |
| GET | `/api/v1/questionnaire/{id}/_history` | Get all Questionnaire versions |
| GET | `/api/v1/questionnaire/{id}/response` | Get most recent QuestionnaireResponse |
| PUT | `/api/v1/questionnaire/status/{status}` | Save annotated Questionnaire with mapping status |
| POST | `/api/v1/questionnaire-response/extract` | Extract FHIR resources from QR body |
| GET | `/api/v1/questionnaire-response/{id}/extract` | Extract FHIR resources from stored QR |
| GET | `/api/v1/fhir-elements?resourceType=Observation` | List valid element paths for a resource type |
| GET | `/api/v1/search_snomed_concept?query=...` | Search SNOMED CT concepts via Snowstorm |
