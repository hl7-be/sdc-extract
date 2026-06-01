#!/bin/bash

# --- Configuration Variables ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/.env"
QUESTIONNAIRE_ID="your-questionnaire-id"

# --- API Execution ---
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire/${QUESTIONNAIRE_ID}?api_key=${API_KEY}"