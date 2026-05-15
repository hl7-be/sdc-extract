"""
Definition-based QuestionnaireResponse extraction (SDC v4).

The Google Healthcare FHIR API does not provide a native $extract operation,
so extraction is implemented here.

Usage::

    extractor = DefinitionBasedExtractor(questionnaire, questionnaire_response)
    bundle, errors = extractor.extract()

    # bundle  — FHIR transaction Bundle ready to POST to the store
    # errors  — list of human-readable strings for type mismatches / structural
    #           problems found during extraction (non-fatal: the bundle is still
    #           returned, but entries that triggered errors are skipped)
"""

import logging
from typing import Any
from uuid import uuid4

from src.core.sdc_annotations import (
    DEFINITION_EXTRACT_URL,
    DEFINITION_EXTRACT_VALUE_URL,
    _has_definition_extract,
)

log = logging.getLogger(__name__)

# FHIR top-level element names that are always arrays.
# Used by _set_nested to decide whether to wrap a value in [...].
_LIST_FIELDS: frozenset[str] = frozenset({
    "category",
    "identifier",
    "note",
    "performer",
    "coding",
    "extension",
    "modifierExtension",
    "basedOn",
    "partOf",
    "hasMember",
    "derivedFrom",
    "focus",
    "interpretation",
    "bodySite",
})

# Default values for required fields that are commonly omitted from configurations.
# Applied as soft defaults before fixed-value processing, so explicit user-configured
# definitionExtractValue extensions always take precedence.
_RESOURCE_STATUS_DEFAULTS: dict[str, str] = {
    "Observation": "final",
    "DiagnosticReport": "final",
    "Procedure": "completed",
    "ImagingStudy": "available",
}

# Fields that must be present (beyond resourceType) for a resource to be considered
# valid enough to include in the bundle.  Resources missing any of these are silently
# dropped and a warning is added to the errors list so the caller can surface it.
_RESOURCE_REQUIRED_FIELDS: dict[str, frozenset[str]] = {
    "Observation": frozenset({"code"}),
    "DiagnosticReport": frozenset({"code"}),
    "Procedure": frozenset({"code"}),
}

# Last path segments that hold CodeableConcept and therefore accept a valueCoding
# answer (which must be wrapped in {"coding": [...]}).
_CODEABLE_CONCEPT_LAST_SEGMENTS: frozenset[str] = frozenset({
    "valuecodeableconcept",
    "code",
    "bodysite",
    "method",
    "dataabsentreason",
    "category",
})


# ===========================================================================
# Public class
# ===========================================================================

