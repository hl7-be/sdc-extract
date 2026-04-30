import logging
import os
import requests
from typing import Optional
from dataclasses import dataclass
from src.core.sdc_annotations import (
    DEFINITION_EXTRACT_URL,
    validate_definition_extract_structure,
)

log = logging.getLogger(__name__)

DEFAULT_FHIR_BASE_URL = os.environ.get("FHIR_BASE_URL", "https://hapi.fhir.org/baseR4")
GOOGLE_SERVICE_ACCOUNT_FILE = os.environ.get("GOOGLE_SERVICE_ACCOUNT_FILE", "")
GOOGLE_SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]

MAPPING_STATUS_SYSTEM = os.environ.get(
    "MAPPING_STATUS_SYSTEM",
    "https://sdc-extract.example.com/fhir/CodeSystem/mapping-status",
)


@dataclass
class FhirConfig:
    base_url: str = DEFAULT_FHIR_BASE_URL
    api_key: str = ""


def _get_fhir_client(config: FhirConfig):
    base_url = config.base_url.rstrip("/") if config.base_url else DEFAULT_FHIR_BASE_URL

    # When the frontend sends the Google sentinel (prefix only), use the full URL from .env
    if base_url == "https://healthcare.googleapis.com":
        base_url = DEFAULT_FHIR_BASE_URL.rstrip("/")

    if base_url.startswith("https://healthcare.googleapis.com") and GOOGLE_SERVICE_ACCOUNT_FILE and os.path.exists(GOOGLE_SERVICE_ACCOUNT_FILE):
        from google.oauth2 import service_account
        from google.auth.transport.requests import AuthorizedSession
        credentials = service_account.Credentials.from_service_account_file(
            GOOGLE_SERVICE_ACCOUNT_FILE, scopes=GOOGLE_SCOPES
        )
        session = AuthorizedSession(credentials)
        auth_params = {}
    else:
        session = requests.Session()
        auth_params = {"api_key": config.api_key} if config.api_key else {}

    return session, base_url, auth_params


ALLOWED_STATUSES = {"PARTIAL", "DONE", "NOT-STARTED"}


def update_questionnaire(resource: dict, mapping_status: str, config: Optional[FhirConfig] = None) -> dict:
    """
    Validate, tag, and PUT a Questionnaire back to the FHIR store.

    Raises:
        ValueError: If the mapping status is invalid, the resource has no id, or
                    validate_definition_extract_structure returns errors.
    """
    if config is None:
        config = FhirConfig()

    if mapping_status.upper() not in ALLOWED_STATUSES:
        raise ValueError(f"Invalid mapping status: {mapping_status}. Must be one of {ALLOWED_STATUSES}")

    q_id = resource.get("id")
    if not q_id:
        raise ValueError("Questionnaire resource must have an 'id'")

    errors = validate_definition_extract_structure(resource)
    if errors:
        raise ValueError({"validation_errors": errors})

    session, base_url, auth_params = _get_fhir_client(config)
    url = f"{base_url}/Questionnaire/{q_id}"

    meta = resource.setdefault("meta", {})
    tags = meta.setdefault("tag", [])

    system_url = MAPPING_STATUS_SYSTEM
    tags = [t for t in tags if t.get("system") != system_url]
    tags.append({
        "system": system_url,
        "code": mapping_status.upper(),
        "display": mapping_status.lower()
    })
    meta["tag"] = tags

    log.info("Updating Questionnaire id=%s status=%s", q_id, mapping_status)
    resp = session.put(url, json=resource, params=auth_params)
    resp.raise_for_status()
    return resp.json()


def get_latest_version(q_id: str, config: Optional[FhirConfig] = None) -> dict:
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    resp = session.get(f"{base_url}/Questionnaire/{q_id}", params=auth_params)
    resp.raise_for_status()
    return resp.json()


def get_all_versions(q_id: str, config: Optional[FhirConfig] = None) -> dict:
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    resp = session.get(f"{base_url}/Questionnaire/{q_id}/_history", params=auth_params)
    resp.raise_for_status()
    return resp.json()


def get_version(q_id: str, version_id: str, config: Optional[FhirConfig] = None) -> dict:
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    resp = session.get(f"{base_url}/Questionnaire/{q_id}/_history/{version_id}", params=auth_params)
    resp.raise_for_status()
    return resp.json()


