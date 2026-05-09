import logging

from fastapi import APIRouter
from fhir_sdc import extract as sdc_extract

from src.server.fhir_parameters import (
    load_questionnaire,
    load_questionnaire_response,
)
from src.server.structure_definitions import get_structure_definition_loader
from src.server.utils import (
    FhirJSONResponse,
    OperationOutcomeException,
    bundle_collection,
)

LOGGER = logging.getLogger(__name__)

router = APIRouter()


@router.get("/metadata", response_class=FhirJSONResponse)
def capability_statement():
    """FHIR conformance endpoint — describes this server's capabilities."""
    return {
        "resourceType": "CapabilityStatement",
        "status": "active",
        "date": "2026-05-07",
        "kind": "instance",
        "software": {"name": "fhirquestionnaire-mapper", "version": "0.1.0"},
        "fhirVersion": "4.0.1",
        "format": ["application/fhir+json"],
        "rest": [
            {
                "mode": "server",
                "resource": [
                    {
                        "type": "QuestionnaireResponse",
                        "operation": [
                            {
                                "name": "extract",
                                "definition": "http://hl7.org/fhir/uv/sdc/OperationDefinition/QuestionnaireResponse-extract",
                            }
                        ],
                    }
                ],
            }
        ],
    }


@router.post("/QuestionnaireResponse/$extract", response_class=FhirJSONResponse)
def questionnaire_response_extract(parameters: dict):
    """
    FHIR SDC `$extract` operation — definition-based extraction.

    Body must be a FHIR `Parameters` resource with:
      - `questionnaire-response` (required, inline resource)
      - `questionnaire`          (required, inline resource)

    StructureDefinitions are loaded from the server-side folder configured via
    `STRUCTURE_DEFINITIONS_DIR` (default `<repo>/data/structure-definitions/`).

    Returns a `collection` Bundle of extracted resources.
    """
    try:
        qr = load_questionnaire_response(parameters)
        q = load_questionnaire(parameters)
    except ValueError as e:
        raise OperationOutcomeException(
            status_code=400,
            issues=[{"severity": "error", "code": "structure", "diagnostics": str(e)}],
        )

    missing = [
        name
        for name, val in (("questionnaire-response", qr), ("questionnaire", q))
        if val is None
    ]
    if missing:
        raise OperationOutcomeException(
            status_code=400,
            issues=[
                {
                    "severity": "error",
                    "code": "required",
                    "diagnostics": f"Missing required parameter: {name}",
                }
                for name in missing
            ],
        )
    assert qr is not None and q is not None, (
        "questionnaire-response and questionnaire should be known here"
    )

    loader = get_structure_definition_loader()
    extractor = sdc_extract.DefinitionBasedExtractor(loader, allow_logical_models=True)

    result = extractor.extract(q, qr)

    fatals = [i for i in result.get("issues", []) if i.get("severity") == "fatal"]
    if fatals:
        raise OperationOutcomeException(status_code=422, issues=fatals)

    return bundle_collection(result["resources"])
