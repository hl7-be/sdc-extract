# Test 3 — Pre-population

**Difficulty:** Bonus  
**Estimated time:** 30–45 min (if time permits)

---

## Objective

Automatically populate a `Questionnaire` with existing patient data from a FHIR server,
reducing clinician data entry. The result is a `QuestionnaireResponse` in `"in-progress"` status
with fields pre-filled from previously recorded FHIR resources.

---

## Background

Pre-population uses the `$populate` operation defined in
[SDC](https://hl7.org/fhir/uv/sdc/OperationDefinition-Questionnaire-populate.html). The server
evaluates FHIRPath or CQL expressions embedded in the `Questionnaire` and fetches matching
data from a FHIR server to fill in answers.

The two main SDC mechanisms for declaring how data should be fetched:

| Mechanism           | Element                                                          | What it does                                                                                                |
|---------------------|------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `launchContext`     | `sdc-questionnaire-launchContext` extension on the Questionnaire | Declares named variables (`patient`, `user`, `encounter`) that the rendering app must inject at launch time |
| `initialExpression` | `sdc-questionnaire-initialExpression` extension on an item       | FHIRPath expression evaluated at populate-time; result becomes the initial answer for that item             |
| `sourceQueries`     | `sdc-questionnaire-sourceQueries` extension                      | Named FHIR queries whose results are available to expressions                                               |

A typical flow:

```
App launches with patient context
        ↓
POST QuestionnaireResponse/$populate
  Parameters:
    - questionnaire (the Q resource)
    - subject (Patient reference)
    - context (launchContext variables)
        ↓
Server evaluates initialExpression on each item
        ↓
Returns QuestionnaireResponse with status = "in-progress"
  and pre-filled answers where data was found
```

---

## What You Need

### 1. Existing patient data on a FHIR server

The eHealth Test Server already contains many patients and other FHIR resources — you do not
need to load your own data first. Browse what is available:

```bash
GET https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Patient?api_key=${API_KEY}
GET https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Observation?api_key=${API_KEY}
```

Pick any patient that has existing `Observation` resources and use that patient ID in your
`$populate` call. Alternatively, run Test 1 first to POST observations for the sample patient,
then use those as the pre-population source.

Patient used in the sample QR:

```
Patient/ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a
```

### 2. A Questionnaire with pre-population expressions

The existing sample Questionnaires in [`data/samples/`](../../data/samples/) do not yet carry
pre-population extensions. To run this test you need to add `initialExpression` extensions to
relevant items, e.g. for body temperature:

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

Add a `launchContext` extension at the root of the Questionnaire to declare the patient variable:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext",
  "extension": [
    {
      "url": "name",
      "valueCoding": {
        "system": "http://hl7.org/fhir/uv/sdc/CodeSystem/launchContext",
        "code": "patient"
      }
    },
    {
      "url": "type",
      "valueCode": "Patient"
    },
    {
      "url": "description",
      "valueString": "The patient whose record is being reviewed"
    }
  ]
}
```

---

## Step 1 — Call `$populate`

```bash
curl --location \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire/\$populate?api_key=${API_KEY}" \
  --header 'Accept: application/fhir+json' \
  --header 'Content-Type: application/fhir+json' \
  --data '{
    "resourceType": "Parameters",
    "parameter": [
      {
        "name": "questionnaire",
        "resource": <Q-resource>
      },
      {
        "name": "subject",
        "valueReference": {"reference": "Patient/ad1cf7a8-8d18-475e-8277-98d5b1bb7d6a"}
      }
    ]
  }'
```

---

## Step 2 — Inspect the Returned QuestionnaireResponse

The server returns a `QuestionnaireResponse` with:

- `status: "in-progress"`
- Answers pre-filled where `initialExpression` resolved to data on the server
- Items with no matching data left unanswered (not an error)

---

## Step 3 — Complete and Submit

Hand the pre-filled `QuestionnaireResponse` to a nurse for completion of remaining items.
After completion, call `$extract` (Test 1) to produce the final FHIR resources.

---

## Success Criteria

- [ ] `$populate` returns a `QuestionnaireResponse` (not an `OperationOutcome`).
- [ ] `QuestionnaireResponse.status = "in-progress"`.
- [ ] At least one item is pre-filled with data retrieved from the FHIR server.
- [ ] Pre-filled values match what was previously stored (verify against `GET /Observation?patient=<id>&code=<loinc>`).
- [ ] Completing and extracting the pre-filled QR still produces a valid Bundle (regression check).
