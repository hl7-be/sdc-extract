"""
SDC annotation helpers for definition-based extraction.

All functions mutate Questionnaire item dicts in place and return the item for
convenience.  They have no I/O and carry no state; import and call directly.
"""

import re
import logging

log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# URL constants (also imported by extractor.py and app.py)
# ---------------------------------------------------------------------------

SNOMED_SYSTEM = "http://snomed.info/sct"
FHIR_BASE = "http://hl7.org/fhir/StructureDefinition"

DEFINITION_EXTRACT_URL = (
    "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract"
)
DEFINITION_EXTRACT_VALUE_URL = (
    "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue"
)
_ITEM_EXTRACTION_CONTEXT_URL = (
    "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemExtractionContext"
)

# Pattern: http://hl7.org/fhir/StructureDefinition/SomeType#SomeType.element(.sub)*
_DEFINITION_PATTERN = re.compile(
    r"^http://hl7\.org/fhir/StructureDefinition/\w+#\w+(\.\w+)+$"
)


# ---------------------------------------------------------------------------
# Annotation helpers
# ---------------------------------------------------------------------------

def add_snomed_code(item: dict, code: str, display: str) -> dict:
    """
    Append a SNOMED CT code to item.code[], deduplicating by code value.

    Args:
        item:    Questionnaire item dict (mutated in place).
        code:    SNOMED CT code string, e.g. "364075005".
        display: Human-readable display name.
    """
    item.setdefault("code", [])
    already_present = any(
        c.get("code") == code and c.get("system") == SNOMED_SYSTEM
        for c in item["code"]
    )
    if not already_present:
        item["code"].append({"system": SNOMED_SYSTEM, "code": code, "display": display})
    return item


def set_item_definition(item: dict, resource_type: str, element_path: str) -> dict:
    """
    Set the definition field on a leaf questionnaire item.

    Args:
        item:         Questionnaire item dict (mutated in place).
        resource_type: FHIR resource type, e.g. "Observation".
        element_path:  Element path including resource prefix,
                       e.g. "Observation.valueQuantity".
    """
    item["definition"] = f"{FHIR_BASE}/{resource_type}#{element_path}"
    return item


def attach_definition_extract(
    item: dict,
    resource_type: str,
    profile_url: str | None = None,
) -> dict:
    """
    Attach (or replace) the definitionExtract extension on a group item.

    Uses the valueCanonical shorthand: ``{"url": DEFINITION_EXTRACT_URL,
    "valueCanonical": canonical}``.  Any pre-existing definitionExtract
    extension is removed first.

    Args:
        item:         Group questionnaire item dict (mutated in place).
        resource_type: e.g. "Observation".  Used to build the canonical URL
                       when profile_url is not provided.
        profile_url:  Optional profile canonical URL that overrides the base
                      resource URL.
    """
    canonical = profile_url or f"{FHIR_BASE}/{resource_type}"
    extension_entry = {"url": DEFINITION_EXTRACT_URL, "valueCanonical": canonical}

    item.setdefault("extension", [])
    item["extension"] = [
        e for e in item["extension"] if e.get("url") != DEFINITION_EXTRACT_URL
    ]
    item["extension"].append(extension_entry)
    return item


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_definition_extract_structure(questionnaire: dict) -> list[str]:
    """
    Validate the SDC definition-based extraction structure of a questionnaire.

    Returns a list of human-readable error strings.  An empty list means the
    structure is valid and safe to save.

    Checks performed:
    - Every item with a ``definition`` field has an ancestor group that carries
      a ``definitionExtract`` extension (only enforced in group-mode questionnaires;
      flat questionnaires with no extract groups at all are allowed to have
      root-level definitions).
    - Every ``definitionExtract`` extension uses the ``valueCanonical`` field
      (not sub-extensions).
    - ``definition`` field values match the canonical#ResourceType.element pattern.
    - No deprecated ``itemExtractionContext`` extensions are present anywhere.
    """
    errors: list[str] = []

    # Determine whether the questionnaire uses group-based extraction.
    # Only enforce the "definition must have an ancestor extract group" rule
    # in group-mode questionnaires.  Flat questionnaires (no extract groups
    # anywhere) may have definition fields directly on root-level items.
    def _has_any_extract_group(items: list[dict]) -> bool:
        for item in items:
            if item.get("type") == "group" and _has_definition_extract(item):
                return True
            if _has_any_extract_group(item.get("item", [])):
                return True
        return False

    group_mode = _has_any_extract_group(questionnaire.get("item", []))

    def check_items(items: list[dict], ancestor_has_context: bool = False) -> None:
        for item in items:
            link_id = item.get("linkId", "<unknown>")
            item_has_extract = _has_definition_extract(item)
            has_context = ancestor_has_context or item_has_extract

            # --- definitionExtract format check ---
            if item_has_extract:
                for ext in item.get("extension", []):
                    if ext.get("url") != DEFINITION_EXTRACT_URL:
                        continue
                    if not ext.get("valueCanonical"):
                        errors.append(
                            f"Item '{link_id}': definitionExtract is missing 'valueCanonical'. "
                            f"Sub-extension format is not supported — use the valueCanonical "
                            f"shorthand: {{\"url\": \"{DEFINITION_EXTRACT_URL}\", "
                            f"\"valueCanonical\": \"...\"}}"
                        )

            # --- definition field checks ---
            definition = item.get("definition")
            if definition:
                if not has_context and group_mode:
                    # In group-mode questionnaires, every definition must live inside
                    # an extract group.  In flat questionnaires this check is skipped.
                    errors.append(
                        f"Item '{link_id}': has a 'definition' field but no ancestor "
                        f"group carries a definitionExtract extension."
                    )
                if not _DEFINITION_PATTERN.match(definition):
                    errors.append(
                        f"Item '{link_id}': malformed definition '{definition}'. "
                        f"Expected: {{canonical}}#{{ResourceType.element[.subelement...]}}"
                    )

            # --- deprecated extension check ---
            for ext in item.get("extension", []):
                if ext.get("url") == _ITEM_EXTRACTION_CONTEXT_URL:
                    errors.append(
                        f"Item '{link_id}': uses deprecated 'itemExtractionContext' extension. "
                        f"Replace with 'definitionExtract'."
                    )
                    break  # one error per item is enough

            if "item" in item:
                check_items(item["item"], has_context)

    check_items(questionnaire.get("item", []))
    return errors


# ---------------------------------------------------------------------------
# Internal helpers (also imported by extractor.py)
# ---------------------------------------------------------------------------

def _has_definition_extract(item: dict) -> bool:
    """Return True if the item carries a definitionExtract extension."""
    return any(
        e.get("url") == DEFINITION_EXTRACT_URL
        for e in item.get("extension", [])
    )