def get_questionnaire_mapping_status(questionnaire: dict) -> str:
    """
    Determine the mapping status of a FHIR Questionnaire.

    Counts two kinds of mappable items:
    - Leaf questions: fulfilled when they have a text label, a definition field,
      and at least one SNOMED CT code.
    - Group items that have child items: fulfilled when they carry a
      definitionExtract extension (declaring the target resource type).
    """
    total_mappable = 0
    fulfilled_mappable = 0

    def has_snomed_code(item: dict) -> bool:
        return any(
            c.get("system") == "http://snomed.info/sct"
            for c in item.get("code", [])
        )

    def has_definition_extract(item: dict) -> bool:
        return any(
            e.get("url") == DEFINITION_EXTRACT_URL
            for e in item.get("extension", [])
        )

    def walk_items(items: list) -> None:
        nonlocal total_mappable, fulfilled_mappable

        for item in items:
            if "linkId" not in item:
                continue

            item_type = item.get("type")

            if item_type == "group" and item.get("item"):
                total_mappable += 1
                if has_definition_extract(item):
                    fulfilled_mappable += 1
            elif item_type != "group":
                total_mappable += 1
                if bool(item.get("text")) and bool(item.get("definition")) and has_snomed_code(item):
                    fulfilled_mappable += 1

            if "item" in item:
                walk_items(item["item"])

    walk_items(questionnaire.get("item", []))

    if total_mappable == 0 or fulfilled_mappable == 0:
        return "NOT-STARTED"
    if fulfilled_mappable == total_mappable:
        return "DONE"
    return "PARTIAL"


def get_questionnaire_response(qr_id: str, config: Optional[FhirConfig] = None) -> dict:
    """Fetch a QuestionnaireResponse by ID from the FHIR store."""
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    resp = session.get(f"{base_url}/QuestionnaireResponse/{qr_id}", params=auth_params)
    resp.raise_for_status()
    return resp.json()


def get_questionnaire_response_by_questionnaire_id(q_id: str, config: Optional[FhirConfig] = None) -> Optional[dict]:
    """
    Find the most recent QuestionnaireResponse that references the given Questionnaire ID.

    Pages through all QRs sorted by authored desc and matches client-side on the
    ID suffix, following FHIR Bundle pagination until a match is found or all pages exhausted.
    """
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)

    suffix = f"/{q_id}"
    next_url = f"{base_url}/QuestionnaireResponse"
    params: dict | None = {"_count": 100, "_sort": "-authored", **auth_params}

    while next_url:
        log.info("Fetching QuestionnaireResponses page: %s", next_url)
        resp = session.get(next_url, params=params)
        resp.raise_for_status()
        bundle = resp.json()
        params = None

        for entry in bundle.get("entry", []):
            resource = entry.get("resource", {})
            questionnaire_ref = resource.get("questionnaire", "")
            if questionnaire_ref == q_id or questionnaire_ref.endswith(suffix):
                log.info("Found QuestionnaireResponse via client-side match: questionnaire=%s", questionnaire_ref)
                return resource

        next_url = next(
            (link["url"] for link in bundle.get("link", []) if link.get("relation") == "next"),
            None,
        )

    return None


def post_bundle(bundle: dict, config: Optional[FhirConfig] = None) -> dict:
    """POST a FHIR transaction Bundle to the store and return the response Bundle."""
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    resp = session.post(base_url, json=bundle, params=auth_params)
    resp.raise_for_status()
    return resp.json()


def list_questionnaires_from_fhir(config: FhirConfig) -> list[dict]:
    """List all Questionnaires from the configured FHIR server, following pagination."""
    session, base_url, auth_params = _get_fhir_client(config)

    log.info("Listing questionnaires from FHIR server: %s", base_url)

    next_url: str | None = f"{base_url}/Questionnaire"
    params: dict | None = {"_count": 100, "_sort": "title"}
    params.update(auth_params)

    results = []
    while next_url:
        resp = session.get(next_url, params=params)
        resp.raise_for_status()
        bundle = resp.json()
        params = None  # subsequent requests use the full next URL (params are embedded)

        for entry in bundle.get("entry", []):
            resource = entry.get("resource", {})
            results.append({
                "id": resource.get("id"),
                "title": resource.get("title") or resource.get("id"),
                "mappingtag": None,
            })

        next_url = next(
            (link["url"] for link in bundle.get("link", []) if link.get("relation") == "next"),
            None,
        )

    log.info("Loaded %d questionnaires total", len(results))
    return results


def get_recent_questionnaire_responses(config: Optional[FhirConfig] = None, limit: int = 50) -> list[dict]:
    """Fetch recent QuestionnaireResponses."""
    if config is None:
        config = FhirConfig()
    session, base_url, auth_params = _get_fhir_client(config)
    params = {"_count": limit, "_sort": "-authored"}
    params.update(auth_params)
    resp = session.get(f"{base_url}/QuestionnaireResponse", params=params)
    if not resp.ok:
        return []

    bundle = resp.json()
    results = []
    for entry in bundle.get("entry", []):
        results.append(entry.get("resource", {}))

    return results
