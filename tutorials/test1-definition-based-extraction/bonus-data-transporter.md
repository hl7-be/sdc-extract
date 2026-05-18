# Bonus - Data transporter: validation and lifecycle

**For:** FHIR server infrastructure teams, integration engineers

This bonus is open-ended. There is no single right answer. The goal is to explore, discuss,
and optionally prototype.

---

## Context

When a Bundle of extracted resources is POSTed to a FHIR server, several things need to go right
beyond "HTTP 200 received":

- The resources must be structurally valid and conform to the required profiles.
- If the same QuestionnaireResponse is submitted twice (e.g. after an amendment), the second
  extraction should update - not duplicate - the previously created resources.
- When answers are deleted from a QR in a later version, the corresponding resources should be
  retracted or flagged.
- Provenance should be traceable from any extracted resource back to the originating
  QuestionnaireResponse.

The full design discussion is in
[`docs/sdc-extract-integrity-and-lifecycle.md`](../../docs/sdc-extract-integrity-and-lifecycle.md).

---

## Things to explore

**Validation**

- After POSTing the Bundle in the base test, validate one of the returned resources against the
  Belgian FHIR profiles (BeFHIR Core, BeMedication). What tooling would you use?
- What validation does the eHealth testserver apply on ingest? Does it reject invalid resources,
  or accept them and flag later?

**Idempotency**

- Run the base test `$extract` + Bundle POST twice for the same QR. What happens on the server?
  Are there duplicate resources?
- The lifecycle doc describes two approaches for upsert: Provenance + reverse chaining (Option A)
  and identifier convention (Option B). Which is more realistic for the servers you are using?
  Which servers support `_has` (reverse chaining) in conditional operations?

**Lifecycle and retraction**

- If a QR is amended and a previously filled answer is removed, how should the extracted resource
  be handled? Is deletion the right answer, or a status change (e.g. `Observation.status = "entered-in-error"`)?
- The lifecycle doc raises this as an open problem. What would you do?

**Provenance**

- What would a `Provenance` resource look like that links an extracted `Observation` back to its
  source `QuestionnaireResponse`? Try constructing one manually.
- Can you query for "all resources extracted from QR X" on the eHealth testserver using
  Provenance and reverse chaining?

---

## Share your findings

Copy `submissions/TEMPLATE.md`, rename it to `{your-github-handle-or-team}.md`, fill in what
you tried and found, and open a pull request targeting `main`.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process.
