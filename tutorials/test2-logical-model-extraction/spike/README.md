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

- Full QR walk reproducing `expected.json` byte-for-byte (slicing, repeating cardinality).
- Integration with `cqf-fhir-cr`'s bundle assembly and HAPI server wiring.
