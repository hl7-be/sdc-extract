# Test 1 - Definition-based Extraction to FHIR Resources

**Difficulty:** Core  
**Estimated time:** 30–45 min

---

## What this test does

A `QuestionnaireResponse` (a completed clinical form) is submitted to a FHIR server via the
`$extract` operation. The server reads `.definition` links on `Questionnaire` items - each
pointing to a specific element path of a FHIR StructureDefinition - and assembles a Bundle of
profiled FHIR resources that can be independently searched and queried.

```
QuestionnaireResponse  →  $extract  →  Bundle  →  (optionally) POST  →  FHIR search
```

No custom mapping code. The Questionnaire **is** the mapping.

---

## Prerequisite - start the Tiro testserver locally

All scripts in this tutorial target the in-repo Tiro testserver at
`http://localhost:8001/api/v2`. Boot it once:

```bash
cd apps/tiro_sdc_extract
uv sync
uv run uvicorn src.server.app:app --reload --port 8001
```

No credentials, no `.env` required. Leave it running and switch back to the repository root for
the rest of the steps. To target a different deployment, set `TIRO_BASE_URL` before running the
scripts.

---

## Sample data

Two clinical scenarios are available in [`data/samples/`](../../data/samples/):

| Scenario                    | Questionnaire                      | QuestionnaireResponse   |
|-----------------------------|------------------------------------|-------------------------|
| OPAT (antibiotics infusion) | `homehosp_q_opat_definitions.json` | `homehosp_qr_opat.json` |
| Oncology (Trastuzumab)      | `homehosp_q_onco_definitions.json` | `homehosp_qr_onco.json` |

Pick one - the steps are identical for both.

---

## Step 1 - Call `$extract`

Run the ready-made script for your scenario:

```bash
# OPAT
bash scripts/curls/working_extraction_opat.sh

# Oncology
bash scripts/curls/working_extraction_onco.sh
```

The script combines the Questionnaire and QuestionnaireResponse into a `Parameters` resource and
POSTs it to `QuestionnaireResponse/$extract` on the local Tiro testserver.

**Expected response:** a `collection` Bundle containing one or more entries (`Observation`,
`DiagnosticReport`, …). If you get an `OperationOutcome` instead, see
[Troubleshooting](#troubleshooting) below.

Pretty-print with `jq` to inspect:

```bash
bash scripts/curls/working_extraction_opat.sh | jq .
```

---

## Step 2 - Validate the extracted resources

Open the Bundle and check that:

- Every entry has the right `resourceType` (`Observation`, `DiagnosticReport`, …).
- `Observation.status = "final"` and `Observation.category` is populated.
- `Observation.code` is set — populated either from a fixed value or from the question's `code`
  via a FHIRPath expression on the group item's
  `sdc-questionnaire-definitionExtractValue` extension.
- `Observation.value[x]` matches the answer in the QR.

A quick `jq` filter to list all extracted Observation codes and values:

```bash
bash scripts/curls/working_extraction_opat.sh \
  | jq '.entry[].resource | select(.resourceType=="Observation") | {code: .code.coding[0].code, value: (.valueCodeableConcept.coding[0].display // .valueQuantity.value)}'
```

---

## Step 3 (optional) - persist the Bundle to a FHIR server

The local Tiro testserver only implements `$extract` — it does not store or search resources. To
exercise the full data-transport flow, POST the Bundle to a FHIR server of your choice (HAPI, your
own instance, …) and query it back:

```bash
bash scripts/curls/working_extraction_opat.sh > bundle.json

# Replace with your own server URL:
curl --location "https://<your-fhir-server>/Bundle" \
  --header 'Content-Type: application/fhir+json' \
  --data @bundle.json
```

A `200 OK` followed by a successful `GET /Observation?...` confirms the resources are persisted and
queryable.

---

## Success criteria

- [ ] `$extract` returns a `Bundle` (not an `OperationOutcome`).
- [ ] The Bundle contains at least one `Observation`.
- [ ] `Observation.status = "final"` and `Observation.category` is populated.
- [ ] `Observation.code` is set on every Observation (issue #26).
- [ ] `Observation.value[x]` reflects the answer in the QR.

---

## Troubleshooting

See [`docs/fse-faq.md`](../../docs/fse-faq.md) for the most common errors:

- **`$extract` returns an error about a missing Questionnaire code map** → at least one item must carry the
  `sdc-questionnaire-definitionExtract` extension
- **`NullPointerException` in `ItemPair`** → a linkId in the QR does not exist in the Q; check for mismatches
- **Extracted Observations have empty `.code`** → add `sdc-questionnaire-definitionExtractValue` on the group item for
  `Observation.code` (either a fixed `valueCodeableConcept` or a FHIRPath `expression` like
  `%questionnaire.descendants().where(linkId = 'X').code`)
- **`valueExpression` silently ignored** → confirm you are running rc6 or later (rc5 only supported `fixed-value`)

---

## Bonus exercises

These are open-ended exploration prompts - no single right answer, no requirement to finish.

- [Bonus for data providers](bonus-data-provider.md) - use and extend the Python extractor (interesting if you don't
  have a FHIR server of your own)
- [Bonus for data transporters](bonus-data-transporter.md) - validation, idempotency, and lifecycle
- [Bonus for domain experts](bonus-domain-expert.md) - author your own definitions and Questionnaire