class DefinitionBasedExtractor:
    """
    Walks a QuestionnaireResponse against its annotated Questionnaire and
    produces a FHIR transaction Bundle of extracted resources.

    One resource is created per (group occurrence × distinct canonical URL
    referenced by child definition fields).  A single group whose children
    point to different resource types therefore produces multiple resources.

    Fixed values declared with ``definitionExtractValue`` on group items or
    leaf items are injected unconditionally into the matching resource.
    """

    def __init__(self, questionnaire: dict, questionnaire_response: dict) -> None:
        self.questionnaire = questionnaire
        self.qr = questionnaire_response
        # Flat linkId → q_item index built from the full questionnaire tree
        self._q_index: dict[str, dict] = {}
        self._build_linkid_index(questionnaire.get("item", []))
        # True when the questionnaire uses group-based extraction.
        # When False (flat questionnaire) leaf items are extracted without a group wrapper.
        self._has_extract_groups: bool = self._check_has_extract_groups(
            questionnaire.get("item", [])
        )

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def extract(self) -> tuple[dict, list[str]]:
        """
        Run the extraction.

        Returns:
            (bundle, errors) where ``bundle`` is a FHIR transaction Bundle dict
            and ``errors`` is a list of human-readable strings describing any
            type mismatches or structural problems encountered.  Entries that
            produced errors are omitted from the bundle.
        """
        resources: list[dict] = []
        errors: list[str] = []
        # For flat questionnaires (no extract groups): accumulates one resource dict
        # per canonical URL across all top-level leaf items.
        flat_resources: dict[str, dict] = {}
        self._process_items(self.qr.get("item", []), resources, errors, flat_resources)
        resources.extend(flat_resources.values())
        resources = _filter_incomplete_resources(resources, errors)
        bundle = self._make_bundle(resources)
        return bundle, errors

    # ------------------------------------------------------------------
    # Index building
    # ------------------------------------------------------------------

    def _build_linkid_index(self, items: list[dict]) -> None:
        for item in items:
            link_id = item.get("linkId")
            if link_id:
                self._q_index[link_id] = item
            if "item" in item:
                self._build_linkid_index(item["item"])

    def _check_has_extract_groups(self, items: list[dict]) -> bool:
        """Return True if any item in the tree is a group with definitionExtract."""
        for item in items:
            if item.get("type") == "group" and _has_definition_extract(item):
                return True
            if self._check_has_extract_groups(item.get("item", [])):
                return True
        return False

    # ------------------------------------------------------------------
    # QR tree walking
    # ------------------------------------------------------------------

    def _process_items(
        self,
        qr_items: list[dict],
        collected: list[dict],
        errors: list[str],
        flat_resources: dict[str, dict] | None = None,
    ) -> None:
        """
        Walk a list of QR items, collecting extracted resources into ``collected``.

        - Items whose corresponding Q item is a group with ``definitionExtract``
          are handed to ``_process_group``.
        - When the questionnaire has no extract groups at all (flat mode), leaf
          items with a ``definition`` field are extracted directly and accumulated
          into ``flat_resources`` (one resource dict per canonical URL).
        - All other items are recursed into so that deeply nested extract groups
          are reached through purely structural ancestors.
        """
        if flat_resources is None:
            flat_resources = {}
        for qr_item in qr_items:
            link_id = qr_item.get("linkId")
            q_item = self._q_index.get(link_id)
            if q_item is None:
                log.debug("No questionnaire item for linkId=%r — skipping", link_id)
                continue

            if q_item.get("type") == "group" and _has_definition_extract(q_item):
                group_resources = self._process_group(q_item, qr_item, errors)
                collected.extend(group_resources)
            elif "item" in qr_item:
                self._process_items(qr_item["item"], collected, errors, flat_resources)
            elif (
                not self._has_extract_groups
                and q_item.get("definition")
                and "#" in (q_item.get("definition") or "")
            ):
                # Flat questionnaire: extract leaf directly into the shared resource
                # accumulator.  _apply_fixed_values and _apply_leaf_answers both call
                # _get_or_create so the resource is lazily initialised on first write.
                canonical = q_item["definition"].split("#", 1)[0]
                resource = _get_or_create(flat_resources, canonical)
                # Inject soft defaults the first time this canonical is seen.
                if len(resource) == 1:  # only resourceType set — freshly created
                    _inject_resource_defaults(resource, q_item)
                self._apply_fixed_values(q_item, flat_resources, errors)
                self._apply_leaf_answers(q_item, qr_item, flat_resources, errors)

    def _process_group(
        self,
        q_item: dict,
        qr_item: dict,
        errors: list[str],
    ) -> list[dict]:
        """
        Process one occurrence of an extraction group.

        Returns a flat list containing:
        - One resource per distinct canonical URL whose data was populated from
          this group's children (including the type declared by ``definitionExtract``).
        - Resources produced by any nested extraction groups found inside this one.
        """
        # canonical URL → resource dict for this group occurrence
        resources_by_canonical: dict[str, dict] = {}

        # Seed with the resource type declared on the group itself
        primary_canonical = _get_definition_extract_canonical(q_item)
        if primary_canonical:
            resource_type = _type_from_canonical(primary_canonical)
            resource = {"resourceType": resource_type}
            # Inject soft defaults (status, code) before user fixed-values so that
            # explicit definitionExtractValue extensions always take precedence.
            _inject_resource_defaults(resource, q_item)
            resources_by_canonical[primary_canonical] = resource

        # Fixed values on the group item (e.g. status=final, category, subject)
        self._apply_fixed_values(q_item, resources_by_canonical, errors)

        additional: list[dict] = []

        for child_qr in qr_item.get("item", []):
            child_link_id = child_qr.get("linkId")
            child_q = self._q_index.get(child_link_id)
            if child_q is None:
                continue

            # Nested extraction group → independent resource set, processed recursively
            if child_q.get("type") == "group" and _has_definition_extract(child_q):
                nested = self._process_group(child_q, child_qr, errors)
                additional.extend(nested)
                continue

            # Non-extract group inside this extract group → walk its descendants
            if child_q.get("type") == "group":
                self._collect_from_non_extract_group(
                    child_q, child_qr, resources_by_canonical, errors
                )
                continue

            # Leaf item: fixed values (e.g. valueQuantity unit companion fields)
            self._apply_fixed_values(child_q, resources_by_canonical, errors)

            # Leaf item: answer values
            self._apply_leaf_answers(child_q, child_qr, resources_by_canonical, errors)

        return list(resources_by_canonical.values()) + additional

    def _collect_from_non_extract_group(
        self,
        q_item: dict,
        qr_item: dict,
        resources_by_canonical: dict[str, dict],
        errors: list[str],
    ) -> None:
        """
        Recursively collect leaf answers from a non-extract group that lives
        inside an extract group.  Any nested extract groups found here are NOT
        processed (they will be caught by the parent ``_process_items`` call).
        """
        for child_qr in qr_item.get("item", []):
            child_link_id = child_qr.get("linkId")
            child_q = self._q_index.get(child_link_id)
            if child_q is None:
                continue

            if child_q.get("type") == "group":
                if not _has_definition_extract(child_q):
                    self._collect_from_non_extract_group(
                        child_q, child_qr, resources_by_canonical, errors
                    )
                # nested extract groups are intentionally skipped here
                continue

            self._apply_fixed_values(child_q, resources_by_canonical, errors)
            self._apply_leaf_answers(child_q, child_qr, resources_by_canonical, errors)

    # ------------------------------------------------------------------
    # Fixed value injection
    # ------------------------------------------------------------------

    def _apply_fixed_values(
        self,
        q_item: dict,
        resources_by_canonical: dict[str, dict],
        errors: list[str],
    ) -> None:
        """
        Inject every ``definitionExtractValue`` extension from ``q_item`` into
        the matching resource in ``resources_by_canonical``.
        """
        for ext in q_item.get("extension", []):
            if ext.get("url") != DEFINITION_EXTRACT_VALUE_URL:
                continue

            sub = {e["url"]: e for e in ext.get("extension", [])}
            def_ext = sub.get("definition")
            fv_ext = sub.get("fixed-value")

            if not def_ext or not fv_ext:
                log.warning(
                    "Malformed definitionExtractValue on item %r — missing sub-extension(s)",
                    q_item.get("linkId"),
                )
                continue

            definition_uri = (
                def_ext.get("valueUri")
                or def_ext.get("valueUrl")
                or def_ext.get("valueString")
            )
            if not definition_uri or "#" not in definition_uri:
                errors.append(
                    f"Item '{q_item.get('linkId')}': definitionExtractValue has invalid "
                    f"definition URI: {definition_uri!r}"
                )
                continue

            fixed_value = _extract_value_x(fv_ext)
            if fixed_value is None:
                errors.append(
                    f"Item '{q_item.get('linkId')}': definitionExtractValue has no value[x]"
                )
                continue

            canonical, element_path = definition_uri.split("#", 1)
            resource = _get_or_create(resources_by_canonical, canonical)
            _write_to_path(resource, element_path, fixed_value)

    # ------------------------------------------------------------------
    # Answer application
    # ------------------------------------------------------------------

    def _apply_leaf_answers(
        self,
        child_q: dict,
        child_qr: dict,
        resources_by_canonical: dict[str, dict],
        errors: list[str],
    ) -> None:
        """Write each answer of a leaf item to the resource at its definition path."""
        definition = child_q.get("definition")
        if not definition or "answer" not in child_qr:
            return

        link_id = child_q.get("linkId", "<unknown>")

        if "#" not in definition:
            errors.append(
                f"Item '{link_id}': definition '{definition}' is missing the '#' separator"
            )
            return

        canonical, element_path = definition.split("#", 1)

        for answer in child_qr["answer"]:
            answer_key, answer_value = _extract_answer_kv(answer)
            if answer_key is None:
                continue

            mismatch = _check_type_mismatch(answer_key, element_path, link_id)
            if mismatch:
                errors.append(mismatch)
                continue

            value_to_write = _transform_answer(answer_key, answer_value, element_path)
            resource = _get_or_create(resources_by_canonical, canonical)
            _write_to_path(resource, element_path, value_to_write)

    # ------------------------------------------------------------------
    # Bundle assembly
    # ------------------------------------------------------------------

    def _make_bundle(self, resources: list[dict]) -> dict:
        """Wrap extracted resources in a FHIR transaction Bundle."""
        entries = []
        for resource in resources:
            resource_type = resource.get("resourceType", "Unknown")
            resource_id = resource.get("id")
            entry = {
                "fullUrl": f"urn:uuid:{uuid4()}",
                "resource": resource,
                "request": {
                    "method": "PUT" if resource_id else "POST",
                    "url": (
                        f"{resource_type}/{resource_id}" if resource_id else resource_type
                    ),
                },
            }
            entries.append(entry)

        return {
            "resourceType": "Bundle",
            "type": "transaction",
            "entry": entries,
        }


