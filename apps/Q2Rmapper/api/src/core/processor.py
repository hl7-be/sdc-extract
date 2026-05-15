"""
QuestionnaireProcessor — high-level orchestrator for definition-based extraction.

Fetches a QuestionnaireResponse (and its referenced Questionnaire) from the
FHIR store, delegates to DefinitionBasedExtractor, and optionally persists the
resulting transaction Bundle back to the store.

Usage::

    from src.core.processor import QuestionnaireProcessor
    from src.server.fhir_client import FhirConfig

    processor = QuestionnaireProcessor(FhirConfig(...))
    bundle, errors = processor.extract(qr_id="abc123")
    # or with persistence:
    bundle, errors = processor.extract(qr_id="abc123", persist=True)
"""

import logging

import requests

from src.core.extractor import DefinitionBasedExtractor
from src.server.fhir_client import (
    FhirConfig,
    get_latest_version,
    get_questionnaire_response,
    post_bundle,
    get_questionnaire_response_by_questionnaire_id,
)

log = logging.getLogger(__name__)


def _fhir_error_detail(exc: requests.HTTPError) -> str:
    """Extract a readable error message from a FHIR store HTTP error response."""
    resp = exc.response
    if resp is None:
        return str(exc)
    try:
        body = resp.json()
        # FHIR OperationOutcome — collect all issue diagnostics / details
        if body.get("resourceType") == "OperationOutcome":
            messages = []
            for issue in body.get("issue", []):
                diag = issue.get("diagnostics") or issue.get("details", {}).get("text") or issue.get("code", "")
                if diag:
                    messages.append(diag)
            if messages:
                return "; ".join(messages)
        return str(body)
    except Exception:
        return resp.text or str(exc)


class QuestionnaireProcessor:
    """
    Orchestrates the full extraction pipeline for a single QuestionnaireResponse.

    1. Fetch the QuestionnaireResponse by ID from the FHIR store.
    2. Read the ``questionnaire`` reference on the QR to identify the source
       Questionnaire.
    3. Fetch that Questionnaire from the FHIR store.
    4. Run ``DefinitionBasedExtractor`` to produce a transaction Bundle.
    5. Optionally POST the Bundle to the FHIR store (``persist=True``).
    """

    def __init__(self, config: FhirConfig) -> None:
        self.config = config

    def extract(
        self,
        qr_id: str,
        persist: bool = False,
    ) -> tuple[dict, list[str]]:
        """
        Run the full extraction pipeline for the given QuestionnaireResponse ID.

        Args:
            qr_id:   ID of the QuestionnaireResponse resource in the FHIR store.
            persist: When True, POST the resulting transaction Bundle to the store.
                     A FHIR store rejection is captured as an entry in ``errors``
                     rather than raising, so the caller always receives the bundle.

        Returns:
            (bundle, errors) where ``bundle`` is the FHIR transaction Bundle and
            ``errors`` is a list of human-readable strings for any type mismatches,
            structural problems, or persist failures encountered.

        Raises:
            ValueError: If the QuestionnaireResponse does not reference a
                        Questionnaire, or if the Questionnaire cannot be fetched.
            requests.HTTPError: On FHIR store fetch failures (not persist failures).
        """
        log.info("Starting extraction for QuestionnaireResponse/%s", qr_id)

        qr = get_questionnaire_response(qr_id, self.config)

        questionnaire_ref = qr.get("questionnaire")
        if not questionnaire_ref:
            raise ValueError(
                f"QuestionnaireResponse/{qr_id} does not have a 'questionnaire' reference"
            )

        q_id = questionnaire_ref.split("/")[-1]
        log.info("Fetching Questionnaire/%s referenced by QR", q_id)
        questionnaire = get_latest_version(q_id, self.config)

        extractor = DefinitionBasedExtractor(questionnaire, qr)
        bundle, errors = extractor.extract()

        if errors:
            log.warning(
                "Extraction of QR/%s produced %d error(s): %s",
                qr_id,
                len(errors),
                errors,
            )

        if persist:
            if not bundle.get("entry"):
                log.info("Bundle is empty — nothing to persist")
            else:
                log.info("Persisting %d bundle entries to FHIR store", len(bundle["entry"]))
                try:
                    post_bundle(bundle, self.config)
                except requests.HTTPError as exc:
                    detail = _fhir_error_detail(exc)
                    log.error("FHIR store rejected bundle (HTTP %s): %s", exc.response.status_code if exc.response else "?", detail)
                    errors.append(f"FHIR store rejected the bundle: {detail}")

        return bundle, errors

    def extract_from_body(
        self,
        qr: dict,
        persist: bool = False,
        questionnaire: dict | None = None,
    ) -> tuple[dict, list[str]]:
        """
        Run extraction with a QuestionnaireResponse provided directly (not fetched from the store).

        Useful for preview: the frontend exports LForms data as a QR and POSTs it here
        without having to persist it to the FHIR store first.

        When ``questionnaire`` is supplied the annotated Questionnaire is used as-is and
        no FHIR store fetch is performed.  When it is omitted the QR must have a
        ``questionnaire`` field (e.g. ``"Questionnaire/MyId"``) so the Questionnaire can
        be fetched from the store.

        Args:
            qr:            QuestionnaireResponse dict (e.g. exported from LForms).
            persist:       When True, POST the resulting transaction Bundle to the store.
            questionnaire: Optional pre-supplied Questionnaire dict with all
                           definition/definitionExtract annotations already present.

        Returns:
            (bundle, errors)
        """
        if questionnaire is None:
            questionnaire_ref = qr.get("questionnaire")
            if not questionnaire_ref:
                raise ValueError("QuestionnaireResponse does not have a 'questionnaire' reference")
            q_id = questionnaire_ref.split("/")[-1]
            log.info("Fetching Questionnaire/%s for preview extraction", q_id)
            questionnaire = get_latest_version(q_id, self.config)
        else:
            log.info(
                "Using supplied Questionnaire '%s' for preview extraction",
                questionnaire.get("id", "<no id>"),
            )

        extractor = DefinitionBasedExtractor(questionnaire, qr)
        bundle, errors = extractor.extract()

        if errors:
            log.warning("Preview extraction produced %d error(s): %s", len(errors), errors)

        if persist and bundle.get("entry"):
            try:
                post_bundle(bundle, self.config)
            except requests.HTTPError as exc:
                detail = _fhir_error_detail(exc)
                log.error(
                    "FHIR store rejected bundle (HTTP %s): %s",
                    exc.response.status_code if exc.response else "?",
                    detail,
                )
                errors.append(f"FHIR store rejected the bundle: {detail}")

        return bundle, errors