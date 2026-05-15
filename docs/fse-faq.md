# FSE / FAQ - Common errors and questions

Errors and questions collected while running the test scenarios.
See also [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md) for a deep-dive
into the logical-model limitation, and [`hapi-extract-logical-model-fork-guide.md`](hapi-extract-logical-model-fork-guide.md)
for a forking approach to fix it.

---

## `IllegalArgumentException: Unable to retrieve Questionnaire code map for Observation based extraction`

HAPI's `$extract` fell through to **observation-based** extraction (the legacy
`sdc-questionnaire-observationLinkPeriod` / "code map" path) instead of the definition-based path you intended.

**Fix:** ensure **at least one leaf item carries `sdc-questionnaire-definitionExtract`** with a target `valueCanonical`
(e.g. `http://hl7.org/fhir/StructureDefinition/Observation`). It does not need to be on every leaf - only on the group
items that should produce extracted resources.

> Earlier wisdom suggested that having `code` elements on leaves was forbidden under definition-based extraction. That
> turns out **not** to be the case. The leaf `code` is simply redundant: under definition-based extraction,
> `Observation.code` comes from a `sdc-questionnaire-definitionExtractValue` fixed-value extension on the **group**,
> not from `Questionnaire.item.code`.

---

## `NullPointerException` deep in `ItemPair.getItem(...)`

**Symptom:** `$extract` returns 500 with a stack trace pointing at
`org.opencds.cqf.fhir.cr.questionnaireresponse.extract.ProcessDefinitionItem`, NPE on `ItemPair.getItem()`.

**Real cause:** a `linkId` in the `QuestionnaireResponse` does not resolve to any item in the `Questionnaire`. HAPI's CR
builds an `ItemPair` for every QR leaf; if the matching Q item is missing, `getItem()` returns null and the next access
throws.

> This happens when a Q was regenerated or hand-edited and the QR was authored against an earlier version. Only linkIds
> present in both resources resolve correctly.

**Fix:** make sure every `QuestionnaireResponse.item.linkId` (recursively) is also present in the referenced
`Questionnaire`. Diff the linkId sets first whenever you see this NPE.

---

## Extracted `Observation`s have an empty `code`

`status`, `category`, `subject`, `value[x]` come out fine but `Observation.code` is `{}`.

**Cause:** the `Questionnaire` is missing a `sdc-questionnaire-definitionExtractValue` for `Observation.code` on the
group.

**Fix:** add one with a coded fixed value on the group item, e.g.:

```json
{
  "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
  "extension": [
    {
      "url": "definition",
      "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.code"
    },
    {
      "url": "fixed-value",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8716-3",
            "display": "Vital signs"
          }
        ]
      }
    }
  ]
}
```

---

## `valueExpression` on `definitionExtract` / `definitionExtractValue` is silently ignored

The SDC IG documents both `valueCanonical` and `valueExpression` as permitted forms. HAPI's CR reads these primitives
via `IPrimitiveType` and only the canonical/URI forms parse - `valueExpression` is silently dropped, which makes
dispatch fall through to observation-based extraction (and you end up at the first error in this list).

**Use `valueCanonical`** (for `definitionExtract`) and **`valueUri`** (for the `definition` sub-extension), not
`valueExpression`, until HAPI's CR adds expression support.

---

## `ClassNotFoundException: org.hl7.fhir.r4.model.<logical-model-URL>` when extracting to a Logical Model

**Symptom:** `$extract` with a `Questionnaire` whose `sdc-questionnaire-definitionExtract` points to a logical model
canonical URL returns an `OperationOutcome` like:

```
java.lang.IllegalArgumentException: java.lang.ClassNotFoundException:
  org.hl7.fhir.r4.model.http://hl7belgium.org/fhir/patient-monitoring/StructureDefinition/onco-trastuzumab-questionnaire
```

**Real cause:** HAPI does not implement `$extract` itself - it delegates to the
[`cqframework/clinical-reasoning`](https://github.com/cqframework/clinical-reasoning) library. That library's
definition-based path resolves the target type and then calls:

```java
Class.forName("org.hl7.fhir.r4.model." + type)
```

For core resources (`Observation`, `DiagnosticReport`, …) this resolves to a real generated Java class. For a logical
model, `type` ends up as the canonical URL (or a fragment of it) - no such class exists in the HAPI structures JAR,
so `ClassNotFoundException` is thrown wrapped in `IllegalArgumentException`.

**On the SD lookup:** uploading the logical model's `StructureDefinition` to the HAPI server *does* allow the canonical
URL to resolve - the library's `getProfile(...)` call succeeds and finds the SD. But that does not help: the next step
reads `StructureDefinition.type`, which for `kind = logical` is itself the canonical URL (not a core resource name),
and feeds that string into the same `Class.forName` call. The outcome is identical.

> In short: the SD is found, but what is done with it - reflective instantiation of a generated POJO - cannot work for
> any type outside `org.hl7.fhir.r4.model.*`. Publishing the IG at the canonical URL makes no difference either.
> The restriction is implicit, baked into the reflection call.

See [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md) for the full source-level
trace through `ProcessDefinitionItem` and `Resources.getClassForTypeAndVersion`.

**Workarounds:**

- **StructureMap-based extraction:** author a `StructureMap` that transforms `QuestionnaireResponse` into the logical
  model instance, reference it via `sdc-questionnaire-targetStructureMap`, and call `$extract`. HAPI supports the
  StructureMap dispatch - it follows a different code path that does not go through `getClassForTypeAndVersion`.
  Complex to author but spec-compliant.
- **Client-side assembly:** use Test 1 (definition-based extraction to core FHIR resources) to get a Bundle of
  `Observation` / `DiagnosticReport` / … resources, then reassemble into the logical model shape client-side using
  the element mappings declared in the logical model `StructureDefinition`.
- **Different server:** any server whose extractor builds the target instance from `StructureDefinition` metadata
  rather than reflecting on generated POJOs (e.g. Tiroserver - to be confirmed).
- **Fork `cqframework/clinical-reasoning`:** see [`hapi-extract-logical-model-fork-guide.md`](hapi-extract-logical-model-fork-guide.md)
  for a design sketch (untested).
