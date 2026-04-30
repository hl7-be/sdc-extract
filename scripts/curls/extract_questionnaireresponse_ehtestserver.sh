#!/bin/bash

# --- Configuration Variables ---
TENANT_ID="your-tenant-id"
QUESTIONNAIRE_RESPONSE="your-json-payload-for-questionnaire-response"
API_KEY="your-secret-api-key"

# --- API Execution ---
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/QuestionnaireResponse/$extract?api_key=${API_KEY}" \
--header 'Accept: application/fhir+json' \
--header 'Content-Type: application/fhir+json' \
--data "${QUESTIONNAIRE_RESPONSE}"