# Test 2 - Extraction to a Logical Model

**Difficulty:** Advanced  
**Estimated time:** 30–45 min  
**Prerequisite:** complete [Test 1](../test1-definition-based-extraction/README.md) first

---

> [!IMPORTANT]
> **Logical-model extraction does not work on the eHealth testserver (HAPI).** This test
> requires the local Tiro testserver — see
> [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md)
> for the underlying reason.

---

## What this test does

Instead of extracting into standard FHIR resource types (`Observation`, `DiagnosticReport`…), the
Questionnaire items point to elements of a **logical model** - a custom data structure defined as
a FHIR `StructureDefinition` with `kind: logical`. The `$extract` response is either the raw JSON
of that logical-model instance, or a `Binary` resource wrapping the same JSON, depending on the
`Accept` header you send.

```
QuestionnaireResponse  →  $extract  →  raw JSON (or Binary{base64 JSON})  →  validate / load
```

Compared to Test 1:

| | Test 1 | Test 2 |
|--|--------|--------|
| `.definition` targets | Core FHIR resource element (e.g. `Observation#Observation.valueQuantity.value`) | Logical-model element (e.g. `HomeHospAssessment#HomeHospAssessment.vitals.temperature`) |
| `Accept` header | `application/fhir+json` | `application/json` (raw) **or** `application/fhir+json` (Binary envelope) |
| Response | `collection` Bundle of FHIR resources | Logical-model instance (raw JSON or Binary-wrapped) |

### Accept-header content negotiation

| `Accept`                  | Response body                                                          |
|---------------------------|------------------------------------------------------------------------|
| `application/json`        | Raw decoded logical-model JSON (no envelope, no base64).               |
| `application/fhir+json`   | A FHIR `Binary` resource with `contentType: application/json` and the logical-model JSON base64-encoded in `data`. |
| absent or `*/*`           | Defaults to the FHIR `Binary` envelope.                                |

The atelier scripts default to `application/json` so you can pipe the response directly into `jq`.

---

## Prerequisite - start the Tiro testserver locally

Same as Test 1 — boot the local server if you haven't already:

```bash
cd apps/tiro_sdc_extract
uv sync
uv run fastapi dev src/server/app.py
```

---

## Sample data

Logical-model Questionnaires are in [`data/samples/`](../../data/samples/). The
QuestionnaireResponses from Test 1 are reused directly.

| Scenario | Questionnaire                       | QuestionnaireResponse   |
|----------|-------------------------------------|-------------------------|
| OPAT     | `homehosp_q_opat_logicalmodel.json` | `homehosp_qr_opat.json` |
| Oncology | `homehosp_q_onco_logicalmodel.json` | `homehosp_qr_onco.json` |

---

## Step 1 - Register the logical-model StructureDefinitions

The Tiro testserver loads StructureDefinitions from
`${STRUCTURE_DEFINITIONS_DIR:-data/structure-definitions/}` at startup. Copy the two logical-model
SDs into that folder:

```bash
bash scripts/curls/upload_logicalmodel_structuredefinitions.sh
```

`fastapi dev` runs with reload enabled — touch any source file (or restart the process) so the
loader rebuilds its directory listing and picks up the new StructureDefinitions.

---

## Step 2 - Call `$extract`

```bash
# OPAT
bash scripts/curls/working_extraction_opat_logicalmodel.sh

# Oncology
bash scripts/curls/working_extraction_onco_logicalmodel.sh
```

Both scripts send `Accept: application/json`, so the response is the raw logical-model instance.
Pretty-print with `jq`:

```bash
bash scripts/curls/working_extraction_opat_logicalmodel.sh | jq .
```

If you need the FHIR `Binary` envelope instead (useful when piping into FHIR-aware tooling that
insists on a resource shape), change the script's `Accept` header to `application/fhir+json` and
decode the `.data` field:

```bash
bash scripts/curls/working_extraction_opat_logicalmodel.sh \
  | jq -r '.data' | base64 --decode | jq .
```

---

## Step 3 - Validate against the logical model

Inspect the decoded JSON and check that the field names and nesting match the element paths
defined in the `StructureDefinition` (`.snapshot.element[*].path`). Each answer in the QR should
have landed in the correct element.

---

## Success criteria

- [ ] `$extract` returns either raw JSON (`Accept: application/json`) or a `Binary` resource
      (`Accept: application/fhir+json`).
- [ ] The JSON conforms to the logical model — field paths match `StructureDefinition.snapshot.element[*].path`.
- [ ] Every QR answer is reflected in the matching element.

---

## Troubleshooting

- **Returns a Bundle with empty entries** → the server thinks the extraction is FHIR-only, which
  means it couldn't resolve any of the logical-model element paths. Confirm that the relevant
  StructureDefinition was copied into `STRUCTURE_DEFINITIONS_DIR` and the server was restarted.
- **422 `OperationOutcome` "produced both FHIR resources and logical-model instances"** → the
  Questionnaire mixes core-resource targets and logical-model targets in one extraction context;
  split the groups so each emits a single shape.
- **Returns the Binary envelope when you expected raw JSON** → check the `Accept` header on the
  request. `application/json` selects the raw branch; anything else falls back to `Binary`.
- **`ClassNotFoundException` / server error** → you are talking to HAPI, not the Tiro testserver.
  Verify the URL points to `http://localhost:8000/api/v1` (see
  [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md)).

---

## Bonus exercises

These are open-ended exploration prompts - no single right answer, no requirement to finish.

- [Bonus for data providers](bonus-data-provider.md) - implement logical-model extraction in Python
- [Bonus for data transporters](bonus-data-transporter.md) - validation and lifecycle for logical-model output
- [Bonus for domain experts](bonus-domain-expert.md) - design your own logical model
- [Bonus for developers: fix HAPI](bonus-developers-hapi-fork.md) - prototype a fix for logical-model extraction in HAPI upstream
