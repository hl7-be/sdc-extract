# HAPI `$extract` for Logical Models — Forking Approach

> **Status: UNTESTED IDEA.**
> We have **not** built, run, or verified this fork ourselves. This document
> is a design sketch derived from reading the upstream source (see
> [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md)). Every code change shown
> below is illustrative — treat it as a starting point for a spike, not as a
> patch you can paste verbatim.

---

## 0. Disclaimer up front

- The diffs in this file have **not been compiled**.
- The build/run steps have **not been executed end-to-end**.
- The approach assumes the structure of `cqframework/clinical-reasoning`
  on `master` at the time of investigation (around release `v4.7.0`,
  2026-05-11). The internals may have moved by the time you read this.
- "Logical model" here means an `StructureDefinition` with
  `kind = logical` — the Belgian onco / OPAT models in `data/samples/`.

If you take this on, please record findings back into this file (or open a
follow-up doc) so the next person doesn't repeat the same dead ends.

---

## 1. What we are trying to fix

Recap from [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md):

- HAPI delegates `QuestionnaireResponse/$extract` to the
  [`cqframework/clinical-reasoning`](https://github.com/cqframework/clinical-reasoning)
  library.
- That library, for definition-based extraction, ultimately calls:

  ```java
  Class.forName("org.hl7.fhir.r4.model." + type)
  ```

  in `org.opencds.cqf.fhir.utility.Resources.getClassForTypeAndVersion`. For
  logical models there is no such generated Java class, so it throws
  `ClassNotFoundException` (wrapped in `IllegalArgumentException`).

The fork's goal is to intercept that single moment and produce a
profile-driven, generic representation of the logical-model instance instead
of trying to instantiate a non-existent POJO.

---

## 2. Architecture recap

```
┌────────────────────────────────────────────────────────────────┐
│ HAPI FHIR JPA server (hapi-fhir)                               │
│   └── hapi-fhir-storage-cr                                     │
│        └── @Operation("$extract") providers                    │
│             │  (thin wiring; no extraction logic of its own)   │
│             ▼                                                  │
│        cqframework/clinical-reasoning  ←  THE LOGIC IS HERE    │
│          cqf-fhir-cr/.../questionnaireresponse/extract/        │
│            ExtractProcessor                                    │
│            ProcessDefinitionItem  ← (D)+(E) in investigation   │
│          cqf-fhir-utility/.../Resources.java                   │
│            getClassForTypeAndVersion  ← THE Class.forName SITE │
└────────────────────────────────────────────────────────────────┘
```

So: **the fork target is `cqframework/clinical-reasoning`, not `hapi-fhir`**.
You only touch HAPI's `pom.xml` (or your starter's `build.gradle`) to make
it consume *your* patched version of the CR library.

---

## 3. Two forking strategies

### Strategy A — Fork only `cqframework/clinical-reasoning` (recommended)

1. Fork `cqframework/clinical-reasoning`.
2. Patch the two files identified in
   [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md) §2.
3. Publish the resulting JARs to a local/team Maven repository under a
   private version coordinate (e.g. `4.7.0-uzl.1`).
4. Override `clinical-reasoning` versions in the HAPI server's `pom.xml`
   via `<dependencyManagement>` so HAPI picks up your build.

Pros: minimal blast radius — you change one library, HAPI itself stays on
stock releases.
Cons: you have to re-rebase on every upstream CR release.

### Strategy B — Fork `hapi-fhir` *and* `clinical-reasoning`

Only needed if you also want to change the HAPI-side wiring (e.g. register a
new operation provider, expose an extension parameter, or change how the
extraction target is decided). For the specific `ClassNotFoundException` we
care about, this is overkill.

**Recommendation: start with Strategy A.**

---

## 4. The code change — sketch

> Reminder: **untested**. Names of types and method signatures are based on
> the current source quoted in [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md);
> verify against the tag you're forking.

### 4.1 Detect logical-model targets

In `ProcessDefinitionItem.processDefinitionItem`, before the call to
`newBaseForVersion(...)`, decide whether the target is a logical model:

```java
public IBaseResource processDefinitionItem(ExtractRequest request, ItemPair item) {
    ...
    var profile      = getProfile(request, profileUrl);
    var resourceType = getResourceType(linkId, definitionProfile, definition, profile);

    // NEW: logical-model branch
    if (isLogicalModel(profile)) {
        return processLogicalModelItem(request, item, profile.get());
    }

    var extractResource   = getExtractResource();
    var isCreatedResource = extractResource == null;
    var resource = isCreatedResource
            ? (IBaseResource) newBaseForVersion(resourceType, request.getFhirVersion())
            : extractResource;
    processResource(request, resource, profile, isCreatedResource, item);
    return resource;
}

private boolean isLogicalModel(Optional<IStructureDefinitionAdapter> profile) {
    return profile.isPresent() && "logical".equalsIgnoreCase(profile.get().getKind());
}
```

