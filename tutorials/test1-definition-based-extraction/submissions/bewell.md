# Submission — [BeWell Innovations](https://github.com/bewellinnovations)

**Role(s):** data provider  
**Test:** Test 1 — Definition-based extraction to FHIR resources  
**Date:** 2026-06-03

---

## What we tried

Referring to the steps in the README of tutorial/test 1:

- Step 1, `$extract`: used OPAT sample `Questionnaire` and `QuestionnaireResponse` with Tiro test server, worked.
- Step 2, `POST` the bundle:
  - Registered for [eHealth Digital Test Environment](https://github.com/hl7-be/FHIR-A-THON/wiki/BE-eHealth-Digital-Test-Environment-%E2%80%90-BE-FHIR%E2%80%90A%E2%80%90THON-2026)
  - After logging into DTE, on the Dashboard, enable the "HAPI-FHIR-Layer1" project to obtain a FHIR REST API URL
  - Attempt to `POST` the bundle to DTE -> ❌ Initially failed with 2 errors
  - Manually resolved error 1 by removing a stray `valueQuantity` in the bundle that did not belong there. A more correct way to fix this would be by fixing the definitions that caused it to be included in the bundle in the first place.
  - Manually resolved error 2 by adding a SNOMED code to a `DiagnosticReport` that did not have one
  - Attempt to `POST` the bundle to DTE -> ❌ Failed because is tied to a patient that did not exist in DTE yet
  - Attempt to `POST` a test patient to DTE -> ✔️ Worked
  - Attempt to `POST` the bundle to DTE -> ❌ Failed because the bundle refers to a practitioner that did not exist in DTE yet
  - Attempt to `POST` a test practitioner to DTE -> ✔️ Worked
  - Attempt to `POST` the bundle to DTE -> ✅ Worked!
- Step 3, verify
  - Attempt to `GET` the created Observations -> ✅ Worked! (Note: in the URL parameter, the patient identifier has to be formatted as `Patient/123abc`)
  - Created Observations are also visible in the UI of DTE, see screenshot below:

<img width="2354" height="1748" alt="image" src="https://github.com/user-attachments/assets/d1a284c4-d1e8-4315-99fc-913d6cd29960" />



## What we found

- Went to the eHealth table at the FHIR-A-THON to obtain access to the DTE environment.
- After obtaining access to the DTE environment, you have to manually enable the "HAPI-FHIR-Layer1" project to obtain a API URL (including API key).
- Before being able to post Observations, ensure all objects it refers to (Patient, Practitioner) have been seeded too with additional `POST`s.

## Bugs or gaps noticed

- Sample definitions in the repo caused the generated bundle to contain 2 errors (see above).

## Design or model sketch

N/A

## Open questions or follow-up ideas

N/A
