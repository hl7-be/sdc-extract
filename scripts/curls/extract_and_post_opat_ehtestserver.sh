#!/bin/bash
# Extract the OPAT QuestionnaireResponse and POST the resulting bundle
# (including dummy Patient and Practitioner) as a single transaction to the
# eHealth testserver (HAPI). Requires TENANT_ID and API_KEY in .env.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"
DUMMY_DIR="$ROOT_DIR/data/dummy"

# shellcheck source=../../.env
source "$ROOT_DIR/.env"

Q_FILE="${DATA_DIR}/homehosp_q_opat_definitions.json"
QR_FILE="${DATA_DIR}/homehosp_qr_opat.json"
PATIENT_FILE="${DUMMY_DIR}/dummy-patient-opat.json"
PRACTITIONER_FILE="${DUMMY_DIR}/dummy-practitioner.json"

PARAMS_TMP=$(mktemp)
BUNDLE_TMP=$(mktemp)
trap 'rm -f "$PARAMS_TMP" "$BUNDLE_TMP"' EXIT

# Build Parameters payload for $extract
{
  printf '{"resourceType":"Parameters","parameter":[{"name":"questionnaire-response","resource":'
  cat "$QR_FILE"
  printf '},{"name":"questionnaire","resource":'
  cat "$Q_FILE"
  printf '}]}'
} > "$PARAMS_TMP"

echo "=== Calling \$extract ===" >&2
curl --silent --location \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/QuestionnaireResponse/\$extract?api_key=${API_KEY}" \
  --header 'Accept: application/fhir+json' \
  --header 'Content-Type: application/fhir+json' \
  --data "@${PARAMS_TMP}" \
  > "$BUNDLE_TMP"

echo "=== Posting transaction bundle (extracted resources + dummy patient/practitioner) ===" >&2
python3 "${ROOT_DIR}/scripts/merge_bundle.py" "$BUNDLE_TMP" "$PATIENT_FILE" "$PRACTITIONER_FILE" \
  | curl --location \
      "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}?api_key=${API_KEY}" \
      --header 'Accept: application/fhir+json' \
      --header 'Content-Type: application/fhir+json' \
      --data @-