> `IStructureDefinitionAdapter.getKind()` exists on the current adapter —
> double-check the exact accessor name in your fork's source.

### 4.2 Build a profile-driven instance instead of a POJO

There are three plausible representations for the logical-model output:

| Option | Representation                                                | Effort   | Spec-fit                          |
|--------|---------------------------------------------------------------|----------|-----------------------------------|
| 1      | `Parameters` with one `parameter` per leaf path               | Low      | Loose — clients need to know LM   |
| 2      | `org.hl7.fhir.r4.elementmodel.Element` driven by the SD       | Medium   | Best — true LM instance shape     |
| 3      | Raw `Map<String, Object>` serialized to JSON                  | Low      | Bypasses HAPI's resource model    |

**Option 2 is the spec-fit choice.** `org.hl7.fhir.r4.elementmodel.Element`
(from the FHIR core `org.hl7.fhir.r4` package, the same one HAPI's validator
uses) can represent any element of any `StructureDefinition` — including
logical models — without needing a generated class. Pseudocode:

```java
private IBaseResource processLogicalModelItem(
        ExtractRequest request,
        ItemPair item,
        IStructureDefinitionAdapter profile) {

    // 1. Get a profile-aware element factory.
    //    org.hl7.fhir.r4.elementmodel.Property / Element from the FHIR core jar.
    var elementFactory = request.getFhirContext()                 // verify accessor
            .getValidationSupport();                              // or similar
    var rootElement = org.hl7.fhir.r4.elementmodel.Manager
            .build(elementFactory, profile.get());                // pseudo

    // 2. Walk the QuestionnaireResponse exactly like processResource(...) does,
    //    but call rootElement.makeElement(path) / setProperty(...) instead of
    //    request.getModelResolver().setValue(resource, path, value).
    walkAndPopulate(request, rootElement, item, profile);

    // 3. Wrap the elementmodel.Element so the extractor's bundle assembler
    //    can include it. Easiest stopgap: serialize to JSON, parse into a
    //    DomainResource of type "Basic" with a contained representation -
    //    OR extend the bundle code to accept Element directly.
    return wrapAsResource(rootElement);
}
```

The `walkAndPopulate` step should reuse `processItems(...)` /
`processChildItem(...)` from `ProcessDefinitionItem`, but routed through an
element-model setter instead of `IModelResolver.setValue(...)`. Refactoring
those methods to operate on an `IBase`-shaped abstraction is probably the
**bulk of the work**.

### 4.3 Belt-and-braces: harden `Resources.getClassForTypeAndVersion`

If the new branch in §4.1 misses a code path, you want a clearer error
than `ClassNotFoundException`:

```java
public static <T extends IBase> Class<T> getClassForTypeAndVersion(String type, FhirVersionEnum fhirVersion) {
    if (type != null && type.contains("/")) {
        throw new IllegalArgumentException(
            "getClassForTypeAndVersion called with a canonical URL ('" + type +
            "'). This usually means a logical-model target reached the core-resource " +
            "code path. See ProcessDefinitionItem#isLogicalModel.");
    }
    try {
        return (Class<T>) Class.forName(
                "org.hl7.fhir.%s.model.%s".formatted(fhirVersion.toString().toLowerCase(), type));
    } catch (Exception e) {
        throw new IllegalArgumentException(e);
    }
}
```

Optional, but it turns a confusing reflection error into a pointer at the
right file.

---

## 5. Build & publish your patched CR

> Verify the exact module names against the fork's `pom.xml`.

```bash
# 1. clone your fork
git clone https://github.com/<your-org>/clinical-reasoning.git
cd clinical-reasoning
git checkout -b feature/logical-model-extract v4.7.0

# 2. apply the patches from §4
# ... edit ProcessDefinitionItem.java, Resources.java ...

# 3. bump version
mvn versions:set -DnewVersion=4.7.0-uzl.1 -DgenerateBackupPoms=false

# 4. install to local Maven repo
mvn -DskipTests clean install
```

This puts artifacts like
`org.opencds.cqf.fhir:cqf-fhir-cr:4.7.0-uzl.1` into your local
`~/.m2/repository`.

For a team-wide build, push to a private Nexus / GitHub Packages instead of
`install`.

---

## 6. Wire HAPI to use your patched library

Pick the HAPI server flavour you actually run. The two common ones:

### 6.1 `hapi-fhir-jpaserver-starter` (Spring Boot)

