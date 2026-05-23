# sdc-extract

> **BE FHIR-a-thon - Test atelier: From forms to FHIR**
> Definition-based extraction in Belgian healthcare
> 
> By Tiro.health and UZ Leuven

---

## Objective

This repository demonstrates and tests **definition-based extraction** - a mechanism in
[FHIR SDC (Structured Data Capture)](https://hl7.org/fhir/uv/sdc/) that automatically transforms completed
`QuestionnaireResponse` resources into discrete, interoperable FHIR resources without custom per-vendor mapping code.

By linking `Questionnaire` items to `StructureDefinition`s via the `.definition` element, the `$extract` operation
converts form responses into Bundles of profiled FHIR resources - making the Questionnaire both the form specification
and the extraction specification.

> **New to FHIR SDC?** Read [`docs/sdc-overview.md`](docs/sdc-overview.md) first — a short primer on the core
> resources, the `$populate` / `$extract` operations, and the bidirectional `Questionnaire.item.definition` link
> that ties them together.

---

## Scope & Use Cases

Two Belgian use cases anchor the atelier:

- **Home hospitalization:** a home care nurse documents an OPAT treatment or antitumoral therapy. Extracted resources
  (`Observation`, `DiagnosticReport`, `MedicationStatement`) flow into the patient record. Directly linked to the
  FOD-funded home hospitalization pilot (UZ Leuven, Wit-Gele Kruis, Corilus, nexuzhealth - running since January 2026).
- **Registry population:** a clinician submits a QERMID implant registration or cancer notification (BCR). Output is
  validated against registry `StructureDefinition`s and forwarded to the receiving infrastructure. Relevant for Tiro.health and for people involved in 
  Sciensano/HealthData.be (HD4DP), Belgian Cancer Registry and other registries

---

## Roles in the Data Flow

Each test scenario is a shared exercise - roles contribute different inputs to the same scenario rather than running
separate tracks in parallel.

| Role           | Actor                      | Contribution to the tests                                                                                                          | Partner                    |
|----------------|----------------------------|------------------------------------------------------------------------------------------------------------------------------------|----------------------------|
| Domain expert  | Registries & institutions  | Publish `StructureDefinition`s (profiles / logical models); co-author `Questionnaire` `.definition` links and extraction metadata | UZ Leuven                  |
| Data provider  | EHR vendors, care software | Render the `Questionnaire`, capture the `QuestionnaireResponse`, call `$extract` (shared API available - no own server required)  | Tiro.health, nexuzhealth   |
| Data transport | FHIR server infrastructure | Receive the transaction `Bundle`, validate against `StructureDefinition`s, expose resources via standard FHIR search              | Amaron, nexuzhealth, Axian |

A single scenario run therefore requires at minimum: a `Questionnaire` + `StructureDefinition` (domain expert), a
`QuestionnaireResponse` (data provider), and a receiving FHIR server (data transport). Sample files for all three are
provided in `data/` and `scripts/` so any role can participate even without the others present on the day.

---

## Test Scenarios

> **TODO:** Detailed test scenario guides are under development in a separate branch. The table below lists the planned
> scenarios; tutorial folder links will become active once that work is merged.

| # | Title                                         | Difficulty |
|---|-----------------------------------------------|------------|
| 1 | Definition-based Extraction to FHIR Resources | Core       |
| 2 | Extraction to Logical Models                  | Advanced   |
| 3 | Pre-population                                | Bonus      |

---

## Repository Structure

```
sdc-extract/
├── apps/        
│   ├── Q2Rmapper/          # Interactive annotation tool (Angular + FastAPI)
│   │   ├── web/            #   Angular 18 frontend
│   │   └── api/            #   FastAPI backend (questionnaire mapping + preview extraction)
│   └── tiro_sdc_extract/   # Standalone FHIR SDC $extract service (Python)
├── data/        # Sample Questionnaire and QuestionnaireResponse files
├── docs/        # Investigation notes, troubleshooting, and design documents
├── scripts/     # Shell scripts for calling FHIR servers
└── tutorials/   # Step-by-step test guides (in progress)
```

### Registry logical models

The Belgian Cancer Registry (BCR) and QERMID `StructureDefinition`s, `CodeSystem`s, and
`ValueSet`s are not bundled — fetch them on demand:

```bash
bash scripts/download_bcr_definitions.sh      # → data/bcr/
bash scripts/download_qermid_definitions.sh   # → data/qermid/
```

Both scripts pull `definitions.json.zip` from the published IG. Outputs are gitignored. Re-run
with `--force` to bypass the conditional GET.

---

## Troubleshooting

Common errors and workarounds are collected in [`docs/fse-faq.md`](docs/fse-faq.md).

For the known limitation with logical-model extraction targets on HAPI, see:
- [`docs/hapi-extract-logical-model-root-cause.md`](docs/hapi-extract-logical-model-root-cause.md) - source-level root cause
- [`docs/hapi-extract-logical-model-fork-guide.md`](docs/hapi-extract-logical-model-fork-guide.md) - forking approach (untested)

---

## Contact & partners

Partners of this FHIR-a-thon test-atelier are Axians, Amaron, Intersystems and Nexuzhealth.

Want to partner with us? Contact us at 

- [axel.vanraes@tiro.health](mailto:axel.vanraes@tiro.health)
- [annabel.dompas@uzleuven.be](mailto:annabel.dompas@uzleuven.be)
