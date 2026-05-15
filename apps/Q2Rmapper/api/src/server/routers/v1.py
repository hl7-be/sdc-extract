import logging
import os

import requests
from fastapi import APIRouter, Depends, HTTPException, Request

from src.core.processor import QuestionnaireProcessor
from src.server.dependencies import get_fhir_config
from src.server.fhir_client import (
    ALLOWED_STATUSES,
    FhirConfig,
    get_all_versions,
    get_latest_version,
    get_questionnaire_mapping_status,
    get_questionnaire_response_by_questionnaire_id,
    get_version,
    list_questionnaires_from_fhir,
    update_questionnaire,
)
from src.server.fhir_validator import extract_valid_paths, get_structure_definition

LOGGER = logging.getLogger(__name__)

SNOMED_URL = os.environ.get("SNOMED_URL", "")
SNOMED_CERT_PATH = os.environ.get("SNOMED_CERT_PATH")

router = APIRouter()


@router.get("/hello")
def say_hello():
    return 'Hello, this is the FHIR Questionnaire Mapper API!'


@router.get("/list_questionnaires")
def list_questionnaires(config: FhirConfig = Depends(get_fhir_config)):
    try:
        return list_questionnaires_from_fhir(config)
    except Exception as e:
        LOGGER.exception("Error in list_questionnaires")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/questionnaire/status/{status}")
def update_questionnaire_and_status(
    status: str,
    questionnaire: dict,
    config: FhirConfig = Depends(get_fhir_config),
):
    if status.upper() not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Must be one of {ALLOWED_STATUSES}",
        )
    try:
        return update_questionnaire(questionnaire, status, config)
    except ValueError as e:
        detail = e.args[0]
        if isinstance(detail, dict) and "validation_errors" in detail:
            raise HTTPException(status_code=422, detail=detail)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/questionnaire/{q_id}")
def get_latest(q_id: str, config: FhirConfig = Depends(get_fhir_config)):
    try:
        return get_latest_version(q_id, config)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/questionnaire/{q_id}/_history")
def get_history(q_id: str, config: FhirConfig = Depends(get_fhir_config)):
    try:
        return get_all_versions(q_id, config)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/questionnaire/{q_id}/_history/{version_id}")
def get_version_endpoint(q_id: str, version_id: str, config: FhirConfig = Depends(get_fhir_config)):
    try:
        return get_version(q_id, version_id, config)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/questionnaire/calculate-mapping-status")
def calculate_mapping_status(questionnaire: dict):
    try:
        status = get_questionnaire_mapping_status(questionnaire)
        return {"status": status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/fhir-elements")
def get_fhir_elements(resourceType: str):
    """Returns a list of valid structural element paths for a given FHIR resource type."""
    try:
        struct_def = get_structure_definition(resourceType)

        if not struct_def:
            raise HTTPException(
                status_code=404,
                detail=f"StructureDefinition for {resourceType} not found on HAPI or HL7."
            )

        paths = extract_valid_paths(struct_def)

        if not paths:
            raise HTTPException(
                status_code=404,
                detail=f"No elements found in the definition of {resourceType}."
            )

        return paths

    except HTTPException as he:
        raise he
    except Exception as e:
        LOGGER.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error fetching FHIR elements")


@router.get("/questionnaire/{q_id}/response")
def get_questionnaire_response(
    q_id: str,
    config: FhirConfig = Depends(get_fhir_config),
):
    """
    Find the most recent QuestionnaireResponse that references Questionnaire/{q_id}.
    Used by the frontend "show example data" toggle to prefill LForms.
    Returns 404 if no QuestionnaireResponse exists for this questionnaire.
    """
    try:
        qr = get_questionnaire_response_by_questionnaire_id(q_id, config)
        if qr is None:
            raise HTTPException(status_code=404, detail=f"No QuestionnaireResponse found for Questionnaire/{q_id}")
        return qr
    except HTTPException:
        raise
    except Exception as e:
        LOGGER.exception("Error fetching example QuestionnaireResponse for Questionnaire/%s", q_id)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/questionnaire-response/extract")
def extract_questionnaire_response_from_body(
    body: dict,
    persist: bool = False,
    config: FhirConfig = Depends(get_fhir_config),
):
    """
    Preview extraction by submitting a Questionnaire + QuestionnaireResponse body directly.

    Expected body::

        {
            "questionnaire":         { ... },   // FHIR Questionnaire with SDC annotations
            "questionnaireResponse": { ... }    // FHIR QuestionnaireResponse from LForms
        }

    Query params:
        persist (bool, default False): When True, POST the resulting Bundle to the store.

    Returns::

        { "bundle": { ... }, "errors": [ ... ] }
    """
    try:
        processor = QuestionnaireProcessor(config)

        if "questionnaireResponse" in body:
            qr = body["questionnaireResponse"]
            questionnaire = body.get("questionnaire")
        else:
            qr = body
            questionnaire = None

        bundle, errors = processor.extract_from_body(qr=qr, persist=persist, questionnaire=questionnaire)
        return {"bundle": bundle, "errors": errors}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        LOGGER.exception("Error in preview extraction from body")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/questionnaire-response/{qr_id}/extract")
def extract_questionnaire_response(
    qr_id: str,
    persist: bool = False,
    config: FhirConfig = Depends(get_fhir_config),
):
    """
    Run definition-based extraction for a QuestionnaireResponse.

    Query params:
        persist (bool, default False): When True, POST the Bundle to the store.

    Returns::

        { "bundle": { ... }, "errors": [ ... ] }
    """
    try:
        processor = QuestionnaireProcessor(config)
        bundle, errors = processor.extract(qr_id=qr_id, persist=persist)
        return {"bundle": bundle, "errors": errors}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        LOGGER.exception("Error extracting QuestionnaireResponse/%s", qr_id)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search_snomed_concept")
def search_snomed_concept(query: str, ecl: str | None = None):
    """
    Search Snowstorm using FHIR $expand + ECL.
    Returns first 10 SNOMED CT concepts.
    If ECL is provided, limit results to that hierarchy (e.g. <<123037004).
    Configure via environment variables: SNOMED_URL, SNOMED_CERT_PATH.
    """
    if not SNOMED_URL:
        LOGGER.warning("SNOMED_URL not configured; returning empty results")
        return []

    ecl_expression = ecl if ecl else "<<138875005"
    params = {
        "url": f"http://snomed.info/sct?fhir_vs=ecl/{ecl_expression}",
        "filter": query,
        "_count": 10,
    }
    verify = SNOMED_CERT_PATH if SNOMED_CERT_PATH else True

    try:
        response = requests.get(SNOMED_URL, params=params, verify=verify)
        response.raise_for_status()
    except requests.RequestException as e:
        LOGGER.warning("SNOMED search failed: %s", e)
        return []

    vs = response.json()
    items = []
    for entry in vs.get("expansion", {}).get("contains", []):
        items.append({
            "id": entry.get("code"),
            "display": entry.get("display"),
            "system": entry.get("system"),
        })
    return items
