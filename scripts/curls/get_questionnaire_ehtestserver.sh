#!/bin/bash

# --- Configuration Variables ---
TENANT_ID="your-tenant-id"
QUESTIONNAIRE_ID="your-questionnaire-id"
API_KEY="your-secret-api-key"

# --- API Execution ---
curl --location "https://hapi.fhir-testserver.be/fhir/${TENANT_ID}/Questionnaire/${QUESTIONNAIRE_ID}?api_key=${API_KEY}"