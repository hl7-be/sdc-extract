# Test 2 - Extraction to a Logical Model

**Difficulty:** Advanced  
**Estimated time:** 30–45 min  
**Prerequisite:** complete [Test 1](../test1-definition-based-extraction/README.md) first

---

> [!IMPORTANT]
> **Logical model extraction does not work on the eHealth testserver (HAPI).** This test
> requires the **Tiro testserver**.
>
> **Tiro testserver credentials: TBD - ask the organisers on the day.**
>
> For the technical reason why HAPI cannot do this, see
> [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md).

---

## What this test does

Instead of extracting into standard FHIR resource types (`Observation`, `DiagnosticReport`…), the
Questionnaire items point to elements of a **logical model** - a custom data structure defined as
a FHIR `StructureDefinition` with `kind: logical`. The `$extract` response is a `Binary` resource
whose `.data` field contains base64-encoded JSON conforming to that logical model.

```
QuestionnaireResponse  →  $extract  →  Binary (base64 JSON)  →  decode  →  logical model instance
```

Compared to Test 1:

| | Test 1 | Test 2 |
|--|--------|--------|
| `.definition` targets | Core FHIR resource element (e.g. `Observation#Observation.valueQuantity.value`) | Logical model element (e.g. `HomeHospAssessment#HomeHospAssessment.vitals.temperature`) |
| `Accept` header | `application/fhir+json` | **`application/json`** |
| Response | Bundle of FHIR resources | Binary containing raw JSON |

The `Accept: application/json` header is what signals to the server that a logical model target is
intended. If you forget it, the server tries FHIR resource extraction and fails for logical model
paths.

---

## What you need

### Server

Tiro testserver only. Credentials TBD - ask organisers on the day.

### Sample data

Logical model Questionnaires are in [`data/samples/`](../../data/samples/). The
QuestionnaireResponses from Test 1 are reused directly.

| Scenario | Questionnaire | QuestionnaireResponse |
|----------|---------------|-----------------------|
| OPAT | `homehosp_q_opat_logicalmodel.json` | `homehosp_qr_opat.json` |
| Oncology | `homehosp_q_onco_logicalmodel.json` | `homehosp_qr_onco.json` |

### Logical model StructureDefinitions

Before calling `$extract`, the server must know the logical model. Register the StructureDefinitions:

```bash
bash scripts/curls/upload_logicalmodel_structuredefinitions.sh
```

---

## Step 1 - Call `$extract`

```bash
# OPAT
bash scripts/curls/working_extraction_opat_logicalmodel.sh

# Oncology
bash scripts/curls/working_extraction_onco_logicalmodel.sh
```

Note the `Accept: application/json` header in these scripts - this is what tells the server to
return logical model output rather than a FHIR Bundle.

**Expected response:** a `Binary` resource (`resourceType: "Binary"`) with a `data` field
containing a base64-encoded string.

---

## Step 2 - Decode the Binary

Decode the base64 content to inspect the extracted logical model instance:

```bash
bash scripts/curls/working_extraction_opat_logicalmodel.sh \
  | jq -r '.data' | base64 --decode | jq .
```

The decoded JSON should reflect the structure of the logical model - for example, a
`vitals.temperature` element for the OPAT scenario.

---

## Step 3 - Validate against the logical model

Inspect the decoded JSON and check that the field names and nesting match the element paths
defined in the `StructureDefinition` (`.snapshot.element[*].path`). Each answer in the QR should
have landed in the correct element.

---

## Success criteria

- [ ] `$extract` returns a `Binary` resource (not a Bundle and not an OperationOutcome).
- [ ] `Binary.data` decodes to valid JSON.
- [ ] The decoded JSON element paths match the logical model StructureDefinition.
- [ ] The StructureDefinition was registered on the Tiro server without errors (prerequisite step above).

---

## Troubleshooting

- **Returns a Bundle instead of Binary** → check that `Accept: application/json` is set (not `application/fhir+json`)
- **StructureDefinition not found on server** → run `upload_logicalmodel_structuredefinitions.sh` first; confirm the canonical URL in the Questionnaire matches the registered SD
- **LinkId mismatch errors** → same fix as in Test 1 (see [`docs/fse-faq.md`](../../docs/fse-faq.md))
- **ClassNotFoundException / server error** → this is the known HAPI limitation; you must use the Tiro server (see [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md))

---

## Bonus exercises

These are open-ended exploration prompts - no single right answer, no requirement to finish.

- [Bonus for data providers](bonus-data-provider.md) - implement logical model extraction in Python
- [Bonus for data transporters](bonus-data-transporter.md) - validation and lifecycle for logical model output
- [Bonus for domain experts](bonus-domain-expert.md) - design your own logical model
- [Bonus for developers: fix HAPI](bonus-developers-hapi-fork.md) - prototype a fix for logical model extraction in HAPI upstream
