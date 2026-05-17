# From Forms to FHIR - SDC Extract Test Atelier

This atelier explores **definition-based extraction**: a mechanism in the FHIR SDC specification
that automatically transforms a completed `QuestionnaireResponse` into discrete FHIR resources -
without writing custom mapping code per vendor or per form.

A `Questionnaire` item carries a `.definition` element pointing to a FHIR StructureDefinition
element path. When a clinician fills in the form and the `$extract` operation is called, the server
walks those links and assembles a Bundle of profiled FHIR resources - or, in the logical model
variant, a Binary containing structured JSON.

No prior experience with SDC extract is assumed. If you are unfamiliar with FHIR itself, the
[FAQ](../docs/fse-faq.md) and test READMEs contain enough context to follow along.

---

## Tests

| # | Test | What it produces |
|---|------|------------------|
| [Test 1](test1-definition-based-extraction/README.md) | Definition-based extraction to FHIR resources | Bundle of `Observation`, `DiagnosticReport`, … |
| [Test 2](test2-logical-model-extraction/README.md) | Extraction to a logical model | Raw JSON (or a `Binary` envelope) conforming to the logical model |
| [Test 3](test3-pre-population/README.md) | Pre-population | Pre-filled `QuestionnaireResponse` (work in progress) |

Start with **Test 1**. Test 2 builds directly on it.

---

## Server

Both tests run against the **Tiro testserver** — the reference implementation in
[`apps/tiro_sdc_extract/`](../apps/tiro_sdc_extract/). No credentials are required.

```bash
cd apps/tiro_sdc_extract
uv sync
uv run fastapi dev src/server/app.py
```

Base URL: `http://localhost:8000/api/v2`

The curl scripts under [`scripts/curls/`](../scripts/curls/) default to that URL. Override with
`TIRO_BASE_URL` (in your environment or `.env`) if you've deployed the server elsewhere.

Supports: Test 1 ✅ | Test 2 ✅ | Test 3 ❌ (in progress)

> Logical-model extraction is the reason we run our own server: the public HAPI testserver
> cannot do it — see [the root-cause note](../docs/hapi-extract-logical-model-root-cause.md).

---

## Bonus exercises

Each test README links to per-role bonus files. These are **open-ended exploration prompts**, not
step-by-step checklists. There is no single correct answer and no requirement to finish them - they
are starting points for discussion and experimentation.

The roles below are a loose guide; feel free to explore across them:

| Role | What the bonus exercises explore |
|------|----------------------------------|
| **Data provider** (EHR vendors, care software) | Using and improving the Python extractor for environments without a native `$extract` server |
| **Data transporter** (FHIR server infrastructure) | Validation, idempotency, and lifecycle management of extracted resources |
| **Domain expert** (registries, care institutions) | Authoring your own definitions and logical models; understanding the Q2R Mapper tool |

---

## Other resources in this repository

- [`docs/fse-faq.md`](../docs/fse-faq.md) - common errors and fixes
- [`docs/sdc-extract-integrity-and-lifecycle.md`](../docs/sdc-extract-integrity-and-lifecycle.md) - validation and lifecycle design
- [`docs/hapi-extract-logical-model-root-cause.md`](../docs/hapi-extract-logical-model-root-cause.md) - why logical model extraction fails on HAPI
- [`docs/hapi-extract-logical-model-fork-guide.md`](../docs/hapi-extract-logical-model-fork-guide.md) - design sketch for fixing it (untested)
- [`docs/general-extractor.md`](../docs/general-extractor.md) - standalone Python extractor for FHIR facade / Google Healthcare environments
- [`data/samples/`](../data/samples/) - all sample Questionnaire, QuestionnaireResponse, and StructureDefinition files
- [`scripts/curls/`](../scripts/curls/) - ready-made shell scripts for all `$extract` calls
