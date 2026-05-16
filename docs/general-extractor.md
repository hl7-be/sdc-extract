# General Extractor — Python implementation for FHIR facade environments

## When to use this

The `$extract` operation is a server-side feature. If your FHIR infrastructure does not support
it natively — for example:

- **Google Healthcare FHIR API** — does not expose `$extract`
- **Custom FHIR facade** — a thin translation layer over a proprietary database
- **Local testing** — you have a Questionnaire and a QuestionnaireResponse and want to see
  extraction output without a server

— then the Python extractor in this repository provides a client-side implementation of
definition-based extraction.

---

## Where it lives

```
apps/Q2Rmapper/api/src/core/extractor.py
```

The extractor is part of the Q2R Mapper application (a FastAPI backend + Angular frontend for
authoring Questionnaire definitions), but it is a self-contained module with no dependency on
the web framework. It can be imported and run independently.

---

## What it does

The `DefinitionBasedExtractor` class takes a `Questionnaire` and a `QuestionnaireResponse` (both
as Python dicts) and returns a FHIR transaction Bundle and a list of any non-fatal errors:

```python
from apps.Q2Rmapper.api.src.core.extractor import DefinitionBasedExtractor
import json

with open("data/samples/homehosp_q_opat_definitions.json") as f:
    questionnaire = json.load(f)
with open("data/samples/homehosp_qr_opat.json") as f:
    questionnaire_response = json.load(f)

extractor = DefinitionBasedExtractor(questionnaire, questionnaire_response)
bundle, errors = extractor.extract()
# bundle  — FHIR transaction Bundle ready to POST to a FHIR server
# errors  — list of human-readable strings for problems found (non-fatal; bundle still returned)
```

The algorithm:

1. Builds a flat index of `linkId → Questionnaire item` from the Questionnaire tree.
2. Walks the QuestionnaireResponse items against that index.
3. For each item group marked with `sdc-questionnaire-definitionExtract`, seeds a resource
   skeleton of the target type.
4. Applies fixed values from `sdc-questionnaire-definitionExtractValue` extensions on the group.
5. Applies answer values from leaf items, writing to the element path from `.definition`.
6. Filters out resources that are missing required fields (`code` for Observation,
   DiagnosticReport, and Procedure).
7. Wraps surviving resources in a FHIR transaction Bundle.

Errors are non-fatal by default: a problematic item is skipped and the error is recorded rather
than aborting the whole extraction.

---

## Limitations compared to server-side `$extract`

| Feature | Python extractor | Server `$extract` |
|---------|-----------------|-------------------|
| Definition-based extraction (FHIR resources) | ✅ | ✅ |
| Logical model extraction | ❌ not implemented | ✅ Tiro server only (`apps/tiro_sdc_extract/`) |
| FHIRPath evaluation | ❌ | ✅ |
| Terminology validation | ❌ | Depends on server |
| Profile validation on output | ❌ | Depends on server |
| No server required | ✅ | ❌ |

---

## Testing locally

### Option 1 — Add a `__main__` block

Add the following at the bottom of `extractor.py` and run the file directly:

```python
if __name__ == "__main__":
    import json, sys

    q_path = sys.argv[1] if len(sys.argv) > 1 else "data/samples/homehosp_q_opat_definitions.json"
    qr_path = sys.argv[2] if len(sys.argv) > 2 else "data/samples/homehosp_qr_opat.json"

    with open(q_path) as f:
        q = json.load(f)
    with open(qr_path) as f:
        qr = json.load(f)

    extractor = DefinitionBasedExtractor(q, qr)
    bundle, errors = extractor.extract()

    print(json.dumps(bundle, indent=2))
    if errors:
        print("\nErrors:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
```

Then run from the repository root:

```bash
python apps/Q2Rmapper/api/src/core/extractor.py \
  data/samples/homehosp_q_opat_definitions.json \
  data/samples/homehosp_qr_opat.json
```

### Option 2 — Copy the file

Copy `extractor.py` into your own project. Its only imports are from the standard library
(`logging`, `typing`, `uuid`) — no third-party dependencies. Adjust the import paths if needed.

---

## Posting the output to a FHIR server

The Bundle returned by `extractor.extract()` is a standard FHIR transaction Bundle. POST it to
any server that accepts transaction Bundles:

```python
import requests

response = requests.post(
    "http://your-fhir-server/fhir",
    json=bundle,
    headers={"Content-Type": "application/fhir+json"},
)
response.raise_for_status()
```

For the Google Healthcare FHIR API, use the `google-cloud-healthcare` client library or the REST
API with OAuth2 credentials.

---

## Relationship to the Q2R Mapper application

The Q2R Mapper application (`apps/Q2Rmapper/`) exposes this extractor via a FastAPI endpoint
(`POST /extract`). When the full application is running, the API accepts a Questionnaire and
QuestionnaireResponse as JSON, runs `DefinitionBasedExtractor`, and returns the Bundle — the same
logic as running locally, wrapped in a web service.

If you are building a FHIR facade and want extraction as a microservice, the Q2R Mapper's FastAPI
layer is a reasonable starting point: it handles request parsing, error serialisation, and HTTP
plumbing, while the core extraction logic stays in `extractor.py`.
