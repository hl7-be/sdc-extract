import logging
import os
from pathlib import Path

# Load .env from apps/api/ regardless of working directory or which venv is active.
_ENV_FILE = Path(__file__).parent.parent.parent / ".env"
try:
    from dotenv import load_dotenv
    load_dotenv(_ENV_FILE)
except ImportError:
    # python-dotenv not available — fall back to manual parsing
    if _ENV_FILE.exists():
        for line in _ENV_FILE.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())

logging.basicConfig(level=logging.INFO)
_startup_log = logging.getLogger(__name__)
_startup_log.info("FHIR default server : %s", os.environ.get("FHIR_BASE_URL", "(not set — using HAPI public)"))
_sa = os.environ.get("GOOGLE_SERVICE_ACCOUNT_FILE", "")
_startup_log.info("Google service account: %s", _sa if _sa else "(not set — using API key / no auth)")

import requests
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from src.core.processor import QuestionnaireProcessor
from src.server.fhir_client import (
    update_questionnaire,
    get_latest_version,
    get_all_versions,
    get_version,
    get_questionnaire_mapping_status,
    get_questionnaire_response_by_questionnaire_id,
    list_questionnaires_from_fhir,
    ALLOWED_STATUSES,
    FhirConfig,
    get_recent_questionnaire_responses
)
from src.server.fhir_validator import get_structure_definition, extract_valid_paths


def get_fhir_config(request: Request) -> FhirConfig:
    LOGGER.info("Headers received: %s", {k: v for k, v in request.headers.items() if "fhir" in k.lower()})
    return FhirConfig(
        base_url=request.headers.get("X-FHIR-Base-URL", "") or "",
        api_key=request.headers.get("X-FHIR-API-Key", "") or "",
    )

LOGGER = logging.getLogger(__name__)

SNOMED_URL = os.environ.get("SNOMED_URL", "")
SNOMED_CERT_PATH = os.environ.get("SNOMED_CERT_PATH")

app = FastAPI(title="FHIR Questionnaire mapper")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    LOGGER.exception("Unhandled exception")
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


prefix = "/api/v1"


@app.get(prefix + "/hello")
def say_hello():
    return 'Hello, this is the FHIR Questionnaire Mapper API!'


@app.get(prefix + "/list_questionnaires")
def list_questionnaires(request: Request):
    try:
        config = get_fhir_config(request)
        return list_questionnaires_from_fhir(config)
    except Exception as e:
        LOGGER.exception("Error in list_questionnaires")
        raise HTTPException(status_code=500, detail=str(e))


@app.put(prefix + "/questionnaire/status/{status}")
def update_questionnaire_and_status(
        status: str,
        questionnaire: dict,
        request: Request,
):
    if status.upper() not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Must be one of {ALLOWED_STATUSES}",
        )
    try:
        return update_questionnaire(questionnaire, status, get_fhir_config(request))
    except ValueError as e:
        detail = e.args[0]
        if isinstance(detail, dict) and "validation_errors" in detail:
            raise HTTPException(status_code=422, detail=detail)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get(prefix + "/questionnaire/{q_id}")
def get_latest(q_id: str, request: Request):
    try:
        return get_latest_version(q_id, get_fhir_config(request))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get(prefix + "/questionnaire/{q_id}/_history")
def get_history(q_id: str, request: Request):
    try:
        return get_all_versions(q_id, get_fhir_config(request))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get(prefix + "/questionnaire/{q_id}/_history/{version_id}")
def get_version_endpoint(q_id: str, version_id: str, request: Request):
    try:
        return get_version(q_id, version_id, get_fhir_config(request))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post(prefix + "/questionnaire/calculate-mapping-status")
def calculate_mapping_status(questionnaire: dict):
    try:
        status = get_questionnaire_mapping_status(questionnaire)
        return {"status": status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get(prefix + "/fhir-elements")
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


@app.get(prefix + "/questionnaire/{q_id}/response")
def get_questionnaire_response(
        q_id: str,
        request: Request,
):
    """
    Find the most recent QuestionnaireResponse that references Questionnaire/{q_id}.
    Used by the frontend "show example data" toggle to prefill LForms.
    Returns 404 if no QuestionnaireResponse exists for this questionnaire.
    """
    try:
        config = get_fhir_config(request)
        qr = get_questionnaire_response_by_questionnaire_id(q_id, config)
        if qr is None:
            raise HTTPException(status_code=404, detail=f"No QuestionnaireResponse found for Questionnaire/{q_id}")
        return qr
    except HTTPException:
        raise
    except Exception as e:
        LOGGER.exception("Error fetching example QuestionnaireResponse for Questionnaire/%s", q_id)
        raise HTTPException(status_code=500, detail=str(e))


@app.post(prefix + "/questionnaire-response/extract")
def extract_questionnaire_response_from_body(
        body: dict,
        persist: bool = False,
        request: Request = None,
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
        config = get_fhir_config(request)
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


@app.get(prefix + "/questionnaire-response/{qr_id}/extract")
def extract_questionnaire_response(
        qr_id: str,
        persist: bool = False,
        request: Request = None,
):
    """
    Run definition-based extraction for a QuestionnaireResponse.

    Query params:
        persist (bool, default False): When True, POST the Bundle to the store.

    Returns::

        { "bundle": { ... }, "errors": [ ... ] }
    """
    try:
        config = get_fhir_config(request)
        processor = QuestionnaireProcessor(config)
        bundle, errors = processor.extract(qr_id=qr_id, persist=persist)
        return {"bundle": bundle, "errors": errors}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        LOGGER.exception("Error extracting QuestionnaireResponse/%s", qr_id)
        raise HTTPException(status_code=500, detail=str(e))


@app.get(prefix + "/search_snomed_concept")
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


# uvicorn src.server.app:app --reload --port 8000
if __name__ == "__main__":
    uvicorn.run("src.server.app:app", host="127.0.0.1", port=8000, reload=True)
