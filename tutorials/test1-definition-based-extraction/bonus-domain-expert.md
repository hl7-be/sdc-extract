# Bonus - Domain expert: author your own definitions

**For:** Registries, care institutions, clinical informaticists

This bonus is open-ended. There is no single right answer. The goal is to explore how definitions
are authored and what the trade-offs are.

---

## Context

In the base test you used pre-built Questionnaires that already carry `.definition` links and
`sdc-questionnaire-definitionExtract` extensions. This bonus asks: what does it take to build
those yourself?

There are two ways to add definitions to a Questionnaire:

1. **Direct JSON editing** - open the Questionnaire JSON, find each item, and add `.definition`
   and the SDC extensions by hand. Requires understanding the JSON structure but no extra tooling.
2. **Q2R Mapper UI** - a local web application in this repository that provides a graphical
   interface for linking Questionnaire items to StructureDefinition elements. Useful for large
   questionnaires or when JSON editing is unfamiliar. Requires local setup (Docker or Node.js +
   Python - see `apps/Q2Rmapper/README.md`; expect 10–15 min of setup time).

---

## Understand the mapping first

Open `data/samples/homehosp_q_opat_definitions.json` and find a few items with `.definition` set.
The pattern is:

```json
{
  "linkId": "B1_Temperatuur",
  "text": "Lichaamstemperatuur:",
  "type": "decimal",
  "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value"
}
```

The group item above it carries:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
  "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
}
```

And fixed values like `Observation.code` and `Observation.status` are set via
`sdc-questionnaire-definitionExtractValue` on the same group item.

---

## Things to explore

**Modify an existing Questionnaire**

- Add a new item to one of the sample Questionnaires (e.g. a free-text `note` field). Map it to
  `Observation.note.text`. Call `$extract` and check whether the note appears in the output.
- What happens if you remove the `sdc-questionnaire-definitionExtractValue` for `Observation.code`?
  Does extraction still work?

**Create your own Questionnaire**

- Design a simple Questionnaire for a clinical use case you know - even two or three items.
  Which FHIR resources would the answers map to? Which element paths?
- What is the minimum structure needed to make `$extract` produce a valid `Observation`?

**Use a registry StructureDefinition**

- If you have access to a registry StructureDefinition (e.g. from Sciensano, HealthData.be, or
  BCR), try using one of its elements as a definition target. What does extraction produce? 

**Discuss**

- Who in your organisation would be responsible for authoring and maintaining `.definition` links?
  A clinical informaticist? A terminology manager? A developer?
- What tooling would make this sustainable at scale?
- What happens when a StructureDefinition is updated - do all Questionnaires using it need to be
  reviewed?
- Do you think a FHIR Questionnaires + SDC extraction could be an interesting transition path for FHIR adoption for registries?


---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
