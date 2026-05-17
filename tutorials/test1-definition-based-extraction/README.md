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

Both servers support Test 1 — pick whichever you have credentials/access for.

| Server             | Base URL                                            | Auth                 |
|--------------------|-----------------------------------------------------|----------------------|
| eHealth testserver | `https://hapi.fhir-testserver.be/fhir/{TENANT_ID}`  | `?api_key={API_KEY}` |
| Tiro testserver    | `http://localhost:8000/api/v1` (local, see below)   | none                 |

For eHealth, copy `TENANT_ID` and `API_KEY` (provided at the hackathon) into a `.env` file at the
repository root — the scripts pick them up automatically.

For the local Tiro testserver, boot it once from `apps/tiro_sdc_extract/`:

```bash
cd apps/tiro_sdc_extract
uv sync
uv run fastapi dev src/server/app.py
```

No credentials, no `.env` required. Override with `TIRO_BASE_URL` if you've deployed it elsewhere.

### Sample data

Two clinical scenarios in [`data/samples/`](../../data/samples/):

| Scenario                    | Questionnaire                      | QuestionnaireResponse   |
|-----------------------------|------------------------------------|-------------------------|
| OPAT (antibiotics infusion) | `homehosp_q_opat_definitions.json` | `homehosp_qr_opat.json` |
| Oncology (Trastuzumab)      | `homehosp_q_onco_definitions.json` | `homehosp_qr_onco.json` |

Pick one - the steps are identical for both.

---

## Step 1 - Call `$extract`

Two pairs of ready-made scripts — pick the one for your server:

| Scenario | Tiro testserver (local, default)             | eHealth testserver (HAPI)                                  |
|----------|----------------------------------------------|------------------------------------------------------------|
| OPAT     | `scripts/curls/working_extraction_opat.sh`   | `scripts/curls/working_extraction_opat_ehtestserver.sh`   |
| Oncology | `scripts/curls/working_extraction_onco.sh`   | `scripts/curls/working_extraction_onco_ehtestserver.sh`   |

Run one:

```bash
# Tiro (no creds, server must be running locally)
bash scripts/curls/working_extraction_opat.sh

# eHealth (needs TENANT_ID + API_KEY in .env)
bash scripts/curls/working_extraction_opat_ehtestserver.sh
```

Each script combines the Questionnaire and QuestionnaireResponse into a `Parameters` resource and
POSTs it to `QuestionnaireResponse/$extract` on the chosen server.

**Expected response:** a `transaction` Bundle with one or more entries (`Observation`,
`DiagnosticReport`, …). If you get an `OperationOutcome` instead, see
[Troubleshooting](#troubleshooting) below.

Pretty-print with `jq`:

```bash
bash scripts/curls/working_extraction_opat.sh | jq .
```

---

## Step 2 - POST the Bundle to the server

The Bundle is a `transaction` — POST it back to a FHIR server to persist the resources.

Against eHealth:

```bash
bash scripts/curls/working_extraction_opat.sh > bundle.json

curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}?api_key=${API_KEY}" \
  --header 'Content-Type: application/fhir+json' \
  --data @bundle.json
```

The local Tiro testserver only implements `$extract` — it does not store resources. Against any
other FHIR server, swap the URL accordingly.

A `200 OK` with a Bundle response confirms the resources were created.

---

## Step 3 - Verify with FHIR search

Confirm the extracted resources are queryable (eHealth example):

```bash
# Body temperature Observations for the sample patient
curl "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Observation\
?patient=ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a&code=8310-5&api_key=${API_KEY}"

# DiagnosticReports
curl "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/DiagnosticReport\
?patient=ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a&api_key=${API_KEY}"
```

You should get back resources whose values match what was in the QuestionnaireResponse.

---

## Success criteria

- [ ] `$extract` returns a `Bundle` (not an `OperationOutcome`).
- [ ] The Bundle contains at least one `Observation` referencing the correct patient.
- [ ] `Observation.status = "final"` and `Observation.category` is populated.
- [ ] `Observation.code` is set (from the `sdc-questionnaire-definitionExtractValue` extension).
- [ ] POSTing the Bundle to a FHIR server returns HTTP 200.
- [ ] A subsequent FHIR search returns the extracted Observation.

---

## Troubleshooting

See [`docs/fse-faq.md`](../../docs/fse-faq.md) for the most common errors:

- **`$extract` returns an error about a missing Questionnaire code map** → at least one item must carry the
  `sdc-questionnaire-definitionExtract` extension.
- **`NullPointerException` in `ItemPair`** → a linkId in the QR does not exist in the Q; check for mismatches.
- **Extracted Observations have empty `.code`** → add `sdc-questionnaire-definitionExtractValue` on the group
  item for `Observation.code` (either a fixed `valueCodeableConcept` or a FHIRPath expression like
  `%questionnaire.descendants().where(linkId = 'X').code`).
- **`valueExpression` silently ignored** → the server must support `definitionExtractValue.expression` (Tiro
  testserver does; some older versions of other servers do not).

---

## Bonus exercises

These are open-ended exploration prompts - no single right answer, no requirement to finish.

- [Bonus for data providers](bonus-data-provider.md) - use and extend the Python extractor (interesting if you don't
  have a FHIR server of your own)
- [Bonus for data transporters](bonus-data-transporter.md) - validation, idempotency, and lifecycle
- [Bonus for domain experts](bonus-domain-expert.md) - author your own definitions and Questionnaire
