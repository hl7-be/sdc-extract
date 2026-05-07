"""End-to-end tests for `POST /api/v2/QuestionnaireResponse/$extract`.

Each fixture under `tests/fixtures/<name>/` is a quadruple:
    q.json         — Questionnaire input
    qr.json        — QuestionnaireResponse input
    sd.json        — StructureDefinition (loaded into the server's SD folder by conftest)
    expected.json  — list of resources the extractor should produce
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from tests.conftest import fixture_dirs


def _load(path: Path) -> dict | list:
    return json.loads(path.read_text())


@pytest.mark.parametrize("fixture", fixture_dirs(), ids=lambda p: p.name)
def test_extract(client, fixture: Path):
    q = _load(fixture / "q.json")
    qr = _load(fixture / "qr.json")
    expected = _load(fixture / "expected.json")

    body = {
        "resourceType": "Parameters",
        "parameter": [
            {"name": "questionnaire", "resource": q},
            {"name": "questionnaire-response", "resource": qr},
        ],
    }

    r = client.post("/api/v2/QuestionnaireResponse/$extract", json=body)
    assert r.status_code == 200, r.json()
    assert r.headers["content-type"].startswith("application/fhir+json")

    bundle = r.json()
    assert bundle["resourceType"] == "Bundle"
    assert bundle["type"] == "collection"

    actual = [entry["resource"] for entry in bundle.get("entry", [])]
    expected_resources = [r for r in expected if "resourceType" in r]
    assert actual == expected_resources


def test_missing_required_parameters(client):
    r = client.post(
        "/api/v2/QuestionnaireResponse/$extract",
        json={"resourceType": "Parameters", "parameter": []},
    )
    assert r.status_code == 400
    body = r.json()
    assert body["resourceType"] == "OperationOutcome"
    codes = {i["code"] for i in body["issue"]}
    assert codes == {"required"}


def test_non_parameters_body(client):
    r = client.post(
        "/api/v2/QuestionnaireResponse/$extract",
        json={"resourceType": "Bundle"},
    )
    assert r.status_code == 400
    body = r.json()
    assert body["resourceType"] == "OperationOutcome"
    assert body["issue"][0]["code"] == "structure"


def test_metadata(client):
    r = client.get("/api/v2/metadata")
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("application/fhir+json")
    body = r.json()
    assert body["resourceType"] == "CapabilityStatement"
    op_names = {
        op["name"]
        for resource in body["rest"][0]["resource"]
        for op in resource.get("operation", [])
    }
    assert "extract" in op_names
