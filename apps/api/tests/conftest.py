"""Pytest configuration: point the API at a tmp folder built from per-fixture SDs."""
from __future__ import annotations

import shutil
from pathlib import Path

import pytest

FIXTURE_ROOT = Path(__file__).parent / "fixtures"


def fixture_dirs() -> list[Path]:
    return sorted(p for p in FIXTURE_ROOT.iterdir() if p.is_dir() and not p.name.startswith("_"))


@pytest.fixture(scope="session", autouse=True)
def _structure_definitions_dir(tmp_path_factory, monkeypatch_session):
    """Build the server's SD folder from every fixture's `sd/*.json`."""
    sd_dir = tmp_path_factory.mktemp("structure-definitions")

    for fx in fixture_dirs():
        sd_subdir = fx / "sd"
        if sd_subdir.is_dir():
            for f in sd_subdir.glob("*.json"):
                shutil.copy(f, sd_dir / f"{fx.name}__{f.name}")

    monkeypatch_session.setenv("STRUCTURE_DEFINITIONS_DIR", str(sd_dir))
    yield sd_dir


@pytest.fixture(scope="session")
def monkeypatch_session():
    """Session-scoped monkeypatch (the built-in `monkeypatch` is function-scoped)."""
    from _pytest.monkeypatch import MonkeyPatch
    mp = MonkeyPatch()
    yield mp
    mp.undo()


@pytest.fixture(scope="session")
def client():
    from fastapi.testclient import TestClient
    from src.server.app import app
    return TestClient(app)
