# sdc-extract

> **BE FHIR-a-thon — Test atelier: From forms to FHIR**
> Definition-based extraction in Belgian healthcare

---

## 🚧 Status — Work in Progress

| # | TODO | Status |
|---|------|--------|
| 1 | Test extraction against the **eHealth test server** | 🔲 pending |
| 2 | Test extraction against the **Tiro test server** | 🔲 pending |
| 3 | Create per-test **tutorial markdown files** in `tutorials/` with step-by-step instructions and references to relevant code and data | 🔲 pending |

---

## Objective

This repository demonstrates and tests **definition-based extraction** — a mechanism in [FHIR SDC (Structured Data Capture)](https://hl7.org/fhir/uv/sdc/) that automatically transforms completed `QuestionnaireResponse` resources into discrete, interoperable FHIR resources without custom per-vendor mapping code.

By linking `Questionnaire` items to `StructureDefinition`s via the `.definition` element, the `$extract` operation converts form responses into Bundles of profiled FHIR resources — making the Questionnaire both the form specification and the extraction specification.

---

## Scope & Use Cases

Two Belgian use cases anchor the atelier:

- **Thuishospitalisatie**: A home care nurse documents an OPAT treatment or antitumoral therapy. Extracted resources (`Observation`, `DiagnosticReport`, `MedicationStatement`) flow into the patient record. Directly linked to the FOD-funded thuishospitalisatie pilot (UZ Leuven, Corilus, Wit-Gele Kruis, nexuzhealth — running since January 2026).
- **Registry population**: A clinician submits a QERMID implant registration or cancer notification (BCR). Output is validated against registry `StructureDefinition`s and forwarded to the receiving infrastructure. Relevant for Sciensano/HealthData.be (HD4DP), Belgian Cancer Registry, and BSP.

---

## Roles in the Data Flow

| Role | Actor | Responsibility | Partner |
|------|-------|----------------|---------|
| Domain expert | Registries & institutions | Publish StructureDefinitions (profiles / logical models); co-author Questionnaire `.definition` links | UZ Leuven |
| Data provider | EHR vendors, care software | Render Questionnaire, capture QuestionnaireResponse, call `$extract` (shared API available — no own implementation required) | Tiro.health, nexuzhealth |
| Data transport | FHIR server infrastructure | Receive Transaction Bundle, validate against StructureDefinitions, expose resources via standard FHIR search | Amaron, nexuzhealth, Axian |

---

## Test Scenarios

### Test 1 — Definition-based Extraction to FHIR Resources *(core)*

**Objective**: Transform a completed `QuestionnaireResponse` into discrete, searchable FHIR resources using the `.definition` element and the `$extract` operation.

1. **Setup**: Participants receive a FHIR `Questionnaire` where items are linked to profiled FHIR resources via `.definition` (e.g., items mapping to elements of an `Observation`, `Condition`, or `Procedure` profile).
2. **Input**: A completed `QuestionnaireResponse` (e.g., a home care nursing assessment or a registry submission) — see [`data/samples/`](data/samples/).
3. **The Challenge**:
   - Call the `$extract` operation (using Tiro.health's public API or a participant's own implementation) to transform the `QuestionnaireResponse` into a FHIR Transaction Bundle.
   - Verify that fixed values, slicing, and patterns defined in the target profiles are correctly applied in the extracted resources.
4. **Success Criteria**: The generated Bundle is successfully POSTed to the eHealth Test Server, and individual resources can be retrieved via standard FHIR search (e.g., `GET /Observation?patient=[ID]&code=[LOINC]`).

### Test 2 — Extraction to Logical Models *(advanced)*

**Objective**: Extract data from a `QuestionnaireResponse` into a custom data model defined as a FHIR logical model (`StructureDefinition` with `kind: logical`).

1. **Setup**: Participants receive (or define) a logical model representing a registry-specific data structure, and a `Questionnaire` with `.definition` elements pointing to paths in that logical model.
2. **Input**: A completed `QuestionnaireResponse` for the registry form.
3. **The Challenge**:
   - Call the `$extract` operation with an `Accept: application/json` header to trigger logical model extraction.
   - Validate that the returned `Binary` resource contains JSON that conforms to the logical model structure.
4. **Success Criteria**: The extracted JSON matches the logical model's element structure and can be consumed by a registry-specific system.

### Test 3 — Pre-population *(bonus, if time permits)*

**Objective**: Automatically populate a `Questionnaire` with existing patient data to reduce clinician data entry.

1. **Source Data**: Participants use the eHealth Test Server or their own FHIR server as the data source.
2. **The Challenge**: Use SDC expressions such as `initialExpression` or `launchContext` to define how existing data should be fetched and mapped to `Questionnaire` items.
3. **Success Criteria**: A `QuestionnaireResponse` is generated in `"in-progress"` status with fields correctly pre-filled from existing patient data.

---

## Repository Structure

```
sdc-extract/
├── apps/                   # Q2R Mapper — Angular + FastAPI app for annotating
│   ├── web/                #   Questionnaires and running $extract
│   └── api/
├── data/
│   └── samples/            # Sample Questionnaire and QuestionnaireResponse files
│       ├── homehosp_q_onco_definitions.json
│       ├── homehosp_q_opat_definitions.json
│       ├── homehosp_qr_onco.json
│       └── homehosp_qr_opat.json
├── scripts/
│   └── curls/              # Shell scripts for calling the eHealth test server
│       ├── extract_questionnaireresponse_ehtestserver.sh
│       ├── get_questionnaire_ehtestserver.sh
│       └── post_questionnaire_ehtestserver.sh
└── tutorials/              # Step-by-step test guides (to be created — see TODOs)
```

---

## FSE (Frequent stupid errors) to avoid

### `IllegalArgumentException: Unable to retrieve Questionnaire code map for Observation based extraction`
This error means HAPI's `$extract` tried to fall through to **observation-based** extraction (the legacy `sdc-questionnaire-observationLinkPeriod` / "code map" path) instead of the definition-based path you intended. To force definition-based processing, ensure **at least one leaf item carries `sdc-questionnaire-definitionExtract`** with a target `valueCanonical` (e.g. `http://hl7.org/fhir/StructureDefinition/Observation`). It does *not* need to be on every single leaf — `inline-q` in `scripts/curls/working-extraction.sh` is a working example with the extension only on the leaves that should produce values.

> ℹ️ Earlier wisdom suggested that having `code` elements on leaves was forbidden under definition-based extraction. That turns out **not** to be the case — the SDC code path doesn't reject it. The leaf `code` is simply redundant: under definition-based extraction the extracted `Observation.code` comes from a `sdc-questionnaire-definitionExtractValue` fixed-value extension on the **group**, not from `Questionnaire.item.code`.

### `NullPointerException` deep in `ItemPair.getItem(...)`
Symptom: `$extract` returns 500 with a stack trace pointing at `org.opencds.cqf.fhir.cr.questionnaireresponse.extract.ProcessDefinitionItem` (or a similarly-named CR class), with the NPE on `ItemPair.getItem()`.

Real cause: **a linkId in the `QuestionnaireResponse` does not resolve to any item in the `Questionnaire`.** HAPI's CR builds an `ItemPair` for every QR leaf, and if it can't find the matching Q item, the pair's `getItem()` returns null, and the next access throws.

> 🔍 This is the actual reason the published OPAT sample previously failed — the standalone Q used long mangled linkIds (e.g. `87Zijneropmerkingenofbezorgdhedenomtrent…`) while the QR used short ones (e.g. `A1_Bewaring`). Only 10 of 61 QR linkIds resolved. The "contained-Q" workaround appeared to fix it only because the inline-Q in `working-extraction.sh` had been hand-aligned with the QR linkIds — not because containment bypasses any HAPI bug.

**How to fix:** make sure every `QuestionnaireResponse.item.linkId` (recursively) is also present in the referenced `Questionnaire`. Diff the linkId sets first whenever you see this NPE.

### Extracted `Observation`s have an empty `code`
`status`, `category`, `subject`, `value[x]` come out fine but `Observation.code` is `{}`. That's not a bug — the Q is missing a `sdc-questionnaire-definitionExtractValue` for `Observation.code` on the group. Add one with a coded fixed value, e.g.:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
  "extension": [
    {"url": "definition",
     "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.code"},
    {"url": "fixed-value",
     "valueCodeableConcept": {
       "coding": [{"system": "http://loinc.org", "code": "8716-3", "display": "Vital signs"}]
     }}
  ]
}
```

### `valueExpression` on `definitionExtract` / `definitionExtractValue` is silently ignored
The SDC IG documents both `valueCanonical` and `valueExpression` as permitted forms. HAPI's CR reads these primitives via `IPrimitiveType` and only the canonical/URI forms parse — `valueExpression` is silently dropped, which makes the dispatch fall through to observation-based extraction (and you end up at the first FSE in this list). **Use `valueCanonical` (for `definitionExtract`) and `valueUri` (for the `definition` sub-extension), not `valueExpression`, until HAPI's CR adds expression support.**

## Contact

- [axel.vanraes@tiro.health](mailto:axel.vanraes@tiro.health)
- [annabel.dompas@uzleuven.be](mailto:annabel.dompas@uzleuven.be)
