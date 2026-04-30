import json
import logging
import requests
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
LOGGER = logging.getLogger(__name__)

CACHE_DIR = Path(__file__).parent.parent.parent / ".fhir_cache"

def get_structure_definition(resource_type: str, use_cache: bool = True) -> dict | None:
    """Haalt de definitie op van HAPI of HL7 en slaat deze op in cache."""
    if not resource_type:
        return None
        
    resource_name = resource_type.capitalize()
    cache_file = CACHE_DIR / f"{resource_name.lower()}.json"
    
    if use_cache and cache_file.exists():
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass

    urls_to_try = [
        f"https://hapi.fhir.org/baseR4/StructureDefinition/{resource_name}",
        f"https://hapi.fhir.org/baseR4/StructureDefinition?url=http://hl7.org/fhir/StructureDefinition/{resource_name}",
        f"http://hl7.org/fhir/R4/{resource_name.lower()}.profile.json"
    ]

    headers = {"Accept": "application/fhir+json"}
    
    for url in urls_to_try:
        try:
            LOGGER.info(f"Poging tot ophalen via: {url}")
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get("resourceType") == "Bundle":
                    if data.get("total", 0) > 0:
                        data = data["entry"][0]["resource"]
                    else:
                        continue
                
                if use_cache:
                    CACHE_DIR.mkdir(parents=True, exist_ok=True)
                    with open(cache_file, "w", encoding="utf-8") as f:
                        json.dump(data, f, indent=2)
                
                return data
        except Exception as e:
            LOGGER.warning(f"Kon {url} niet bereiken: {e}")
            continue
            
    return None

def extract_metadata(structure_definition: dict) -> list[dict]:
    """Extraheert paden, ID's en types uit de elementen."""
    if not structure_definition:
        return []
        
    elements = structure_definition.get("snapshot", {}).get("element", [])
    elements += structure_definition.get("differential", {}).get("element", [])
    
    results = []
    seen_ids = set()

    for el in elements:
        element_id = el.get("id")
        if not element_id or element_id in seen_ids:
            continue
            
        seen_ids.add(element_id)
        
        types = [t.get("code") for t in el.get("type", [])]
        
        results.append({
            "path": el.get("path"),
            "id": element_id,
            "min": el.get("min"),
            "max": el.get("max"),
            "types": types
        })
        
    return results

def extract_valid_paths(struct_def: dict) -> list[str]:
    """
    Extraheert paden uit een StructureDefinition.
    Werkt met zowel 'snapshot' (compleet) als 'differential' (wijzigingen).

    Polymorfische paden (value[x]) worden uitgebreid naar hun concrete vormen op basis
    van de type-codes op het element. Zo wordt Observation.value[x] uitgebreid naar
    Observation.valueQuantity, Observation.valueCodeableConcept, enzovoort. De abstracte
    [x]-vorm wordt niet teruggegeven omdat die niet geldig is in FHIR JSON.
    """
    if not struct_def:
        return []

    snapshot_elements = struct_def.get("snapshot", {}).get("element", [])
    diff_elements = struct_def.get("differential", {}).get("element", [])
    all_elements = snapshot_elements + diff_elements

    paths: set[str] = set()

    for el in all_elements:
        path = el.get("path")
        if not path:
            continue

        if "[x]" in path:
            # Expand to concrete typed paths: value[x] → valueQuantity, valueCodeableConcept, ...
            types = [t.get("code", "") for t in el.get("type", []) if t.get("code")]
            if types:
                base = path.replace("[x]", "")
                for type_code in types:
                    # Capitalize first letter so "string" → "String", "Quantity" stays "Quantity"
                    paths.add(base + type_code[0].upper() + type_code[1:])
            # Do not add the abstract [x] path — it is not a valid FHIR JSON key
        elif "." in path:
            paths.add(path)

    return sorted(paths)