# Bonus - Developers: fix logical model extraction in HAPI

**For:** Java developers comfortable with Maven and working with OSS libraries

This is a design-level challenge. There is no fully working solution yet - the goal is to
understand the problem, evaluate the proposed fix, and optionally prototype it.

---

> [!WARNING]
> The root cause analysis in [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md)
> and the fix described in [`docs/hapi-extract-logical-model-fork-guide.md`](../../docs/hapi-extract-logical-model-fork-guide.md)
> are **unverified**: they are based on reading the upstream source, not on running or debugging
> live code. The actual failure mode may differ, and there may be additional problems not captured
> in the analysis. Treat both documents as a starting point for investigation, not a confirmed
> diagnosis.

---

## The problem

HAPI FHIR delegates `$extract` to the `cqframework/clinical-reasoning` library. That library
assumes the extraction target is a standard FHIR resource type and uses Java reflection to
instantiate it:

```java
Class.forName("org.hl7.fhir.r4.model." + type)
```

For logical models, `type` is a canonical URL, not a class name. The call throws
`ClassNotFoundException` and extraction fails silently or with a server error.

Full root cause analysis: [`docs/hapi-extract-logical-model-root-cause.md`](../../docs/hapi-extract-logical-model-root-cause.md)  
Proposed fix design: [`docs/hapi-extract-logical-model-fork-guide.md`](../../docs/hapi-extract-logical-model-fork-guide.md)

---

## Things to explore

**Understand the architecture**

- Read the root cause doc and trace the call chain in the `clinical-reasoning` source. Confirm
  the `ClassNotFoundException` path in `ProcessDefinitionItem.processDefinitionItem` and
  `Resources.getClassForTypeAndVersion`.
- Why is the fix in `clinical-reasoning` rather than `hapi-fhir` itself? What is the boundary
  between the two libraries?

**Evaluate the proposed fix**

- The guide proposes using `org.hl7.fhir.r4.elementmodel.Element` to represent logical model
  instances without requiring generated POJOs. Is this approach sound? What API stability risks
  exist in the FHIR core library?
- The guide suggests Strategy A (fork `clinical-reasoning` only). Are the cheaper alternatives
  (StructureMap-based extraction, client-side assembly via the Python extractor) viable for the
  use cases in this atelier?

**Prototype**

- Fork `cqframework/clinical-reasoning` and apply the changes described in the guide's
  "Key Changes" section.
- Build with Maven (`mvn -DskipTests clean install`) and wire the patched version into a local
  HAPI instance by overriding the dependency version in `dependencyManagement`.
- Use `scripts/curls/working_extraction_opat_logicalmodel.sh` as a smoke test against your
  local HAPI. Does it work? If not - what broke?
- Run `scripts/curls/working_extraction_opat.sh` as a regression check - core FHIR resource
  extraction must still work.

**Upstream**

- If you get a working prototype, what would it take to upstream the change to
  `clinical-reasoning`? What tests would the maintainers require?
- Is this a contribution worth making to the HL7 community?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you explored and concluded, and open a pull request targeting `main`. For code patches, modified
`pom.xml` snippets, or other files, put them in `submissions/prototypes/{your-handle}/`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
