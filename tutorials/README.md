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

| # | Test | What it produces | Server requirement |
|---|------|------------------|--------------------|
| [Test 1](test1-definition-based-extraction/README.md) | Definition-based extraction to FHIR resources | Bundle of `Observation`, `DiagnosticReport`, … | eHealth testserver **or** Tiro testserver |
| [Test 2](test2-logical-model-extraction/README.md) | Extraction to a logical model | Raw JSON (or `Binary` envelope) conforming to the logical model | Tiro testserver **only** |
| [Test 3](test3-pre-population/README.md) | Pre-population | Pre-filled `QuestionnaireResponse` | eHealth testserver (work in progress) |

Start with **Test 1**. Test 2 builds directly on it.

---

## Servers

### eHealth testserver (HAPI)

Base URL: `https://hapi.fhir-testserver.be/fhir/{TENANT_ID}`  
Authentication: `?api_key={API_KEY}` query parameter

Credentials are provided at the hackathon. Copy them into a `.env` file at the repository root —
the `*_ehtestserver.sh` helper scripts and the eHealth path of Test 1 read from it automatically.

Supports: Test 1 ✅ | Test 2 ❌ out of the box — logical-model extraction fails on an unpatched
HAPI (see [the root-cause note](../docs/hapi-extract-logical-model-root-cause.md)). A patch is
sketched in the [HAPI fork bonus](test2-logical-model-extraction/bonus-developers-hapi-fork.md)
and the accompanying [fork guide](../docs/hapi-extract-logical-model-fork-guide.md) — untested,
but the entry point if you want to take it on.

### Tiro testserver

The reference implementation in [`apps/tiro_sdc_extract/`](../apps/tiro_sdc_extract/). Run it
locally — no credentials needed:

```bash
cd apps/tiro_sdc_extract
uv sync           # install all dependencies from pyproject.toml / uv.lock
uv run fastapi dev
```

Base URL: `http://localhost:8000/api/v1`. Override with `TIRO_BASE_URL` if you've deployed the
server elsewhere.

See [`apps/tiro_sdc_extract/README.md`](../apps/tiro_sdc_extract/README.md) for full run instructions,
configuration (e.g. `STRUCTURE_DEFINITIONS_DIR`), API details, and a note on running the server in
the background.

Supports: Test 1 ✅ | Test 2 ✅

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