# ===========================================================================
# Module-level helpers
# ===========================================================================

def _get_definition_extract_canonical(item: dict) -> str | None:
    """Return the valueCanonical of the first definitionExtract extension, or None."""
    for ext in item.get("extension", []):
        if ext.get("url") == DEFINITION_EXTRACT_URL:
            return ext.get("valueCanonical")
    return None


def _type_from_canonical(canonical: str) -> str:
    """
    Extract the FHIR resource type name from a canonical URL.

    "http://hl7.org/fhir/StructureDefinition/Observation" → "Observation"
    """
    return canonical.rstrip("/").split("/")[-1]


def _get_or_create(resources_by_canonical: dict[str, dict], canonical: str) -> dict:
    """Return the resource dict for ``canonical``, creating a skeleton if absent."""
    if canonical not in resources_by_canonical:
        resources_by_canonical[canonical] = {"resourceType": _type_from_canonical(canonical)}
    return resources_by_canonical[canonical]


def _inject_resource_defaults(resource: dict, q_item: dict | None) -> None:
    """
    Inject soft defaults for commonly-required FHIR fields that users often omit.

    This runs *before* ``_apply_fixed_values``, so any explicitly configured
    ``definitionExtractValue`` extension still takes precedence and overwrites these.

    ``status`` — defaulted for resource types that mandate it (Observation → "final", etc.)
    ``code``   — defaulted from the group/leaf questionnaire item's ``code[0]`` coding when
                 the resource does not yet have a ``code`` field.
    """
    resource_type = resource.get("resourceType", "")

    # Status default
    default_status = _RESOURCE_STATUS_DEFAULTS.get(resource_type)
    if default_status and "status" not in resource:
        resource["status"] = default_status

    # Code default from item.code[0] (set by the wizard's SNOMED picker)
    if q_item and "code" not in resource:
        item_codes: list[dict] = q_item.get("code") or []
        if item_codes:
            resource["code"] = {"coding": item_codes}


