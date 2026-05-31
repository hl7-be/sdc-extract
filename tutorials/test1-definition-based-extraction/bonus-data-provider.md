# Bonus - Data provider: Python extractor

**For:** EHR vendors, care software developers, anyone without a FHIR server that supports `$extract` natively

This bonus is open-ended. There is no single right answer. The goal is to explore, discuss,
and optionally improve.

---

## Context

You have a `Questionnaire` and a completed `QuestionnaireResponse`, and you need the extracted
FHIR resources - but you don't have a fully-featured FHIR server or facade that implements the
`$extract` operation for you. This is common with the Google Healthcare FHIR API (which does not
expose `$extract`), or with a thin FHIR facade over a proprietary database. There are two ways to
get the extraction done.

**Approach 1 — embed the extractor in your backend.** The repository contains a standalone Python
implementation of definition-based extraction at
[`apps/Q2Rmapper/api/src/core/extractor.py`](../../apps/Q2Rmapper/api/src/core/extractor.py). It
is a self-contained module: hand it the Questionnaire and QuestionnaireResponse, get back a
`Bundle`, no network involved. For how it works and how to run it locally, see
[`docs/general-extractor.md`](../../docs/general-extractor.md).

**Approach 2 — delegate to an `$extract` service over HTTP.** Instead of carrying the logic
yourself, your backend can call a separate service that already implements the operation. That
service can run wherever you like - a Tiro container in your own infrastructure (the
[`apps/tiro_sdc_server`](../../apps/tiro_sdc_server) testserver in this repo runs exactly that way)
or the hosted Tiro.health server. Your backend just forwards the `Questionnaire` +
`QuestionnaireResponse` and persists the `Bundle` that comes back.

Embedding keeps everything in-process with no network hop; delegating keeps the extraction logic -
and its future updates - out of your codebase, at the cost of an HTTP call and its latency.

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
- Embed vs. delegate: when would you bundle this extractor into your backend, and when would you
  instead call a separate `$extract` service over HTTP (a Tiro container you host yourself, or the
  hosted Tiro.health server)? Weigh things like deployment footprint, latency, and who owns the
  extraction logic.
- How would you handle errors - should a problem with one answer block the whole Bundle, or just
  skip the affected resource?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
