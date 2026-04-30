# 🧠 What Makes This Fully SDC-Compliant?

## ✔ Declares SDC profile
meta.profile = "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire"
## ✔ Enables extraction at root

Allows $extract operation on the QuestionnaireResponse.

## ✔ Uses:

sdc-questionnaire-observationExtract

sdc-questionnaire-observationExtractCategory

sdc-questionnaire-unit

"component" for panel components

## ✔ Uses proper LOINC coding for Observation.code


# 🔄 Result of $extract

When a conformant SDC server runs:

POST QuestionnaireResponse/$extract

It will generate:

1 Observation → Heart Rate

1 Observation → Body Temperature

1 Observation → Blood Pressure panel with components

All with:

category = vital-signs

correct valueQuantity

effectiveDateTime from QuestionnaireResponse.authored

subject propagated