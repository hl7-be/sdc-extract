#!/bin/bash
# Run logical-model $extract for the oncology scenario against the local Tiro
# testserver (apps/tiro_sdc_extract on http://localhost:8000 by default).
# Prerequisite: run upload_logicalmodel_structuredefinitions.sh first.
# Override the target with TIRO_BASE_URL in your environment or in a .env file
# at the repo root.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"

: "${TIRO_BASE_URL:=http://localhost:8000/api/v1}"
[ -f "$ROOT_DIR/.env" ] && source "$ROOT_DIR/.env"

Q_FILE="${DATA_DIR}/homehosp_q_onco_logicalmodel.json"
QR_FILE="${DATA_DIR}/homehosp_qr_onco.json"

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

{
  printf '{"resourceType":"Parameters","parameter":[{"name":"questionnaire-response","resource":'
  cat "$QR_FILE"
  printf '},{"name":"questionnaire","resource":'
  cat "$Q_FILE"
  printf '}]}'
} > "$TMPFILE"

# Accept: application/json returns the raw decoded logical-model instance.
# Use application/fhir+json instead to receive a FHIR Binary envelope.
echo "=== \$extract (logical model — Q + QR as Parameters) ==="
curl --location \
  "${TIRO_BASE_URL}/QuestionnaireResponse/\$extract" \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/fhir+json' \
  --data "@${TMPFILE}"
