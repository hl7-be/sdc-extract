# Bonus - Data provider: Python extractor

**For:** EHR vendors, care software developers, anyone without a FHIR server that supports `$extract` natively

This bonus is open-ended. There is no single right answer. The goal is to explore, discuss,
and optionally improve.

---

## Context

The repository contains a standalone Python implementation of definition-based extraction at
[`apps/Q2Rmapper/api/src/core/extractor.py`](../../apps/Q2Rmapper/api/src/core/extractor.py).
It is designed for environments where calling `$extract` on a server is not possible - for
example, when using the Google Healthcare FHIR API (which does not expose `$extract`), or when
building a FHIR facade that needs to assemble resources client-side.

For a detailed description of how the extractor works and how to run it locally without any
server, see [`docs/general-extractor.md`](../../docs/general-extractor.md).

---

## Things to explore

**Understand the extractor**

- Read through `extractor.py` and trace what happens for one of the sample Questionnaire/QR pairs.
  Does the output Bundle match what you got from the server in the base test?
- What edge cases are handled? What might it miss?

**Test it locally**

- Follow the local testing recipe in [`docs/general-extractor.md`](../../docs/general-extractor.md)
  to run the extractor against the OPAT or Oncology samples without any server involved.
- Compare the Bundle it produces with the one the `$extract` call returned. Are they equivalent?
  Are there differences in how fixed values or coded fields are represented?

**Look for bugs or gaps**

- The extractor is not guaranteed to be complete or bug-free. Are there FHIR element types or
  extension patterns it does not handle?
- What happens with components? There are sample files with blood pressure components in
  `data/samples/` (`homehosp_q_opat_definitions_bloodpressurecomponents.json`). Does the
  extractor produce `Observation.component` correctly?

**Think about integration**

- If you were integrating this into an EHR system that has a FHIR facade but not an actual FHIR server, what
  would need to change? How would you POST the resulting Bundle?
- How would you handle errors - should a problem with one answer block the whole Bundle, or just
  skip the affected resource?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
