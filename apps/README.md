# apps — Q2R Mapper

**Q2R Mapper** (Questionnaire-to-Resource Mapper) is an interactive tool for annotating FHIR Questionnaires with [SDC definition-based extraction](https://build.fhir.org/ig/HL7/sdc/extraction.html#definition-based-extraction) mappings and extracting structured FHIR resources from QuestionnaireResponses.

It is used as part of the [FHIR SDC extract test atelier](../README.md) to validate extraction against multiple FHIR servers.

## Structure

```
apps/
├── api/    # FastAPI backend — see api/README.md
└── web/    # Angular 18 frontend — see web/README.md
```

## Running locally

### 1. Backend

```bash
cd apps/api

# First time: install dependencies (requires uv: https://docs.astral.sh/uv/)
uv sync

# Copy and configure environment
cp .env.example .env
# → edit .env: set FHIR_BASE_URL and optionally GOOGLE_SERVICE_ACCOUNT_FILE

# Start backend (http://localhost:8000)
uv run uvicorn src.server.app:app --reload --port 8000
```

Interactive API docs: `http://localhost:8000/docs`

### 2. Frontend

```bash
cd apps/web

npm install

# Start dev server (http://localhost:4200, proxies /api/* → localhost:8000)
npm start
```

> Start the backend before the frontend. The frontend proxies all `/api/*` requests to `http://localhost:8000`.

## FHIR server configuration

The target FHIR server is resolved in this order:

1. **`X-FHIR-Base-URL` header** — set per-request by the frontend settings modal (overrides everything)
2. **`FHIR_BASE_URL` in `api/.env`** — used when no header is present

Use the **⚙ Settings** button in the UI to switch servers at runtime without rebuilding. Supported servers:

| Server | URL pattern |
|---|---|
| eHealth test server (Belgium) | `https://hapi.fhir-testserver.be/fhir/{tenantId}` — requires API key |
| Google Cloud Healthcare API | Select from preset — URL is read from `FHIR_BASE_URL` in `.env` |
| HAPI FHIR (public) | `https://hapi.fhir.org/baseR4` — no auth |

See [`api/README.md`](api/README.md) for authentication details (`FHIR_API_KEY`, `GOOGLE_SERVICE_ACCOUNT_FILE`).

## Extraction preview — important note

The **$extract preview** in this tool is computed locally by the Python backend (`api/src/core/extractor.py`). It is **not** a call to the FHIR server's native `$extract` operation.

This means:

- The preview shows what the extraction logic *in this tool* would produce, based on the SDC definition-based extraction rules implemented here.
- A real FHIR server that natively supports `$extract` (e.g. HAPI FHIR, Google Healthcare API) may produce different output — different Bundle structure, different handling of edge cases, or additional validation errors.
- Use the preview to validate your questionnaire mapping and verify that the right FHIR elements are being targeted. Do not assume the preview output is identical to what a conformant FHIR server would return.

When you click **Save extracted resources**, the locally-computed Bundle is POSTed as a transaction to the configured FHIR store — the server is not asked to run `$extract` itself.

## API endpoints

All endpoints are prefixed with `/api/v1`.

| Method | Path | Description |
|---|---|---|
| GET | `/hello` | Health check |
| GET | `/list_questionnaires` | List all Questionnaires (paginated) |
| GET | `/questionnaire/{id}` | Get latest Questionnaire version |
| GET | `/questionnaire/{id}/_history` | Get all Questionnaire versions |
| GET | `/questionnaire/{id}/response` | Get most recent QuestionnaireResponse |
| PUT | `/questionnaire/status/{status}` | Save annotated Questionnaire with mapping status |
| POST | `/questionnaire-response/extract` | Extract FHIR resources from QR in request body |
| GET | `/questionnaire-response/{id}/extract` | Extract FHIR resources from stored QR |
| GET | `/fhir-elements?resourceType=Observation` | List valid element paths for a resource type |
| GET | `/search_snomed_concept?query=...` | Search SNOMED CT concepts via Snowstorm |
