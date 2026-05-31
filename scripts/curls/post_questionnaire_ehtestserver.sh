#!/bin/bash

# --- Configuration Variables ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/.env"
QUESTIONNAIRE="your-json-payload-for-questionnaire"

# --- API Execution ---
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire?api_key=${API_KEY}" \
--header 'Content-Type: application/json' \
--data "${QUESTIONNAIRE}"