# FHIR SDC: Integrity and Lifecycle of Extracted Resources

FHIR SDC `$extract` enables form-driven resource creation. It's a powerful mechanism but a challenge to ensure
consistency - both schematic and referential. The guardrails you typically have when resources are constructed in code
are completely absent here.

On top of that, the form lifecycle complicates things. Most form-based solutions allow amendments; in such scenarios,
the processing pipeline must be idempotent to avoid duplication of resources.

---

## Validation

### 1. FHIR Resource Validation

- **Structural:** well-formed JSON, cardinality, required elements.
- **Profile constraints:** conformance to BeFHIR Core, BeMedication, registry-specific profiles.
- **Terminology:** coded values against bound ValueSets. Note that profile bindings override base FHIR bindings.

### 2. Bundle Referential Validation

Internal references (`urn:uuid:` placeholders inside `Reference.reference`) must resolve to a `Bundle.entry.fullUrl` of
the right resource type.

Profile-aware: `DiagnosticReport.result` must resolve to an `Observation` conforming to the expected profile, not just
any `Observation`.

`Bundle.entry.request.method` / `url` / `ifNoneExist` must be coherent with each other:

- `POST` without `id`
- `PUT` with `id` matching the URL
- `ifNoneExist` only on `POST`

### 3. Common Business Logic for SDC

- **Patient compartment coherence:** every extracted clinical resource must belong to the same Patient compartment. FHIR
  formalizes this via [CompartmentDefinition/patient](https://hl7.org/fhir/R4/compartmentdefinition-patient.html), which
  specifies per resource type which search parameter anchors it to a Patient (`Observation → subject`,
  `AllergyIntolerance → patient`, `MedicationStatement → subject`, etc.).

- **Enforce Provenance tracking:** each `$extract` run emits a `Provenance` with:
    - `target` = the list of extracted resources
    - `entity[role=source].what` = the `QuestionnaireResponse`
    - `activity` = `DERIVE`
    - `agent` carrying both the clinician (`Practitioner`) and the extracting software (`Device`)

### 4. Custom Business Logic

Registries typically have custom rules. Those could be expressed as:

- FHIRPath constraints on profiles
- CQL libraries producing `DetectedIssue` resources

---

## Idempotency and Lineage

Multiple `$extract` runs shouldn't create duplicates. One mechanism to solve this is using **upsert via
conditional `PUT`**:

| Matches    | Outcome                   |
|------------|---------------------------|
| 0 matches  | Create                    |
| 1 match    | Update with version bump  |
| >1 matches | `412 Precondition Failed` |

The conditions are used to match resources related to previous extraction attempts. Two approaches differ in how the
receiver identifies prior outputs:

### Option A - Provenance + Reverse Chaining

Each `$extract` run emits a `Provenance` (per layer 3) with `entity[role=source].what=QR` and
`target=[extracted resources]`. Match prior runs via reverse chaining (`_has`) on `Provenance`, with a natural-key
discriminator:

```
PUT Observation?_has:Provenance:target:entity=QuestionnaireResponse/qr-123&code=8480-6
```

No identifier convention required, but the server must support `_has` in conditional ops:

| Server                  | `_has` support |
|-------------------------|----------------|
| HAPI                    | ✓              |
| Firely                  | ✓              |
| Google Cloud Healthcare | ✗              |
| Azure                   | Partial        |

### Option B - Identifier Convention

Each extracted resource carries an identifier encoding the source `linkId`:

```json
"identifier": [
{
"system": "https://tiro.health/fhir/sid/qr-linkid",
"value": "{QuestionnaireResponse.id}-{linkId}"
}
]
```

Match via:

```
PUT Observation?identifier=https://tiro.health/fhir/sid/qr-linkid|...
```

### Deleted-Answer Reconciliation

When QR v2 omits an answer that v1 had, the v1 resource has no counterpart in the new extraction and won't be touched by
either upsert.

> **Open problem:** Participants are invited to think about solutions to handle this. A possible approach is to move to
> a **conditional delete** instead of update, followed by plain create operations.