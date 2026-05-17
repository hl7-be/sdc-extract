# tiro_sdc_extract

**tiro_sdc_extract** is a standalone FHIR SDC `$extract` service that implements [definition-based extraction](https://build.fhir.org/ig/HL7/sdc/extraction.html#definition-based-extraction) as a conformant FHIR REST endpoint.

It exposes `POST /api/v1/QuestionnaireResponse/$extract` and accepts a FHIR `Parameters` resource containing a `Questionnaire` and a `QuestionnaireResponse`. It returns a `collection` Bundle of extracted FHIR resources or logical model instances.

This service is separate from the [Q2Rmapper](../Q2Rmapper/README.md) annotation tool. It is the server-side extraction endpoint intended for integration by EHR vendors and care software who want to delegate the `$extract` operation to a shared service.

---

## Requirements

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (recommended package manager)

---

## Running locally

From the `tiro_sdc_extract/` directory:

```bash
uv sync
uv run fastapi dev src/server/app.py
```

The service will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

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

That's enough to run Test 1 out of the box. For Test 2 (logical-model extraction), copy the two logical-model SDs in `data/samples/` into the loader directory:

```bash
bash scripts/curls/register_logicalmodel_structuredefinitions.sh
```

The script is just a `cp` — there is no `PUT StructureDefinition` endpoint on the server.

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
| FHIR resources only       | `application/fhir+json` (default) | `collection` Bundle |
| Logical-model instance(s) | `application/fhir+json` (default) | FHIR `Binary` wrapping the JSON in base64 |
| Logical-model instance(s) | `application/json`                | Raw logical-model JSON (no envelope) |
| Mixed FHIR + logical-model | any                              | `422 OperationOutcome` — split the Questionnaire |

Any other error returns an `OperationOutcome`.

Both standard FHIR R4 resource types and custom logical models are supported as extraction targets — the corresponding `StructureDefinition` must be present in `STRUCTURE_DEFINITIONS_DIR`. For logical-model extraction, register the SDs first with `scripts/curls/register_logicalmodel_structuredefinitions.sh` (copies them into the loader directory — the loader rebuilds per request, so no restart needed).

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
uv sync
uv run pytest
```

---

## uv — package management

| Task | Command |
|------|---------|
| Install dependencies | `uv sync` |
| Add a dependency | `uv add <package>` |
| Run a command | `uv run <command>` |
