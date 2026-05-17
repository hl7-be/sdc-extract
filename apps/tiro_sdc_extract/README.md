# tiro_sdc_extract

**tiro_sdc_extract** is a standalone FHIR SDC `$extract` service that implements [definition-based extraction](https://build.fhir.org/ig/HL7/sdc/extraction.html#definition-based-extraction) as a conformant FHIR REST endpoint.

It exposes `POST /api/v1/QuestionnaireResponse/$extract` and accepts a FHIR `Parameters` resource containing a `Questionnaire` and a `QuestionnaireResponse`. It returns a `transaction` Bundle of extracted FHIR resources or, for logical-model targets, the model instance directly (raw JSON or a `Binary` envelope depending on `Accept`).

This service is separate from the [Q2Rmapper](../Q2Rmapper/README.md) annotation tool. It is the server-side extraction endpoint intended for integration by EHR vendors and care software who want to delegate the `$extract` operation to a shared service.

---

## Requirements

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (recommended package manager)

---

## Running locally

From the `tiro_sdc_extract/` directory:

```bash
uv sync           # install all dependencies from pyproject.toml / uv.lock
uv run fastapi dev
```

The service will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

The FastAPI CLI auto-discovers the app — no path argument is needed (and passing one is discouraged).

> **Note:** `uv run fastapi dev` (and `uv run fastapi run`) must be run in the **foreground**. Appending `&` to background the process causes it to exit immediately — the FastAPI CLI attaches to the controlling TTY and won't stay up when detached. To run the server in the background, invoke `uvicorn` directly instead, e.g. `uv run uvicorn main:app &` (`main.py` re-exports `app` from `src/server/app.py`).

---

## Configuration

| Environment variable | Description | Default |
|---|---|---|
| `STRUCTURE_DEFINITIONS_DIR` | Directory containing FHIR `StructureDefinition` JSON files loaded at request time | `<repo root>/data/structure-definitions/` |

No FHIR server connection is needed — the service is stateless and processes the `Parameters` body entirely in memory.

---

## StructureDefinitions

Every `$extract` request rebuilds the loader from `STRUCTURE_DEFINITIONS_DIR` (default `<repo>/data/structure-definitions/`), so:

- Drop new `.json` files into that directory and the **next request picks them up** — no restart, no reload trigger.
- Each `.json` is read as a single FHIR `StructureDefinition`. Filenames are not significant; the SD is keyed by its `url`.
- Subdirectories are ignored — keep files flat.

**What ships in `data/structure-definitions/`:**

| File | Used by |
|---|---|
| `Observation.json` | Test 1 (definition-based extraction to FHIR `Observation`) |
| `DiagnosticReport.json` | Test 1 |
| `DeviceUseStatement.json` | Test 1 |
| `StructureDefinition-opat-continuous-infusion-questionnaire.json` | Test 2 (OPAT logical model) |
| `StructureDefinition-onco-trastuzumab-questionnaire.json` | Test 2 (onco logical model) |

Both Test 1 and Test 2 run out of the box — no registration step.

---

## API endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/metadata` | FHIR CapabilityStatement |
| POST | `/api/v1/QuestionnaireResponse/$extract` | Definition-based extraction |

### `POST /api/v1/QuestionnaireResponse/$extract`

**Request body** — a FHIR `Parameters` resource:

```json
{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "questionnaire",          "resource": {  } },
    { "name": "questionnaire-response", "resource": {  } }
  ]
}
```

**Response** — content-negotiated based on the request's `Accept` header and the shape of the extracted result:

| Extracted result          | `Accept`                          | Response body |
|---|---|---|
| FHIR resources only       | `application/fhir+json` (default) | `transaction` Bundle (ready to POST back to a FHIR server) |
| Logical-model instance(s) | `application/fhir+json` (default) | FHIR `Binary` wrapping the JSON in base64 |
| Logical-model instance(s) | `application/json`                | Raw logical-model JSON (no envelope) |
| Mixed FHIR + logical-model | any                              | `422 OperationOutcome` — split the Questionnaire |

Any other error returns an `OperationOutcome`.

Both standard FHIR R4 resource types and custom logical models are supported as extraction targets — the corresponding `StructureDefinition` must be present in `STRUCTURE_DEFINITIONS_DIR` (see [StructureDefinitions](#structuredefinitions) above for what ships in the default directory).

---

## Project structure

```
tiro_sdc_extract/
├── src/
│   └── server/
│       ├── app.py                  # FastAPI application entry point
│       ├── fhir_parameters.py      # Helpers for reading FHIR Parameters resources
│       ├── structure_definitions.py # Loads StructureDefinitions from disk for extraction
│       ├── utils.py                # FhirJSONResponse, OperationOutcomeException, bundle helpers
│       └── routers/
│           └── v2.py               # $extract and /metadata route handlers
├── tests/
│   ├── conftest.py
│   ├── fixtures/                   # Per-fixture quadruples: q, qr, sd, expected
│   └── test_extract.py
└── pyproject.toml
```

---

## Running tests

```bash
uv sync           # install all dependencies from pyproject.toml / uv.lock
uv run pytest
```

---

## uv — package management

| Task | Command |
|------|---------|
| Install dependencies | `uv sync` |
| Add a dependency | `uv add <package>` |
| Run a command | `uv run <command>` |