def _filter_incomplete_resources(resources: list[dict], errors: list[str]) -> list[dict]:
    """
    Remove resources that are missing fields required by the FHIR store.

    An incomplete resource (e.g. an Observation with no ``code``) would cause the
    entire transaction Bundle to be rejected with a 400.  Dropping the shell and
    surfacing a warning is better than failing the whole extraction.
    """
    kept: list[dict] = []
    for resource in resources:
        resource_type = resource.get("resourceType", "")
        required = _RESOURCE_REQUIRED_FIELDS.get(resource_type, frozenset())
        missing = [f for f in required if f not in resource]
        if missing:
            log.warning(
                "Dropping incomplete %s resource (missing required field(s): %s)",
                resource_type,
                ", ".join(missing),
            )
            errors.append(
                f"Skipped an incomplete {resource_type} resource "
                f"(missing required field(s): {', '.join(missing)}). "
                f"Make sure the corresponding group has a SNOMED code configured."
            )
        else:
            kept.append(resource)
    return kept



def _extract_value_x(ext: dict) -> Any:
    """Return the value of the first ``value[x]`` key in an extension dict."""
    for key, val in ext.items():
        if key.startswith("value") and key != "url":
            return val
    return None


def _extract_answer_kv(answer: dict) -> tuple[str | None, Any]:
    """Return ``(answer_key, answer_value)`` for the first ``value[x]`` in an answer."""
    for key, val in answer.items():
        if key.startswith("value"):
            return key, val
    return None, None


