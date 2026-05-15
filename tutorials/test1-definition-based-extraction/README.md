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
QuestionnaireResponse  →  $extract  →  Bundle  →  POST to server  →  FHIR search
```

No custom mapping code. The Questionnaire **is** the mapping.

---

## What you need

### Server

Both servers support Test 1. Pick one and copy its credentials into a `.env` file at the
repository root - the scripts read from it automatically.

| Server             | Base URL                                           | Auth                 |
|--------------------|----------------------------------------------------|----------------------|
| eHealth testserver | `https://hapi.fhir-testserver.be/fhir/{TENANT_ID}` | `?api_key={API_KEY}` |
| Tiro testserver    | _TBD - ask organisers_                             | _TBD_                |

### Sample data

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
POSTs it to `QuestionnaireResponse/$extract` on the eHealth testserver. To use the Tiro server
instead, update the base URL in the script.

**Expected response:** a `Bundle` resource with `type: transaction` containing one or more entries
(`Observation`, `DiagnosticReport`, …). If you get an `OperationOutcome` instead, see
[Troubleshooting](#troubleshooting) below.

---

## Step 2 - POST the Bundle to the server

Save the Bundle from Step 1 and POST it to the FHIR server base URL:

```bash
bash scripts/curls/working_extraction_opat.sh > bundle.json

curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}?api_key=${API_KEY}" \
  --header 'Content-Type: application/fhir+json' \
  --data @bundle.json
```

Or as a one-liner (skips inspecting the Bundle):

```bash
bash scripts/curls/working_extraction_opat.sh | \
  curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}?api_key=${API_KEY}" \
    --header 'Content-Type: application/fhir+json' \
    --data @-
```

A `200 OK` with a Bundle response confirms the resources were created on the server.

---

## Step 3 - Verify with FHIR search

Confirm the extracted resources are queryable:

```bash
# Body temperature Observations for the sample patient
curl "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Observation\
?patient=ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a&code=8310-5&api_key=${API_KEY}"

# DiagnosticReports
curl "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/DiagnosticReport\
?patient=ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a&api_key=${API_KEY}"
```

You should get back resources whose values match what was in the QuestionnaireResponse.

> The eHealth testserver already contains many patients. You are not limited to the sample patient
> above - browse with `GET /Patient?api_key=${API_KEY}` and use any patient ID you like.

---

## Success criteria

- [ ] `$extract` returns a `Bundle` (not an `OperationOutcome`).
- [ ] The Bundle contains at least one `Observation` referencing the correct patient.
- [ ] `Observation.status = "final"` and `Observation.category` is populated.
- [ ] `Observation.code` is set (from the `sdc-questionnaire-definitionExtractValue` extension on the group item).
- [ ] POSTing the Bundle to the server returns HTTP 200.
- [ ] A subsequent FHIR search returns the extracted Observation.

---

## Troubleshooting

See [`docs/fse-faq.md`](../../docs/fse-faq.md) for the most common errors:

- **`$extract` returns an error about a missing Questionnaire code map** → at least one item must carry the
  `sdc-questionnaire-definitionExtract` extension
- **`NullPointerException` in `ItemPair`** → a linkId in the QR does not exist in the Q; check for mismatches
- **Extracted Observations have empty `.code`** → add `sdc-questionnaire-definitionExtractValue` on the group item for
  `Observation.code`
- **`valueExpression` silently ignored** → use `valueCanonical` (for `definitionExtract`) and `valueUri` (for the
  `definition` sub-extension)

---

## Bonus exercises

These are open-ended exploration prompts - no single right answer, no requirement to finish.

- [Bonus for data providers](bonus-data-provider.md) - use and extend the Python extractor (interesting if you don't
  have a FHIR server of your own)
- [Bonus for data transporters](bonus-data-transporter.md) - validation, idempotency, and lifecycle
- [Bonus for domain experts](bonus-domain-expert.md) - author your own definitions and Questionnaire
