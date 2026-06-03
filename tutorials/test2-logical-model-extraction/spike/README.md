# Element-model spike

100-line Java probe that verifies the central bet of [`bonus-developers-hapi-fork.md`](../bonus-developers-hapi-fork.md): `org.hl7.fhir.r4.elementmodel.Element` can represent any logical-model instance driven only by the SD, with no generated POJO.

## Run

```bash
# 1. Fetch the FHIR validator jar (contains the org.hl7.fhir.r4.* classes)
curl -L -o /tmp/validator_cli.jar \
  https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar

# 2. Compile and run
javac -cp /tmp/validator_cli.jar Spike.java

FIX=../../../apps/tiro_sdc_extract/tests/fixtures/opat_logicalmodels
java -cp "/tmp/validator_cli.jar:." Spike "$FIX/sd/opat-continuous-infusion-questionnaire.json"
```

## Expected output

```
[ok] Loaded SD: kind=LOGICAL url=http://hl7belgium.org/...
[ok] Manager.build(ctx, sd) returned Element: fhirType=opat-continuous-infusion-questionnaire
[ok] Manager.compose on empty root: {"resourceType":"opat-continuous-infusion-questionnaire"}
[ok] Set medicationStorageRemarks via setChildValue chain
[ok] Manager.compose after setChildValue attempt:
{"resourceType":"opat-continuous-infusion-questionnaire","nursingAssessment":{"storage":{"medicationStorageRemarks":"Stored at 4C"}}}
```

## What is verified

| Capability | Result |
|---|---|
| `Manager.build(ctx, sd)` on `kind=LOGICAL` | works, no exception |
| Element knows its logical-model type | `fhirType=<lm-name>` |
| Compose empty Element to JSON | `{"resourceType":"<lm-name>"}` |
| `setChildValue` auto-creates intermediate complex parents | yes |
| Serialize populated tree to JSON | correct nesting |

## What is not verified

- Full QR walk reproducing `expected.json` byte-for-byte (slicing).
- Integration with `cqf-fhir-cr`'s bundle assembly and HAPI server wiring.

## SpikeComplex: complex types and a populated IWorkerContext

`SpikeComplex.java` extends the bet to a synthetic LM (`complex-lm.json`) that uses `CodeableConcept`, `Quantity`, and repeating cardinality. Loads r4 core via `SimpleWorkerContext.fromPackage(NpmPackage.fromFolder(...))`.

```bash
javac -cp /tmp/validator_cli.jar SpikeComplex.java
java -cp "/tmp/validator_cli.jar:." SpikeComplex \
  "$HOME/.fhir/packages/hl7.fhir.r4.core#4.0.1" complex-lm.json
```

Expected output:

```json
{"resourceType":"ComplexLM",
 "code":{"text":"Lab observation","coding":[{"code":"12345-6","display":"Some lab","system":"http://loinc.org"}]},
 "qty":{"unit":"mmol/L","system":"http://unitsofmeasure.org","code":"mmol/L","value":5.4},
 "note":["first note","second note"]}
```

What it adds to the bet:

| Capability | Result |
|---|---|
| Load r4 core via `SimpleWorkerContext.fromPackage` | works |
| CodeableConcept with nested Coding array | correct JSON shape |
| Quantity with value coerced to number (not string) | works |
| Repeating `0..*` serializes as JSON array | works |
| `Element.makeProperty(hash, name)` for complex children | works |

### Precondition: snapshotted SD

`Manager.build` requires `StructureDefinition.snapshot.element[]` to be populated. A pure differential fails. HAPI's upload pipeline normally generates snapshots, so this is usually handled. The fork depends on this precondition, it does not provide it.
