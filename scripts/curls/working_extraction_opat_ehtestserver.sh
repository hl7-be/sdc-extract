#!/bin/bash
# Run definition-based $extract for the OPAT scenario against the eHealth
# testserver (HAPI). Requires TENANT_ID and API_KEY in .env.
# For the Tiro testserver variant (no credentials needed), see
# working_extraction_opat.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"

# shellcheck source=../../.env
source "$ROOT_DIR/.env"

Q_FILE="${DATA_DIR}/homehosp_q_opat_definitions.json"
QR_FILE="${DATA_DIR}/homehosp_qr_opat.json"

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

{
  printf '{"resourceType":"Parameters","parameter":[{"name":"questionnaire-response","resource":'
  cat "$QR_FILE"
  printf '},{"name":"questionnaire","resource":'
  cat "$Q_FILE"
  printf '}]}'
} > "$TMPFILE"

echo "=== \$extract (Q + QR as Parameters, eHealth testserver) ==="
curl --location \
  "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/QuestionnaireResponse/\$extract?api_key=${API_KEY}" \
  --header 'Accept: application/fhir+json' \
  --header 'Content-Type: application/fhir+json' \
  --data "@${TMPFILE}"
