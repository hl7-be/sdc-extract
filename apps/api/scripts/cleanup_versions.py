# uv run python scripts/cleanup_versions.py

import logging
import sys
import os
import time
from typing import Optional, List

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import requests
from src.server.fhir_client import (
    FhirConfig,
    _get_fhir_client,
)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


# Cleanup Logic
def cleanup_resource_history(session: requests.Session, base_url: str, auth_params: dict, resource_type: str):
    """
    Iterate through all resources of resource_type and keep only version 1.
    """
    next_url: Optional[str] = f"{base_url}/{resource_type}"
    params = {"_count": 50}
    params.update(auth_params)

    log.info("Cleaning up all %s resources ...", resource_type)
    total_processed = 0
    total_reverted = 0

    while next_url:
        resp = session.get(next_url, params=params if next_url.endswith(resource_type) else None)
        if not resp.ok:
            log.error("Failed to list %ss: %s %s", resource_type, resp.status_code, resp.text[:200])
            break

        bundle = resp.json()
        entries = bundle.get("entry", [])

        if not entries:
            break

        for entry in entries:
            resource = entry.get("resource", {})
            rid = resource.get("id")
            if not rid:
                continue

            total_processed += 1
            
            # Check history
            history_url = f"{base_url}/{resource_type}/{rid}/_history"
            h_resp = session.get(history_url, params=auth_params)
            if not h_resp.ok:
                log.warning("  Could not fetch history for %s/%s, skipping.", resource_type, rid)
                continue

            h_bundle = h_resp.json()
            h_entries = h_bundle.get("entry", [])

            valid_histories = [e for e in h_entries if e.get("resource")]
            
            if len(valid_histories) <= 1:
                log.debug("  %s/%s is already at version 1 (or has no valid history).", resource_type, rid)
                continue

            v1_entry = valid_histories[-1]
            v1_resource = v1_entry.get("resource")
            v1_id = v1_resource.get("meta", {}).get("versionId")
            
            log.info("  Reverting %s/%s from %d versions to its first version (v%s)...", 
                     resource_type, rid, len(valid_histories), v1_id or "?")

            # 1. Delete the resource
            del_resp = session.delete(f"{base_url}/{resource_type}/{rid}", params=auth_params)
            if not del_resp.ok:
                log.error("    Failed to delete %s/%s: %s", resource_type, rid, del_resp.status_code)
                continue

            # 2. Re-create using v1 content
            if "meta" in v1_resource:
                v1_resource["meta"].pop("versionId", None)
                v1_resource["meta"].pop("lastUpdated", None)

            put_resp = session.put(f"{base_url}/{resource_type}/{rid}", json=v1_resource, params=auth_params)
            if put_resp.ok:
                log.info("    Successfully reverted %s/%s.", resource_type, rid)
                total_reverted += 1
            else:
                log.error("    Failed to recreate %s/%s: %s %s", 
                          resource_type, rid, put_resp.status_code, put_resp.text[:200])

        # Pagination
        next_url = None
        for link in bundle.get("link", []):
            if link.get("relation") == "next":
                next_url = link["url"]
                break
        
        log.info("Processed %d resources so far...", total_processed)
        time.sleep(0.1)

    log.info("Finished %s cleanup. Total: %d, Reverted: %d", resource_type, total_processed, total_reverted)


def main():
    config = FhirConfig()
    
    print(f"\n  Cleanup script for FHIR resource versions")
    print(f"  Target: {config.server_type} server")
    print(f"  Resources: Questionnaire, QuestionnaireResponse")
    print(f"  Strategy: Keep only version 1 (v1) and delete all subsequent history.")
    
    confirm = input("\n  Type 'yes' to continue: ").strip().lower()
    if confirm != "yes":
        print("  Aborted.")
        sys.exit(0)

    session, base_url, auth_params = _get_fhir_client(config)
    
    try:
        cleanup_resource_history(session, base_url, auth_params, "Questionnaire")
        # cleanup_resource_history(session, base_url, auth_params, "QuestionnaireResponse")
    except KeyboardInterrupt:
        log.warning("Interrupted by user.")
        sys.exit(1)
    except Exception as e:
        log.exception("An error occurred during cleanup: %s", e)
        sys.exit(1)

    print("\n  Done.")

if __name__ == "__main__":
    main()
