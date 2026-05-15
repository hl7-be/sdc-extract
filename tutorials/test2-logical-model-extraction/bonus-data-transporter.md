# Bonus - Data transporter: validation and lifecycle for logical model output

**For:** FHIR server infrastructure teams, integration engineers

This bonus is open-ended. There is no single right answer.

---

## Context

Test 2 produces a `Binary` resource containing JSON conforming to a custom logical model. This
raises different infrastructure questions compared to Test 1:

- The output is not a standard FHIR resource - it cannot be natively indexed or searched by a
  FHIR server.
- Validation cannot rely on standard FHIR profiles; it must be done against the logical model
  StructureDefinition.
- How would a receiving system store, retrieve, and update Binary payloads over time?

The general design discussion (which focuses on FHIR resources) is in
[`docs/sdc-extract-integrity-and-lifecycle.md`](../../docs/sdc-extract-integrity-and-lifecycle.md).
This bonus asks you to extend that thinking to the logical model case.

---

## Things to explore

**Validation**

- How do you validate a JSON object against a FHIR logical model StructureDefinition? What
  tooling supports this?
- Could you POST the decoded JSON to the Tiro server as a validation request? What response do
  you get?

**Storage and retrieval**

- A `Binary` resource is opaque to FHIR search - you cannot query `GET /Binary?patient=X`.
  How would a downstream system find "all logical model instances for patient X"?
- Would you store the Binary alongside a `DocumentReference`? A `Basic` resource? Something else?
  What are the trade-offs?

**Idempotency**

- If the same QR is extracted twice, how would you detect that the Binary already exists and
  update it rather than creating a duplicate?
- The identifier convention (Option B) from the lifecycle doc assigns each extracted resource an
  identifier derived from the QR id and linkId. Can this apply to a Binary resource? How?

**Lifecycle**

- If a QR is amended, the Binary needs to be regenerated. How would you track which Binary
  corresponds to which QuestionnaireResponse?
- Is Provenance applicable here the same way it is for FHIR resources? What would a Provenance
  resource for a Binary look like?
