#!/bin/bash

# --- Configuration Variables ---
TENANT_ID="your-tenant-id"
QUESTIONNAIRE="your-json-payload-for-questionnaire"
API_KEY="your-secret-api-key"

# --- API Execution ---
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire?api_key=${API_KEY}" \
--header 'Content-Type: application/json' \
--data "${QUESTIONNAIRE}"