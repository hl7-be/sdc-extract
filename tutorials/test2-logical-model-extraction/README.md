# Test 2 — Extraction to Logical Models

**Difficulty:** Advanced  
**Estimated time:** 45–60 min

---

## Objective

Extract data from a `QuestionnaireResponse` into a custom data model defined as a FHIR
**logical model** (`StructureDefinition` with `kind: logical`). The result is a `Binary`
resource containing raw JSON that conforms to the logical model's element structure — not
a bundle of FHIR clinical resources.

---

## Background

### What is a FHIR Logical Model?

A FHIR logical model is a `StructureDefinition` with `kind: logical` that describes an
arbitrary data structure — it does not need to correspond to any FHIR resource type. Registries
(BCR, HD4DP, QERMID) use logical models to specify their submission formats independently of
standard FHIR clinical resources.

### How does extraction differ from Test 1?

| Aspect                                                 | Test 1 (FHIR resources)                                                                      | Test 2 (Logical model)                                                                                        |
|--------------------------------------------------------|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| `.definition` targets                                  | `StructureDefinition#Resource.element` (e.g., `Observation#Observation.valueQuantity.value`) | `StructureDefinition#LogicalModel.element` (e.g., `HomeHospAssessment#HomeHospAssessment.vitals.temperature`) |
| `sdc-questionnaire-definitionExtract` `valueCanonical` | `http://hl7.org/fhir/StructureDefinition/Observation`                                        | URL of the logical model, e.g., `http://example.org/StructureDefinition/HomeHospAssessment`                   |
| `Accept` header                                        | `application/fhir+json`                                                                      | **`application/json`**                                                                                        |
| Response type                                          | `Bundle` of FHIR resources                                                                   | `Binary` containing raw JSON                                                                                  |
| Output use                                             | POST to FHIR server, query via FHIR search                                                   | Feed to registry-specific system                                                                              |

The critical difference is the **`Accept: application/json`** header. HAPI's CR engine checks
this header to decide whether to run definition-based extraction into FHIR resources or into
a logical model structure.

---

## What You Need

### 1. A logical model Questionnaire

You need a `Questionnaire` where:

- Each item's `.definition` points to an element path in your logical model, e.g.:
  ```
  "definition": "http://example.org/StructureDefinition/HomeHospAssessment#HomeHospAssessment.vitals.temperature"
  ```
- The group item that represents the root of the logical model carries:
  ```json
  {
    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
    "valueCanonical": "http://example.org/StructureDefinition/HomeHospAssessment"
  }
  ```

Sample files (to be added):

- `data/samples/homehosp_q_opat_logicalmodel.json`
- `data/samples/homehosp_q_onco_logicalmodel.json`

### 2. A completed QuestionnaireResponse

Reuse the existing samples — the QR structure does not change between Test 1 and Test 2;
only the Q changes:

- [`data/samples/homehosp_qr_opat.json`](../../data/samples/homehosp_qr_opat.json)
- [`data/samples/homehosp_qr_onco.json`](../../data/samples/homehosp_qr_onco.json)

> **eHealth Test Server:** The server already contains many patients and other FHIR resources.
> You can substitute any patient from the server — browse via
> `GET https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Patient?api_key=${API_KEY}` —
> and update the `subject.reference` in your QR accordingly.

### 3. The logical model StructureDefinition

The `StructureDefinition` with `kind: logical` must be registered on the FHIR server before
calling `$extract`, so the server can resolve the canonical URL in `.definition` and
`sdc-questionnaire-definitionExtract`. POST it first:

```bash
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/StructureDefinition?api_key=${API_KEY}" \
  --header "Content-Type: application/fhir+json" \
  --data "@data/samples/homehosp_logicalmodel.json"
```

---

## Step 1 — Call `$extract` with `Accept: application/json`

Use the ready-made scripts:

```bash
# OPAT
bash scripts/curls/working_extraction_opat_logicalmodel.sh

# Oncology
bash scripts/curls/working_extraction_onco_logicalmodel.sh
```

Both scripts ([`working_extraction_opat_logicalmodel.sh`](../../scripts/curls/working_extraction_opat_logicalmodel.sh),
[`working_extraction_onco_logicalmodel.sh`](../../scripts/curls/working_extraction_onco_logicalmodel.sh))
are identical to the Test 1 scripts except for one header:

```
--header 'Accept: application/json'
```

This signals to HAPI's CR to produce logical model JSON instead of a FHIR Bundle.

---

## Step 2 — Inspect the Binary Response

The server returns a `Binary` resource. The actual payload is in `Binary.data` (base64-encoded)
or in `Binary.content` depending on the HAPI version. Decode it:

```bash
bash scripts/curls/working_extraction_opat_logicalmodel.sh \
  | jq -r '.data' | base64 -d | jq .
```

The decoded JSON should match your logical model's element structure, e.g.:

```json
{
  "resourceType": "HomeHospAssessment",
  "vitals": {
    "temperature": 37.2,
    "systolicBP": 120,
    "diastolicBP": 80,
    "weight": 72.5
  },
  "contraindications": {
    "present": true,
    "dyspnea": true
  }
}
```

---

## Step 3 — Validate Against the Logical Model

Validate the decoded JSON against your logical model StructureDefinition using the FHIR
validator or a registry-specific schema.

---

## Success Criteria

- [ ] `$extract` returns a `Binary` resource (not a `Bundle` or `OperationOutcome`).
- [ ] `Binary.data` decodes to valid JSON.
- [ ] Decoded JSON element paths match the logical model StructureDefinition.
- [ ] Logical model StructureDefinition can be registered on the test server without errors.
- [ ] Decoded JSON can be consumed by the registry-specific system (or passes schema validation).

---

## Common Errors

- **Returns a Bundle instead of Binary** — `Accept: application/json` header missing or
  overridden. Check that no other `Accept` header is set.
- **`NullPointerException` in `ItemPair.getItem()`** — linkId mismatch between QR and Q.
  See [FSE section](../../README.md#nullpointerexception-deep-in-itempairgetitem).
- **StructureDefinition not found** — the canonical URL in `.definition` / `sdc-questionnaire-definitionExtract`
  doesn't resolve on the server. Register the logical model first (Step 0 above).
