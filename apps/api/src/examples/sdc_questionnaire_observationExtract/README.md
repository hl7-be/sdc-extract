# FHIR Questionnaire with sdc-questionnaire-observationExtract

This questionnaire captures:

Heart Rate

Body Temperature

Blood Pressure (panel with components)

We use the extension:
🔗 http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationExtract
with boolean or coded values per the IG.

What the extensions mean (per SDC IG):

At the question level, valueBoolean: true = extract this item as an independent Observation.

Within a group, child items with "valueCode": "component" mean:
extract them as components of a parent Observation (blood pressure panel).

## How Extraction Works Using SDC IG Rules

With sdc-questionnaire-observationExtract, you can automate extraction:

Independent Observations (like Heart Rate, Body Temperature)

Because valueBoolean=true, each item becomes a standalone Observation.

Panel Observations (like Blood Pressure)

Group-level true → parent Observation

Child-level "component" → becomes Observation.component entries.

## Notes on Extraction

Because this SDC IG defines relationships (independent vs component), FHIR servers can implement $extract operations to emit Observations directly.

You can also augment with:

sdc-questionnaire-observation-extract-category for Observation.category

sdc-questionnaire-observationExtractEntry for metadata on extraction semantics