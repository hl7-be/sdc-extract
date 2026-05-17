"""Server utilities."""
from __future__ import annotations

import base64
import json
from typing import Any, Callable

from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class FhirJSONResponse(JSONResponse):
    """JSONResponse with the FHIR media type."""

    media_type = "application/fhir+json"


class RawJSONResponse(JSONResponse):
    """JSONResponse with the plain JSON media type — used for the raw
    logical-model output branch of the `$extract` endpoint."""

    media_type = "application/json"


class OperationOutcomeException(HTTPException):
    """HTTPException whose `detail` is a FHIR OperationOutcome resource."""

    def __init__(self, status_code: int, issues: list[dict]):
        super().__init__(
            status_code=status_code,
            detail={"resourceType": "OperationOutcome", "issue": issues},
        )


def bundle_collection(resources: list[dict]) -> dict:
    """Wrap concrete FHIR resources in a `collection` Bundle.

    Callers must filter logical-model instances out beforehand: every entry
    is assumed to have a `resourceType`.
    """
    return {
        "resourceType": "Bundle",
        "type": "collection",
        "entry": [{"resource": r} for r in resources],
    }


def client_prefers(media_type: str) -> Callable[[Request], bool]:
    """FastAPI dependency factory for Accept-header content negotiation.

    The returned dependency resolves to True iff the request's `Accept` header
    explicitly lists `media_type` (case-insensitive, media-type parameters
    stripped, q-values ignored). Wildcards (`* / *`) and a missing header
    both resolve to False.

    Use one dependency per candidate type. The caller composes them to express
    its negotiation rule — e.g. "raw JSON only when application/json is asked
    for and the FHIR media type is *not* also asked for":

        @router.post("/...")
        def endpoint(
            prefers_raw_json: bool = Depends(client_prefers("application/json")),
            prefers_fhir_json: bool = Depends(client_prefers("application/fhir+json")),
        ):
            ...
    """
    target = media_type.lower()

    def _dep(request: Request) -> bool:
        accept = request.headers.get("accept", "")
        offers = (part.split(";", 1)[0].strip().lower() for part in accept.split(","))
        return target in offers

    return _dep


def binary_wrap_json(payload: Any) -> dict:
    """Wrap a JSON-serialisable payload in a FHIR `Binary` resource.

    The payload is serialised to compact JSON and base64-encoded into
    `Binary.data`. `Binary.contentType` is `application/json` so consumers
    know how to interpret the decoded bytes.
    """
    encoded = base64.standard_b64encode(
        json.dumps(payload, separators=(",", ":")).encode("utf-8")
    ).decode("ascii")
    return {
        "resourceType": "Binary",
        "contentType": "application/json",
        "data": encoded,
    }
