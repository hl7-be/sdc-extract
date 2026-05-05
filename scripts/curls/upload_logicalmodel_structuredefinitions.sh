#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"

# shellcheck source=../../.env
source "$ROOT_DIR/.env"

SD_OPAT="${DATA_DIR}/StructureDefinition-opat-continuous-infusion-questionnaire.json"
SD_ONCO="${DATA_DIR}/StructureDefinition-onco-trastuzumab-questionnaire.json"

echo "=== Uploading OPAT StructureDefinition ==="
curl --location --request PUT \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/StructureDefinition/opat-continuous-infusion-questionnaire?api_key=${API_KEY}" \
  --header 'Content-Type: application/fhir+json' \
  --data "@${SD_OPAT}"

echo ""
echo "=== Uploading ONCO StructureDefinition ==="
curl --location --request PUT \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/StructureDefinition/onco-trastuzumab-questionnaire?api_key=${API_KEY}" \
  --header 'Content-Type: application/fhir+json' \
  --data "@${SD_ONCO}"

echo ""
echo "=== Done. Run working_extraction_opat_logicalmodel.sh / working_extraction_onco_logicalmodel.sh to test extraction. ==="