# ---------------------------------------------------------------------------
# Path navigation
# ---------------------------------------------------------------------------

def _write_to_path(resource: dict, element_path: str, value: Any) -> None:
    """
    Write ``value`` to ``resource`` at the FHIR element path ``element_path``.

    ``element_path`` is in the form ``ResourceType.field[.subfield...]``.
    The leading ``ResourceType.`` prefix is stripped before navigating.
    """
    parts = element_path.split(".")
    if len(parts) < 2:
        # Bare resource type — nothing to write to
        log.warning("Cannot write to bare resource-type path '%s'", element_path)
        return
    _set_nested(resource, parts[1:], value)


def _set_nested(obj: dict, parts: list[str], value: Any) -> None:
    """
    Recursively navigate or create nested dicts and set the terminal value.

    Special cases handled:
    - Fields in ``_LIST_FIELDS`` are stored as lists.
    - ``note.text`` is expanded into ``[{"text": value}]`` on ``note``.
    - If an intermediate node is a list, navigation descends into the last element.
    """
    if not parts:
        return

    key = parts[0]
    remaining = parts[1:]

    # --- Terminal write ---
    if not remaining:
        if key in _LIST_FIELDS:
            obj.setdefault(key, [])
            if key == "note" and isinstance(value, str):
                obj[key].append({"text": value})
            else:
                obj[key].append(value)
        else:
            obj[key] = value
        return

    # --- Special: note.text → [{"text": value}] ---
    if key == "note" and remaining == ["text"]:
        obj.setdefault("note", [])
        if obj["note"]:
            obj["note"][-1]["text"] = value
        else:
            obj["note"].append({"text": value})
        return

    # --- Intermediate navigation ---
    if key not in obj:
        obj[key] = {}
    target = obj[key]
    if isinstance(target, list):
        if target:
            _set_nested(target[-1], remaining, value)
        else:
            new_node: dict = {}
            target.append(new_node)
            _set_nested(new_node, remaining, value)
    elif isinstance(target, dict):
        _set_nested(target, remaining, value)
    else:
        # Overwrite scalar with a dict so we can navigate further
        obj[key] = {}
        _set_nested(obj[key], remaining, value)


# ---------------------------------------------------------------------------
# Type checking and answer transformation
# ---------------------------------------------------------------------------

def _check_type_mismatch(
    answer_key: str,
    element_path: str,
    link_id: str | None,
) -> str | None:
    """
    Return an error string if the answer type is clearly incompatible with the
    element path.  Returns None when the types are compatible or cannot be
    determined from the path alone.
    """
    last = element_path.split(".")[-1].lower()
    # answer_key is e.g. "valueDecimal"; strip leading "value" for comparison
    atype = answer_key[5:].lower() if answer_key.startswith("value") else answer_key.lower()

    # Exact value[x] typed terminal segments
    if last == "valuequantity" and atype not in ("quantity",):
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueQuantity"
        )

    if last == "valueboolean" and atype != "boolean":
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueBoolean"
        )

    if last == "valuestring" and atype != "string":
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueString"
        )

    if last == "valueinteger" and atype not in ("integer",):
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueInteger"
        )

    if last == "valuedecimal" and atype not in ("decimal",):
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueDecimal"
        )

    # CodeableConcept path: Quantity, Boolean, Decimal, Integer are wrong
    if last == "valuecodeableconcept" and atype in ("quantity", "boolean", "decimal", "integer"):
        return (
            f"Item '{link_id}': answer type '{answer_key}' is incompatible with "
            f"definition path '{element_path}' — expected valueCoding or valueCodeableConcept"
        )

    return None


def _transform_answer(answer_key: str, answer_value: Any, element_path: str) -> Any:
    """
    Transform the answer value where needed to match the target FHIR element type.

    The main transformation is: ``valueCoding`` (how QR stores choice answers)
    → ``{"coding": [coding]}`` when the target element is CodeableConcept-typed.
    """
    last = element_path.split(".")[-1].lower()
    atype = answer_key[5:].lower() if answer_key.startswith("value") else ""

    if atype == "coding" and last in _CODEABLE_CONCEPT_LAST_SEGMENTS:
        return {"coding": [answer_value]}

    return answer_value