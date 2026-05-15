# Bonus - Data provider: Python extractor for logical models

**For:** EHR vendors, care software developers, anyone without a FHIR server that supports
logical model extraction natively

This bonus is open-ended. There is no single right answer.

---

## Context

The Python extractor in
[`apps/Q2Rmapper/api/src/core/extractor.py`](../../apps/Q2Rmapper/api/src/core/extractor.py)
currently implements definition-based extraction into standard FHIR resources (the Test 1
scenario). Logical model extraction produces a different kind of output: a flat or nested JSON
structure whose shape is defined by the logical model StructureDefinition, not by FHIR resource
types.

For how the extractor works and how to run it locally, see
[`docs/general-extractor.md`](../../docs/general-extractor.md).

---

## Things to explore

**Can the existing extractor handle logical models?**

- Read through `extractor.py` and identify where it makes assumptions about the output being a
  standard FHIR resource type. Look at `_RESOURCE_STATUS_DEFAULTS`, `_RESOURCE_REQUIRED_FIELDS`,
  and `_get_or_create`.
- Would the extractor work at all if the `.definition` target was a logical model element path?
  What would it produce?

**What would need to change?**

- For logical model targets, there is no `status`, no mandatory `code`, and no class-based
  resource skeleton - the output is just a JSON object whose shape mirrors the logical model.
- How would you restructure `_process_group` and `_make_bundle` to produce a plain JSON object
  instead of a FHIR resource?
- The server wraps the result in a `Binary` resource. Should the Python extractor do the same,
  or just return the raw JSON?

**Prototype an extension**

- Try running the extractor against `data/samples/homehosp_q_opat_logicalmodel.json` +
  `data/samples/homehosp_qr_opat.json`. What happens? What errors appear?
- If you have time, sketch or implement the changes needed to make it produce correct logical
  model JSON.

**Compare with server output**

- If you got a successful `$extract` response from the Tiro server in the base test, decode the
  Binary and compare its JSON with what the Python extractor produces (or would produce). Are
  the element paths equivalent?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`. For code or modified Python files,
put them in `submissions/prototypes/{your-handle}/`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
