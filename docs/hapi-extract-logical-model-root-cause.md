# HAPI `$extract` and Logical Models — Investigation

> Why does HAPI's `QuestionnaireResponse/$extract` fail when the `Questionnaire`'s
> `sdc-questionnaire-definitionExtract` points to a **logical model** instead of a
> standard FHIR resource (e.g. `Observation`)?

This document captures the source-level root cause, the exact lines responsible,
and the practical implications for the home-hospitalization / registry use cases
described in [`README.md`](../README.md).

---

## TL;DR

- HAPI does **not** implement `$extract` itself. It delegates to the
  [`cqframework/clinical-reasoning`](https://github.com/cqframework/clinical-reasoning)
  library (Java package `org.opencds.cqf.fhir.cr.questionnaireresponse.extract`).
- That library's definition-based path eventually calls one helper —
  `Resources.getClassForTypeAndVersion(type, fhirVersion)` — which does:

  ```java
  Class.forName("org.hl7.fhir.%s.model.%s".formatted(fhirVersion.toLowerCase(), type))
  ```

  and wraps any failure in `IllegalArgumentException`.
- The `type` string is derived from the canonical URL on
  `sdc-questionnaire-definitionExtract` (or the `StructureDefinition.type` of a
  resolved profile). For core resources this resolves to a real class
  (`org.hl7.fhir.r4.model.Observation`, …). For **logical models** it cannot —
  the FHIR R4 structures jar contains generated classes for the core resources
  only.
- Therefore: **HAPI's definition-based `$extract` is restricted to core FHIR
  resource types as extraction targets, by construction of the Java reflection
  call.** It is not a config/registry/IG-publishing issue.

This is consistent with the FSE already documented in
[`README.md`](../README.md) lines 156–184 — and the source confirms the mechanism.

---

## 1. Where `$extract` actually runs

`hapi-fhir`'s `hapi-fhir-storage-cr` module exposes the `$extract` operation,
but the implementation is provided by the external library
[`cqframework/clinical-reasoning`](https://github.com/cqframework/clinical-reasoning).
HAPI's CR documentation describes the operation
([HAPI docs — Questionnaires](https://hapifhir.io/hapi-fhir/docs/clinical_reasoning/questionnaires.html))
and the recent v3.13 changes (definition lookup now prefers the `Questionnaire`
item over the `QuestionnaireResponse`) live in that library, not in HAPI.

Concretely, the call chain for `QuestionnaireResponse/$extract` lands in:

- `org.opencds.cqf.fhir.cr.questionnaireresponse.extract.ExtractProcessor` —
  dispatcher between observation-based and definition-based extraction.
- `org.opencds.cqf.fhir.cr.questionnaireresponse.extract.ProcessDefinitionItem` —
  the **definition-based** path (the one we want for SDC).

Both files live under
`cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/questionnaireresponse/extract/`
on `master`.

---

## 2. The exact code that breaks for logical models

### 2.1 `ProcessDefinitionItem.processDefinitionItem(...)`

Top of the method
([source](https://raw.githubusercontent.com/cqframework/clinical-reasoning/master/cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/questionnaireresponse/extract/ProcessDefinitionItem.java)):

```java
public IBaseResource processDefinitionItem(ExtractRequest request, ItemPair item) {
    // Definition-based extraction -
    // http://build.fhir.org/ig/HL7/sdc/extraction.html#definition-based-extraction

    var linkId = item.getResponseItem() == null
            ? "Questionnaire.root"
            : item.getResponseItem().getLinkId();
    var definitionProfile = getDefinitionProfile(request, item);     // (A)
    var definition         = getDefinition(item);                    // (B)
    var profileUrl         = definitionProfile.right == null ? definition : definitionProfile.right;
    var profile            = getProfile(request, profileUrl);        // (C) resolves the SD if uploaded
    var resourceType       = getResourceType(linkId, definitionProfile, definition, profile); // (D)
    var extractResource    = getExtractResource();                   // currently null
    var isCreatedResource  = extractResource == null;
    var resource = isCreatedResource
            ? (IBaseResource) newBaseForVersion(resourceType, request.getFhirVersion())   // (E) ← throws
            : extractResource;
    processResource(request, resource, profile, isCreatedResource, item);
    return resource;
}
```

The relevant points:

- **(A) `getDefinitionProfile`** inspects the `definitionExtract` extension. If
  its primitive value contains `/`, it is treated as a *profile URL*; otherwise
  as a bare *resource type name*. For the Belgian logical-model URL
  `http://hl7belgium.org/fhir/.../onco-trastuzumab-questionnaire` we land in the
  "URL" branch — `definitionProfile.left == null`, `definitionProfile.right ==
  <full canonical URL>`.

- **(C) `getProfile`** does `searchRepositoryByCanonical(...)`. If you upload
  the `StructureDefinition` to the HAPI server, this WILL find it and return an
  `IStructureDefinitionAdapter`. (This nuance updates the README's note that the
  "extraction code never reaches the lookup step" — it does, but the result
  doesn't save you. See §3.)

- **(D) `getResourceType`** (excerpt):

  ```java
  protected String getResourceType(
          String linkId,
          ImmutablePair<String, String> definitionProfile,
          String definition,
          Optional<IStructureDefinitionAdapter> profile) {
      var resourceType = definitionProfile.left;                 // null for our URL
      if (StringUtils.isEmpty(resourceType)) {
          if (profile.isPresent()) {
              resourceType = profile.get().getType();            // ← SD.type
          } else if (definitionProfile.right != null) {
              var split = definitionProfile.right.split("/");
              resourceType = split[split.length - 1];            // ← last URL segment
          } else {
              if (definition == null) { throw new IllegalArgumentException(...); }
              resourceType = getDefinitionType(definition);       // part after '#'
          }
      }
      return resourceType;
  }
  ```

  For a logical-model SD, **`StructureDefinition.type` is the canonical URL of
  the logical model itself** (per the FHIR spec: for `kind = logical`, `type`
  can be any URI naming the logical model — it is *not* a core resource name).
  So whichever branch is taken, `resourceType` ends up as a string that does
  not correspond to a generated Java class:

  | SD uploaded? | `resourceType` becomes                                    | Class name attempted                         |
  |--------------|-----------------------------------------------------------|----------------------------------------------|
  | yes          | `profile.get().getType()` — the canonical URL of the LM   | `org.hl7.fhir.r4.model.<full canonical URL>` |
  | no           | last segment of the URL (e.g. `onco-trastuzumab-...`)     | `org.hl7.fhir.r4.model.<last-segment>`       |

  Neither resolves.

- **(E) `newBaseForVersion(resourceType, ...)`** is the call that throws.

### 2.2 `Resources.getClassForTypeAndVersion` — the actual restriction

[`org.opencds.cqf.fhir.utility.Resources`](https://raw.githubusercontent.com/cqframework/clinical-reasoning/master/cqf-fhir-utility/src/main/java/org/opencds/cqf/fhir/utility/Resources.java):

```java
public static IBase newBaseForVersion(String type, FhirVersionEnum fhirVersion) {
    return Resources.newBase(Resources.getClassForTypeAndVersion(type, fhirVersion));
}

@SuppressWarnings("unchecked")
public static <T extends IBase> Class<T> getClassForTypeAndVersion(String type, FhirVersionEnum fhirVersion) {
    try {
        return (Class<T>) Class.forName(
                "org.hl7.fhir.%s.model.%s".formatted(fhirVersion.toString().toLowerCase(), type));
    } catch (Exception e) {
        throw new IllegalArgumentException(e);          // wraps ClassNotFoundException
    }
}
```

**This is the hardcoded check.** The library is asking the JVM to load
`org.hl7.fhir.r4.model.<type>` — i.e. the HAPI-FHIR R4 structures jar, which
contains generated POJOs **only for the core FHIR R4 resource types and
data-types**. Logical models defined in IGs (or anywhere else) are not part of
that jar and cannot be loaded this way. The wrapping
`throw new IllegalArgumentException(e)` exactly matches the symptom in
[`README.md`](../README.md):

```
java.lang.IllegalArgumentException: java.lang.ClassNotFoundException:
  org.hl7.fhir.r4.model.http://hl7belgium.org/fhir/.../onco-trastuzumab-questionnaire
```

So the "check" is not a defensive `if (!isCoreResourceType(...)) throw`; it's
an *implicit* restriction baked into reflection over generated classes.

---

## 3. Why uploading the `StructureDefinition` doesn't help

A natural first attempt — and one the README warns against — is "let me upload
the logical model's `StructureDefinition` to HAPI so the canonical URL
resolves."

Walking the code with the SD uploaded:

1. `getProfile(...)` at (C) succeeds. `profile.isPresent() == true`.
2. `getResourceType(...)` at (D) returns `profile.get().getType()`. For a
   logical-model SD this is the canonical URL (or some other non-core string
   the IG authors chose), not `Observation` / `Patient` / etc.
3. `newBaseForVersion(<that string>, R4)` at (E) calls
   `Class.forName("org.hl7.fhir.r4.model." + <that string>)` → `ClassNotFoundException`.

Net effect: the SD is found, but its `type` is then funneled into a reflection
call that cannot produce anything other than a core R4 class. The README's
operational guidance ("does not fix it … publishing the IG at the canonical URL
makes no difference") is correct in outcome; the precise mechanism is "the SD
is looked up, but its `type` is used as a Java class name in
`org.hl7.fhir.r4.model.*`."

---

## 4. Is HAPI ever going to support this directly?

Snapshot of the upstream picture today:

- A search of `cqframework/clinical-reasoning` issues for "logical model" turns
  up no open or closed items. ([issue search](https://github.com/cqframework/clinical-reasoning/issues?q=logical+model))
- Recent releases (`v4.4.x` → `v4.7.0`, latest 2026-05-11) include many
  refinements to definition-based extraction, but none mention logical models
  or `StructureDefinition`-targeted extraction.
  ([releases](https://github.com/cqframework/clinical-reasoning/releases))
- HAPI v3.13 release notes (via the HAPI docs site) describe two changes —
  preferring the `Questionnaire.item.definition` over the QR's `definition`
  when looking up the target, and better handling of decimal/integer answers
  with unit extensions — but again, no logical-model support.
  ([HAPI CR — Questionnaires](https://hapifhir.io/hapi-fhir/docs/clinical_reasoning/questionnaires.html))

To support extraction *to* a logical model in this code path, the library
would need to stop instantiating a generated `org.hl7.fhir.r4.model.<Type>`
class and instead build a `Bundle`/`Parameters`/something representing the
logical-model instance via the FHIR `Element`/`Base` machinery driven by the
`StructureDefinition` itself. That is a non-trivial change to the design.

---

## 5. Implications for the atelier use cases

### Test 1 (definition-based extraction to core resources) — works on HAPI

Anything where `definitionExtract` points at
`http://hl7.org/fhir/StructureDefinition/Observation` (or other core types) is
fine. This is the OPAT / oncology flows that ship `Observation`,
`DiagnosticReport`, `MedicationStatement`, etc.

### Test 2 (extraction to logical models) — does **not** work on HAPI

This is the scenario this investigation covers. Any IG-defined logical model
referenced via `definitionExtract` will hit the `Class.forName` failure.

### Workarounds (already in `README.md`)

1. **StructureMap-based extraction.** Author a `StructureMap` that maps QR →
   logical-model instance, reference it via `sdc-questionnaire-targetStructureMap`,
   and use `$extract`. HAPI's CR supports this dispatch — it follows a
   completely different code path and does not go through
   `getClassForTypeAndVersion`. Complex to author but spec-compliant.
2. **Two-stage on the client.** Run Test 1 against HAPI to obtain a Bundle of
   `Observation`s, then reassemble into the logical-model shape client-side
   using the same element paths declared in the logical model's
   `StructureDefinition`.
3. **A different server.** Any server whose extractor builds the target
   instance from `StructureDefinition` metadata rather than reflecting on
   generated POJOs — the Tiro testserver in this repo
   (`apps/tiro_sdc_extract/`) does this, resolving logical-model `definition`
   paths against the `StructureDefinition`s loaded from
   `STRUCTURE_DEFINITIONS_DIR`.

---

## 6. Sources

- HAPI FHIR docs — Clinical Reasoning / Questionnaires:
  https://hapifhir.io/hapi-fhir/docs/clinical_reasoning/questionnaires.html
- HAPI FHIR docs — Clinical Reasoning overview:
  https://hapifhir.io/hapi-fhir/docs/clinical_reasoning/overview.html
- `cqframework/clinical-reasoning` (the library backing HAPI's CR module):
  https://github.com/cqframework/clinical-reasoning
- `ProcessDefinitionItem.java` (raw):
  https://raw.githubusercontent.com/cqframework/clinical-reasoning/master/cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/questionnaireresponse/extract/ProcessDefinitionItem.java
- `Resources.java` — the `Class.forName` site (raw):
  https://raw.githubusercontent.com/cqframework/clinical-reasoning/master/cqf-fhir-utility/src/main/java/org/opencds/cqf/fhir/utility/Resources.java
- `cqframework/clinical-reasoning` releases:
  https://github.com/cqframework/clinical-reasoning/releases
- `cqframework/clinical-reasoning` issues search for "logical model":
  https://github.com/cqframework/clinical-reasoning/issues?q=logical+model
- SDC IG — Data Extraction:
  https://hl7.org/fhir/uv/sdc/extraction.html
- Local FSE entry (already documenting the symptom):
  [`README.md`](../README.md) lines 156–184
