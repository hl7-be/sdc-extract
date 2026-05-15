import logging

from fastapi import Request

from src.server.fhir_client import FhirConfig

LOGGER = logging.getLogger(__name__)


def get_fhir_config(request: Request) -> FhirConfig:
    LOGGER.info("Headers received: %s", {k: v for k, v in request.headers.items() if "fhir" in k.lower()})
    return FhirConfig(
        base_url=request.headers.get("X-FHIR-Base-URL", "") or "",
        api_key=request.headers.get("X-FHIR-API-Key", "") or "",
    )
