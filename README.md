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
- `Failed to call access method: java.lang.IllegalArgumentException: Unable to retrieve Questionnaire code map for Observation based extraction`
  - You need sdc-questionnaire-definitionExtract and a definition attribute on *every single leaf item*, not just the one you want to extract. Otherwise the server thinks you're using `sdc-questionnaire-observationExtract`.
  - Apparently it is also not allowed to have code elements on the leaves themselves. With definition-based extraction, the code on the item is redundant anyway - the Observation.code is supposed to come from your `sdc-questionnaire-definitionExtractValue` fixed-value extensions on the group.
  - This is a known HAPI FHIR bug. In HAPI's SDC implementation, $extract checks for the presence of sdc-questionnaire-definitionExtract but still routes through the observation code map builder first in certain versions. The fix is to inline the Questionnaire into the QuestionnaireResponse request using the contained resource pattern, which bypasses the server's Questionnaire lookup entirely and forces definition-based processing.
    Try sending the QuestionnaireResponse with the Questionnaire contained inside it, and add the questionnaire reference as a fragment
    --> this does work -_-
  
## Contact

- [axel.vanraes@tiro.health](mailto:axel.vanraes@tiro.health)
- [annabel.dompas@uzleuven.be](mailto:annabel.dompas@uzleuven.be)
