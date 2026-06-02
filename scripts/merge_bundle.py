#!/usr/bin/env python3
"""
Merge a FHIR Bundle from $extract with dummy Patient/Practitioner resources
into a single transaction Bundle that can be POSTed to a FHIR server.

Usage:
    python3 merge_bundle.py <extracted_bundle.json> <patient.json> <practitioner.json>

The extracted bundle entries are turned into POST requests (new resources).
The patient and practitioner are turned into PUT requests (upsert by id).
"""
import json
import sys


def main():
    if len(sys.argv) != 4:
        print("Usage: merge_bundle.py <extracted.json> <patient.json> <practitioner.json>", file=sys.stderr)
        sys.exit(1)

    extracted = json.load(open(sys.argv[1]))
    patient = json.load(open(sys.argv[2]))
    practitioner = json.load(open(sys.argv[3]))

    entries = []

    # Upsert Patient and Practitioner by known id so they always exist
    for res in [patient, practitioner]:
        rt = res["resourceType"]
        rid = res["id"]
        entries.append({
            "fullUrl": f"{rt}/{rid}",
            "resource": res,
            "request": {
                "method": "PUT",
                "url": f"{rt}/{rid}"
            }
        })

    # POST each extracted resource (they have no server id yet)
    for entry in extracted.get("entry", []):
        resource = entry.get("resource", {})
        rt = resource.get("resourceType", "Resource")
        entries.append({
            "resource": resource,
            "request": {
                "method": "POST",
                "url": rt
            }
        })

    transaction = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": entries
    }

    print(json.dumps(transaction, indent=2))


if __name__ == "__main__":
    main()
