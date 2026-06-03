# Submission — [BeWell Innovations](https://github.com/bewellinnovations)

**Role(s):** data provider
**Test:** Test 2 — Extraction to a logical model  
**Date:** 2026-06-03

---

## What we tried

- Step 1, $extract: used OPAT sample QuestionnaireResponse and logical model (`Questionnaire`) with Tiro test server, worked.
- Step 2, validate: the output is shown below. We spot-checked a couple of data points and traced them from the `QuestionnaireResponse`, via its defined `definition`, to the resulting logical model element (output JSON).

```json
{
  "profile": "http://hl7belgium.org/fhir/patient-monitoring/StructureDefinition/opat-continuous-infusion-questionnaire",
  "value": {
    "nursingAssessment": {
      "catheterObservation": {
        "catheterObservation": "17621005",
        "damagedCatheter": "373066001",
        "lumen": [
          {
            "bloodAspiration": "36203004",
            "colorLumen": "371253002",
            "infusion": "36203004"
          }
        ],
        "other": "Test, the catheter tip looks strange"
      },
      "dressingObservation": {
        "bloody": "373066001",
        "dressingObservation": "263654008",
        "loose": "373066001",
        "moist": "373066001",
        "other": "Test",
        "purulent": "373066001",
        "serous": "373066001"
      },
      "insertionSiteObservation": {
        "blistering": "373066001",
        "crusting": "373066001",
        "extravasation": "373066001",
        "hematoma": "373066001",
        "insertionSiteObservation": "263654008",
        "other": "Test",
        "pus": "373067005",
        "redness": "373067005",
        "swelling": "373067005"
      },
      "medicationAdministration": {
        "administeredPerProcedure": "373066001",
        "deviationSpecification": "No, because this is a test so that didn't work"
      },
      "preparation": {
        "additionalObservation": "Test",
        "medicationDissolvedClear": "373066001",
        "weightEmptyInfusor": 2,
        "weightFullInfusorBeforeAdministration": 1
      },
      "sideEffects": {
        "blistersSkinPeeling": "6736007",
        "breathingProblems": "2667000",
        "candidiasis": "255604002",
        "chills": "6736007",
        "constipation": "255604002",
        "decreasedAppetite": "2667000",
        "diarrhea": "6736007",
        "fatigue": "6736007",
        "itching": "255604002",
        "jointPain": "24484000",
        "nausea": "24484000",
        "otherSymptoms": "Test, patient appears dejected",
        "painDuringAdministration": "6736007",
        "painGeneral": "2667000",
        "skinRash": "2667000",
        "swellingFaceTongue": "2667000",
        "vomiting": "255604002"
      },
      "storage": {
        "medicationStorageRemarks": "710977001",
        "storageRemarksSpecification": "No idea, this is a test but you can write a lot here."
      },
      "vitalParameters": {
        "bloodPressureDiastolic": 6,
        "bloodPressureSystolic": 5,
        "bodyTemperature": 3,
        "pulse": 4
      }
    }
  }
}
```

## What we found

We ran a couple of spot checks tracing information from the `QuestionnaireResponse` to the resulting logical model element (output JSON), see below.

### Trace 1: free-text catheter observation

- The `QuestionnaireResponse`…
  - … contains a `linkId` `CatheterObservation` ("Catheter observation") which contains a `linkId` `G6_Other` ("Other: (if applicable)").
  - … contains a `answer.valueString`: *"Test, the catheter tip looks strange"*
- Likewise, the logical model (`Questionnaire`):
  - … contains a `linkId` `CatheterObservation` ("Catheter observation"), which contains a `linkId` `G6_Other` ("Other: (if applicable)").
  - … contains a `definition`: http://hl7belgium.org/fhir/patient-monitoring/StructureDefinition/opat-continuous-infusion-questionnaire#opat-continuous-infusion-questionnaire.nursingAssessment.catheterObservation.other
- ✅ The `value` of the logical model element (output JSON) indeed contains a path `nursingAssessment.catheterObservation.other` with the value *"Test, the catheter tip looks strange"*

### Trace 2: coded value (SNOMED)

- The `QuestionnaireResponse` contains:
  - … a `linkId` `SideEffects` ("Side Effects"), which contains a `linkId` `H14_JointPain` ("Joint pain").
  - … contains a `answer.valueCoding.code`: *"24484000"* ("Severe (qualifier value)")
- Likewise, the logical model (`Questionnaire`):
  - … contains a `linkId` `SideEffects` ("Side Effects"), which contains a `linkId` `H14_JointPain` ("Joint pain").
  - … contains a `definition`: http://hl7belgium.org/fhir/patient-monitoring/StructureDefinition/opat-continuous-infusion-questionnaire#opat-continuous-infusion-questionnaire.nursingAssessment.sideEffects.jointPain
- ✅ The `value` of the logical model element (output JSON) indeed contains a path `nursingAssessment.sideEffects.jointPain` with the value *"24484000"* ("Severe (qualifier value)")

## Bugs or gaps noticed

N/A

## Design or model sketch

N/A

## Prototype or patch

N/A

## Open questions or follow-up ideas

N/A
