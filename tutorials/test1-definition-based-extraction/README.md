# Test 1 — Definition-based Extraction to FHIR Resources

**Difficulty:** Core  
**Estimated time:** 30–45 min

---

## Objective

Transform a completed `QuestionnaireResponse` into discrete, searchable FHIR resources using
the `.definition` element on `Questionnaire` items and the `$extract` operation.

---

## Background

Definition-based extraction is the mechanism in [FHIR SDC](https://hl7.org/fhir/uv/sdc/) that
turns a form into an extraction specification. Each `Questionnaire.item` carries a `.definition`
element that points at a specific element path of a FHIR StructureDefinition, e.g.:

```
"definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value"
```

When `$extract` is called, HAPI's Clinical Reasoning engine walks the `QuestionnaireResponse`,
pairs each answer with its corresponding `Questionnaire` item, follows the `.definition` path,
and writes the answer value into a freshly constructed FHIR resource. The result is a
`Bundle` of `type: transaction` ready to POST to any FHIR server.

Fixed values (status, category, subject, code) are injected via
`sdc-questionnaire-definitionExtractValue` extensions on the **group** item that represents
the target resource — not on the leaves. The group also carries `sdc-questionnaire-definitionExtract`
to declare which resource type to produce.

---

## Sample Data

Two completed assessments are provided under [`data/samples/`](../../data/samples/):

| Use case                    | Questionnaire                                                                             | QuestionnaireResponse                                               |
|-----------------------------|-------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| OPAT (antibiotics infusion) | [`homehosp_q_opat_definitions.json`](../../data/samples/homehosp_q_opat_definitions.json) | [`homehosp_qr_opat.json`](../../data/samples/homehosp_qr_opat.json) |
| Oncology (Trastuzumab)      | [`homehosp_q_onco_definitions.json`](../../data/samples/homehosp_q_onco_definitions.json) | [`homehosp_qr_onco.json`](../../data/samples/homehosp_qr_onco.json) |

Each Questionnaire groups items into logical sections (Bewaring, Observatieparameters,
Tegenindicaties, Symptoomlast, Opdracht, …). Every group that should produce a FHIR resource
carries `sdc-questionnaire-definitionExtract` pointing to the target StructureDefinition and
`sdc-questionnaire-definitionExtractValue` entries for fixed fields like `status`, `category`,
and `subject`. Leaf items carry `.definition` pointing to the exact element path within that
resource.

---

## Step 1 — Call `$extract`

The operation accepts the `Questionnaire` and `QuestionnaireResponse` together as a `Parameters`
resource in the body. Use the ready-made scripts:

```bash
# OPAT
bash scripts/curls/working_extraction_opat.sh

# Oncology
bash scripts/curls/working_extraction_onco.sh
```

Both scripts ([`working_extraction_opat.sh`](../../scripts/curls/working_extraction_opat.sh),
[`working_extraction_onco.sh`](../../scripts/curls/working_extraction_onco.sh)):

1. Read the Q and QR from `data/samples/`.
2. Inline them into a `Parameters` body via `printf` + `cat`.
3. POST to `QuestionnaireResponse/$extract` on the Tiro test server and/or the ehealth testserver.

The endpoint requires `TENANT_ID` and `API_KEY` from `.env` at the repo root if the ehealth testserver is used.

**Expected response:** a `Bundle` of `type: transaction` containing `Observation` and
`DiagnosticReport` entries, each with a `request.method: POST` and `request.url` set to the
resource type.

---

## Step 2 — POST the Bundle to the eHealth Test Server

Save the Bundle from Step 1 to a file and POST it:

```bash
bash scripts/curls/working_extraction_opat.sh > bundle.json

curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}" \
  --header "Content-Type: application/fhir+json" \
  --data @bundle.json
```

**One-liner shortcut:** Steps 1 and 2 can be chained — the extraction script's output (the Bundle) is piped directly
into the POST without saving to disk:

 ```bash
 bash scripts/curls/working_extraction_opat.sh | \
   curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}" \
     --header "Content-Type: application/fhir+json" \
     --data @-
 ```

`--data @-` tells curl to read the request body from stdin (i.e. what the extraction script printed).
Note: this skips inspecting the Bundle before posting — use the two-step approach if you want to verify the extracted
resources first.

---

## Step 3 — Verify with FHIR Search

After a successful POST, verify individual resources are searchable:

```
GET /Observation?patient=<patient-id>&code=8310-5   # Body temperature (LOINC)
GET /Observation?patient=<patient-id>&code=8480-6   # Systolic BP
GET /DiagnosticReport?patient=<patient-id>
```

The patient reference used in the sample data is:

```
Patient/ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a
```

> **eHealth Test Server:** The server already contains many patients and other FHIR resources.
> You are not limited to the patient above — browse available patients via
> `GET https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Patient?api_key=${API_KEY}`
> and pick any patient ID to use in your QR and search queries.

---

## Success Criteria

- [ ] `$extract` returns a `Bundle` (not an `OperationOutcome` with errors).
- [ ] Bundle entries reference the correct patient.
- [ ] `Observation.status = final`, `Observation.category` set correctly (vital-signs or survey).
- [ ] `Observation.code` populated (comes from `sdc-questionnaire-definitionExtractValue` on the group).
- [ ] Bundle POSTed successfully to the eHealth Test Server (HTTP 200).
- [ ] `GET /Observation?patient=<id>` returns the extracted observations.

---

## Common Errors

See the [FSE section in the root README](../../README.md#fse-frequent-stupid-errors-to-avoid) for:

- `IllegalArgumentException: Unable to retrieve Questionnaire code map` — missing `sdc-questionnaire-definitionExtract`
  extension.
- `NullPointerException` in `ItemPair.getItem()` — a `linkId` in the QR has no matching item in the Q.
- Empty `Observation.code` — missing `sdc-questionnaire-definitionExtractValue` for `Observation.code` on the group.
- `valueExpression` silently ignored — use `valueCanonical`/`valueUri` instead.
