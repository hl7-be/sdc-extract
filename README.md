# sdc-extract

> **BE FHIR-a-thon — Test atelier: From forms to FHIR**
> Definition-based extraction in Belgian healthcare

---

## 🚧 Status — Work in Progress

| # | TODO                                                                                                  | 
|---|-------------------------------------------------------------------------------------------------------|
| 1 | Test extraction against the **Tiro test server**                                                      | 
| 2 | Axel: test3 pre-population verder uitschrijven                                                        |  
| 3 | Annabel: Update apps for correct mapping of definitions                                               | 
| 4 | Annabel: Logical models van opat en onco                                                              | 
| 5 | Axel: logical models en testscripts voor kankerregistratie                                            | 
| 6 | ? nog een extra testscenario toevoegen om zelf definities te inputten? voor de echte advanced mensen? | 
| 7 | ? kleine sdc quiz toevoegen bij tutorials?                                                            | 

---

## Objective

This repository demonstrates and tests **definition-based extraction** — a mechanism
in [FHIR SDC (Structured Data Capture)](https://hl7.org/fhir/uv/sdc/) that automatically transforms completed
`QuestionnaireResponse` resources into discrete, interoperable FHIR resources without custom per-vendor mapping code.

By linking `Questionnaire` items to `StructureDefinition`s via the `.definition` element, the `$extract` operation
converts form responses into Bundles of profiled FHIR resources — making the Questionnaire both the form specification
and the extraction specification.

---

## Scope & Use Cases

Two Belgian use cases anchor the atelier:

- **Thuishospitalisatie**: A home care nurse documents an OPAT treatment or antitumoral therapy. Extracted resources (
  `Observation`, `DiagnosticReport`, `MedicationStatement`) flow into the patient record. Directly linked to the
  FOD-funded thuishospitalisatie pilot (UZ Leuven, Corilus, Wit-Gele Kruis, nexuzhealth — running since January 2026).
- **Registry population**: A clinician submits a QERMID implant registration or cancer notification (BCR). Output is
  validated against registry `StructureDefinition`s and forwarded to the receiving infrastructure. Relevant for
  Sciensano/HealthData.be (HD4DP), Belgian Cancer Registry, and BSP.

---

## Roles in the Data Flow

| Role           | Actor                      | Responsibility                                                                                                               | Partner                    |
|----------------|----------------------------|------------------------------------------------------------------------------------------------------------------------------|----------------------------|
| Domain expert  | Registries & institutions  | Publish StructureDefinitions (profiles / logical models); co-author Questionnaire `.definition` links                        | UZ Leuven                  |
| Data provider  | EHR vendors, care software | Render Questionnaire, capture QuestionnaireResponse, call `$extract` (shared API available — no own implementation required) | Tiro.health, nexuzhealth   |
| Data transport | FHIR server infrastructure | Receive Transaction Bundle, validate against StructureDefinitions, expose resources via standard FHIR search                 | Amaron, nexuzhealth, Axian |

---

## Test Scenarios

| # | Title                                         | Difficulty | Tutorial                                                                                       |
|---|-----------------------------------------------|------------|------------------------------------------------------------------------------------------------|
| 1 | Definition-based Extraction to FHIR Resources | Core       | [`tutorials/test1-definition-based-extraction/`](tutorials/test1-definition-based-extraction/) |
| 2 | Extraction to Logical Models                  | Advanced   | [`tutorials/test2-logical-model-extraction/`](tutorials/test2-logical-model-extraction/)       |
| 3 | Pre-population                                | Bonus      | [`tutorials/test3-pre-population/`](tutorials/test3-pre-population/)                           |

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
│       ├── working_extraction_opat.sh             # Test 1 — $extract OPAT (FHIR resources)
│       ├── working_extraction_onco.sh             # Test 1 — $extract Oncology (FHIR resources)
│       ├── working_extraction_opat_logicalmodel.sh  # Test 2 — $extract OPAT (logical model)
│       ├── working_extraction_onco_logicalmodel.sh  # Test 2 — $extract Oncology (logical model)
│       ├── extract_questionnaireresponse_ehtestserver.sh
│       ├── get_questionnaire_ehtestserver.sh
│       └── post_questionnaire_ehtestserver.sh
└── tutorials/              # Step-by-step test guides
    ├── test1-definition-based-extraction/
    ├── test2-logical-model-extraction/
    └── test3-pre-population/
```

---

## FSE (Frequent stupid errors) to avoid

### `IllegalArgumentException: Unable to retrieve Questionnaire code map for Observation based extraction`

This error means HAPI's `$extract` tried to fall through to **observation-based** extraction (the legacy
`sdc-questionnaire-observationLinkPeriod` / "code map" path) instead of the definition-based path you intended. To force
definition-based processing, ensure **at least one leaf item carries `sdc-questionnaire-definitionExtract`** with a
target `valueCanonical` (e.g. `http://hl7.org/fhir/StructureDefinition/Observation`). It does *not* need to be on every
single leaf — the Questionnaire in `data/samples/homehosp_q_opat_definitions.json` and the two-step
`scripts/curls/working-extraction.sh` are working examples with the extension only on the group items that should
produce values.

> ℹ️ Earlier wisdom suggested that having `code` elements on leaves was forbidden under definition-based extraction.
> That turns out **not** to be the case — the SDC code path doesn't reject it. The leaf `code` is simply redundant:under
> definition-based extraction the extracted `Observation.code` comes from a `sdc-questionnaire-definitionExtractValue`
> fixed-value extension on the **group**, not from `Questionnaire.item.code`.

### `NullPointerException` deep in `ItemPair.getItem(...)`

Symptom: `$extract` returns 500 with a stack trace pointing at
`org.opencds.cqf.fhir.cr.questionnaireresponse.extract.ProcessDefinitionItem` (or a similarly-named CR class), with the
NPE on `ItemPair.getItem()`.

Real cause: **a linkId in the `QuestionnaireResponse` does not resolve to any item in the `Questionnaire`.** HAPI's CR
builds an `ItemPair` for every QR leaf, and if it can't find the matching Q item, the pair's `getItem()` returns null,
and the next access throws.

> 🔍 This can happen with any Questionnaire/QuestionnaireResponse pair where the linkId sets diverge — for example, when
> a Q was regenerated or hand-edited and the QR was authored against an earlier version. Only the linkIds that exist in
> both resources will resolve correctly; any QR linkId absent from the Q will trigger this NPE.

**How to fix:** make sure every `QuestionnaireResponse.item.linkId` (recursively) is also present in the referenced
`Questionnaire`. Diff the linkId sets first whenever you see this NPE.

### Extracted `Observation`s have an empty `code`

`status`, `category`, `subject`, `value[x]` come out fine but `Observation.code` is `{}`. That's not a bug — the Q is
missing a `sdc-questionnaire-definitionExtractValue` for `Observation.code` on the group. Add one with a coded fixed
value, e.g.:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
  "extension": [
    {
      "url": "definition",
      "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.code"
    },
    {
      "url": "fixed-value",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8716-3",
            "display": "Vital signs"
          }
        ]
      }
    }
  ]
}
```

### `valueExpression` on `definitionExtract` / `definitionExtractValue` is silently ignored

The SDC IG documents both `valueCanonical` and `valueExpression` as permitted forms. HAPI's CR reads these primitives
via `IPrimitiveType` and only the canonical/URI forms parse — `valueExpression` is silently dropped, which makes the
dispatch fall through to observation-based extraction (and you end up at the first FSE in this list). *
*Use `valueCanonical` (for `definitionExtract`) and `valueUri` (for the `definition` sub-extension),
not `valueExpression`, until HAPI's CR adds expression support.**

## Contact

- [axel.vanraes@tiro.health](mailto:axel.vanraes@tiro.health)
- [annabel.dompas@uzleuven.be](mailto:annabel.dompas@uzleuven.be)