In its `pom.xml`, the CR library is a transitive dep of `hapi-fhir-storage-cr`.
Force the override:

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.opencds.cqf.fhir</groupId>
      <artifactId>cqf-fhir-cr</artifactId>
      <version>4.7.0-uzl.1</version>
    </dependency>
    <dependency>
      <groupId>org.opencds.cqf.fhir</groupId>
      <artifactId>cqf-fhir-utility</artifactId>
      <version>4.7.0-uzl.1</version>
    </dependency>
    <!-- include every other cqf-fhir-* module HAPI pulls in -->
  </dependencies>
</dependencyManagement>
```

Then `mvn clean package` and run the resulting jar.

### 6.2 Custom HAPI build

If you embed HAPI into your own application, just add the dependencies
above to your top-level build file. Maven's nearest-definition wins, so a
direct dependency on `4.7.0-uzl.1` will beat the transitive `4.7.0`.

Verify with `mvn dependency:tree | grep cqf-fhir` (or `gradle dependencies`).

---

## 7. Testing

Reuse the curls already in this repo as a smoke-test harness:

- **Negative control (logical-model, current behaviour):**
  `scripts/curls/working_extraction_opat_logicalmodel.sh` against a stock HAPI
  → expect the `ClassNotFoundException` from
  [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md).
- **Positive case (logical-model, your fork):** same curl against your
  patched HAPI → expect a `Parameters` / `Element`-shaped response.
- **Regression (core resources still work):**
  `scripts/curls/working_extraction_opat_tiroserver.sh` and `working_extraction_onco_tiroserver.sh`
  must still succeed and produce the same Bundle they did before.

If you have time, add a unit test in `clinical-reasoning` itself: pick the
Belgian sample Questionnaire/QuestionnaireResponse pair from `data/samples/`
and assert that `ProcessDefinitionItem.processDefinitionItem` yields a
non-null result with the expected element paths populated.

---

## 8. Risks & open questions

Things to confirm before you commit a week to this:

1. **Bundle assembly.** `ExtractProcessor.createBundle(...)` ultimately
   produces a transaction `Bundle`. Logical-model instances are not
   `IBaseResource` in the FHIR-resource sense (they don't have a `resourceType`
   that the JPA server can route to a DAO). Decide whether you want:
   - the operation to return `Parameters` containing the LM (no DB write), or
   - to short-circuit the persistence step for LM outputs, or
   - to store them as `Basic` + extensions.
   This is a design decision the SDC IG itself leaves open for logical models.
2. **R5 / DSTU3.** The fix has to be applied in the `extract/r4`,
   `extract/r5` (and possibly DSTU3) subpackages if you need parity.
3. **Element-model API stability.** `org.hl7.fhir.r4.elementmodel.Element`
   lives in the FHIR core jar, not in HAPI's structures jar — confirm it's on
   the classpath of `cqf-fhir-cr` already, or add it as a dependency.
4. **Upstreaming.** If the fork works, consider opening a PR on
   `cqframework/clinical-reasoning`. There is no open issue for logical-model
   extraction today (see investigation §4) so an RFC issue first may be
   wiser than a surprise PR.
5. **Maintenance cost.** Every upstream CR release that touches
   `ProcessDefinitionItem` will need a rebase. Treat this as a recurring
   cost, not a one-shot patch.

---

## 9. If a fork is too expensive

The cheaper alternatives from [`README.md`](../README.md) §FSE remain valid:

- Author a `StructureMap` for QR → logical-model and use
  `sdc-questionnaire-targetStructureMap` (HAPI supports the StructureMap
  dispatch — different code path).
- Use Test 1 (core-resource extraction) and reassemble the logical model
  client-side.
- Run extraction on a server that already supports logical-model targets
  (Tiroserver — to be confirmed).

These don't require any Java changes and are the right "today" answer until
the fork lands.

---

## 10. Sources

- [`hapi-extract-logical-model-root-cause.md`](hapi-extract-logical-model-root-cause.md) — root-cause source-level
  analysis, with the exact line and stack involved.
- `cqframework/clinical-reasoning`:
  https://github.com/cqframework/clinical-reasoning
- HAPI FHIR — Clinical Reasoning / Questionnaires:
  https://hapifhir.io/hapi-fhir/docs/clinical_reasoning/questionnaires.html
- SDC IG — Data Extraction:
  https://hl7.org/fhir/uv/sdc/extraction.html
- FHIR core element model (`org.hl7.fhir.r4.elementmodel.Element`) lives in
  the `hapi-fhir-validation-resources-r4` / `org.hl7.fhir.core` jars —
  inspect your dependency tree to confirm.
