#!/bin/bash
# Extract the OPAT QuestionnaireResponse and POST the resulting bundle
# (including dummy Patient and Practitioner) as a single transaction to the
# local Tiro testserver (http://localhost:8000 by default).
# Override the target with TIRO_BASE_URL in your environment or in .env.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"
DUMMY_DIR="$ROOT_DIR/data/dummy"

: "${TIRO_BASE_URL:=http://localhost:8000/api/v1}"
[ -f "$ROOT_DIR/.env" ] && source "$ROOT_DIR/.env"

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
  "${TIRO_BASE_URL}/QuestionnaireResponse/\$extract" \
  --header 'Accept: application/fhir+json' \
  --header 'Content-Type: application/fhir+json' \
  --data "@${PARAMS_TMP}" \
  > "$BUNDLE_TMP"

echo "=== Posting transaction bundle (extracted resources + dummy patient/practitioner) ===" >&2
python3 "${ROOT_DIR}/scripts/merge_bundle.py" "$BUNDLE_TMP" "$PATIENT_FILE" "$PRACTITIONER_FILE" \
  | curl --location \
      "${TIRO_BASE_URL}" \
      --header 'Accept: application/fhir+json' \
      --header 'Content-Type: application/fhir+json' \
      --data @-
