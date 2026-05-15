# Test 3 - Pre-population

> [!WARNING]
> ## Work in progress
>
> Definition-based pre-population (using `.definition` links rather than FHIRPath expressions,
> analogous to how Test 1 and Test 2 work for extraction) is **not yet documented or tested** in
> this repository.
>
> **Want to help shape this test? Contribute to [GitHub issue #8](https://github.com/hl7-be/sdc-extract/issues/8).**

---

**Difficulty:** Bonus  
**Estimated time:** 30–45 min (if time permits)

---

## What this test does

Pre-population uses the `$populate` operation to automatically fill in a `QuestionnaireResponse`
from existing patient data on a FHIR server. A clinician opens a form and fields are already
filled with the most recent recorded values - they only need to confirm or correct them before
submitting.

```
Patient data on server  →  $populate  →  pre-filled QuestionnaireResponse (in-progress)
                                                   ↓
                                    Clinician completes remaining items
                                                   ↓
                                           $extract (Test 1)
```

---

## What is documented here: expression-based pre-population

The current sample Questionnaires do not yet carry pre-population extensions. The mechanism that
works today on the eHealth testserver uses `initialExpression` - a FHIRPath expression embedded
in each Questionnaire item that the server evaluates at populate-time.

### Key extensions

| Extension | Where | What it does |
|-----------|-------|--------------|
| `sdc-questionnaire-launchContext` | Questionnaire root | Declares named variables (`patient`, `user`, `encounter`) the app injects at launch |
| `sdc-questionnaire-initialExpression` | Individual item | FHIRPath expression evaluated at populate-time; result becomes the initial answer |
| `sdc-questionnaire-sourceQueries` | Questionnaire root | Named FHIR queries whose results are available to expressions |

### Adding `initialExpression` to an item

```json
{
  "linkId": "B1_Temperatuur",
  "text": "Lichaamstemperatuur:",
  "type": "decimal",
  "extension": [
    {
      "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression",
      "valueExpression": {
        "language": "text/fhirpath",
        "expression": "%patient.id.resolve().ofType(Observation).where(code.coding.where(code='8310-5')).value.value"
      }
    }
  ]
}
```

Add a `launchContext` at the Questionnaire root to declare the `patient` variable:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext",
  "extension": [
    {"url": "name", "valueCoding": {"system": "http://hl7.org/fhir/uv/sdc/CodeSystem/launchContext", "code": "patient"}},
    {"url": "type", "valueCode": "Patient"},
    {"url": "description", "valueString": "The patient whose record is being reviewed"}
  ]
}
```

---

## Step 1 - Ensure patient data exists on the server

The eHealth testserver has existing patients with Observation resources. Use one of those, or run
Test 1 first to POST observations for the sample patient and then use those as the pre-population
source.

Sample patient used in the QR files: `Patient/ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a`

---

## Step 2 - Call `$populate`

```bash
curl --location \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire/\$populate?api_key=${API_KEY}" \
  --header 'Accept: application/fhir+json' \
  --header 'Content-Type: application/fhir+json' \
  --data '{
    "resourceType": "Parameters",
    "parameter": [
      {"name": "questionnaire", "resource": <your-questionnaire-with-initialExpression>},
      {"name": "subject", "valueReference": {"reference": "Patient/ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a"}}
    ]
  }'
```

**Expected response:** a `QuestionnaireResponse` with `status: "in-progress"` and at least some
items pre-filled with data from the server.

---

## Step 3 - Complete and extract

Inspect the pre-filled QuestionnaireResponse. Complete the remaining items manually, then call
`$extract` from Test 1 on the completed QR to produce final FHIR resources.

---

## Success criteria

- [ ] `$populate` returns a `QuestionnaireResponse`, not an `OperationOutcome`.
- [ ] `QuestionnaireResponse.status = "in-progress"`.
- [ ] At least one item is pre-filled with data retrieved from the FHIR server.
- [ ] Pre-filled values match what was previously stored (verify with `GET /Observation?patient=<id>&code=<loinc>`).
- [ ] Completing and extracting the pre-filled QR still produces a valid Bundle.

---

## What's next: definition-based pre-population

The SDC spec describes pre-population using `.definition` links (the same links used in Test 1 and
Test 2 for extraction). In theory, a server could read those links to know which FHIR elements to
look up when pre-filling - without requiring FHIRPath expressions.

This direction is not yet documented or tested here.

**Want to help? See [GitHub issue #8](https://github.com/hl7-be/sdc-extract/issues/8).**

To share what you tried or designed during the atelier, copy `submissions/TEMPLATE.md`, rename it
to `{your-github-handle-or-team}.md`, and open a pull request. See
[`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
