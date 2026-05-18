# Bonus - Domain expert: design your own logical model

**For:** Registries, care institutions, clinical informaticists

This bonus is open-ended. There is no single right answer.

---

## Context

The sample tests use `HomeHospAssessment` - a logical model designed for home hospitalisation
assessments. But logical models can represent any domain structure: a cancer registry submission,
an implant registration form, a care plan, a patient summary.

This bonus explores what it takes to design a logical model and connect it to a Questionnaire.

---

## Understand the existing logical model first

Look at the StructureDefinition uploaded by
`data/structure-definitions/StructureDefinition-opat-continuous-infusion-questionnaire.json` and compare its element paths to the
`.definition` values in `data/samples/homehosp_q_opat_logicalmodel.json`.

- How do the element paths in the StructureDefinition correspond to the JSON keys in the decoded
  Binary output from the base test?
- What is different between a logical model StructureDefinition and one that profiles a core FHIR
  resource (like the Questionnaires used in Test 1)?

---

## Things to explore

**Design a new logical model**

- Pick a clinical use case you know - a registry submission, a surgical checklist, a care plan
  template. Sketch a logical model StructureDefinition for it, even informally on paper or in a
  text editor.
- What element types would you use (`string`, `decimal`, `CodeableConcept`, nested objects)?
  How would you handle coded values? Lists?

**Connect it to a Questionnaire**

- Take a simple Questionnaire (or a subset of one of the samples) and add `.definition` links
  pointing to elements of your logical model.
- If you have time, register the StructureDefinition on the Tiro server and run `$extract`. Does
  the Binary output match the structure you designed?

**Belgian registries**

- Could a logical model replace or complement the existing submission formats for Sciensano,
  HealthData.be (HD4DP), or the Belgian Cancer Registry?
- What would it take to publish a FHIR logical model alongside an existing registry specification?
  Who would maintain it?

**Discuss**

- How would you handle versioning - if the logical model changes, what happens to previously
  extracted instances?
- Who would be responsible for authoring and evolving the logical model in your organisation?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
