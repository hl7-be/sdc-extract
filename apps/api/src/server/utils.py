"""Server utilities."""
from __future__ import annotations

from fastapi import HTTPException
from fastapi.responses import JSONResponse


class FhirJSONResponse(JSONResponse):
    """JSONResponse with the FHIR media type."""

    media_type = "application/fhir+json"


class OperationOutcomeException(HTTPException):
    """HTTPException whose `detail` is a FHIR OperationOutcome resource."""

    def __init__(self, status_code: int, issues: list[dict]):
        super().__init__(
            status_code=status_code,
            detail={"resourceType": "OperationOutcome", "issue": issues},
        )


def bundle_collection(resources: list[dict]) -> dict:
    """Wrap concrete FHIR resources in a `collection` Bundle.

    Entries without a `resourceType` (e.g. logical-model values) are skipped —
    the caller is responsible for surfacing those separately.
    """
    return {
        "resourceType": "Bundle",
        "type": "collection",
        "entry": [{"resource": r} for r in resources if "resourceType" in r],
    }
