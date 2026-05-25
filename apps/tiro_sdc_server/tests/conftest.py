"""Container-level integration tests for the tiro-sdc-server wrapper.

These tests spin up the wrapper image once per pytest session, wait for
``GET /api/v1/metadata`` to respond, and expose an ``httpx.Client``
fixture pointed at the running container. The image must be built before
running the suite (see ../README.md). Override the image tag via the
``TIRO_SDC_SERVER_IMAGE`` env var; defaults to ``tiro-sdc-server:dev``.

The SDs the tests rely on (OPAT + onco questionnaires) are already baked
into the wrapper image, so per-fixture ``sd/`` subdirs in the fixture
tree are informational — the running container doesn't see them.
"""
from __future__ import annotations

import contextlib
import os
import socket
import subprocess
import time
from pathlib import Path

import httpx
import pytest

IMAGE = os.environ.get("TIRO_SDC_SERVER_IMAGE", "tiro-sdc-server:dev")
READY_TIMEOUT_S = 30

FIXTURE_ROOT = Path(__file__).parent / "fixtures"


def fixture_dirs() -> list[Path]:
    return sorted(p for p in FIXTURE_ROOT.iterdir() if p.is_dir() and not p.name.startswith("_"))


def _free_port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.fixture(scope="session")
def server_url() -> str:
    port = _free_port()
    try:
        cid = subprocess.check_output(
            ["docker", "run", "--rm", "-d", "-p", f"{port}:8000", IMAGE],
            timeout=30, stderr=subprocess.STDOUT,
        ).decode().strip()
    except subprocess.CalledProcessError as exc:
        pytest.skip(
            f"Could not start {IMAGE}: {exc.output.decode(errors='replace')[:400]}\n\n"
            f"Build the image first (see apps/tiro_sdc_server/README.md):\n"
            f"  docker buildx build apps/tiro_sdc_server "
            f"--secret id=license,src=path/to/license.jwt -t {IMAGE} ."
        )
    except FileNotFoundError:
        pytest.skip("docker not on PATH")

    url = f"http://127.0.0.1:{port}"
    deadline = time.monotonic() + READY_TIMEOUT_S
    last_error: str | None = None
    while time.monotonic() < deadline:
        try:
            r = httpx.get(f"{url}/api/v1/metadata", timeout=1.5)
            r.raise_for_status()
            break
        except Exception as exc:
            last_error = repr(exc)
            time.sleep(0.5)
    else:
        logs = subprocess.run(["docker", "logs", cid], capture_output=True, text=True)
        subprocess.run(["docker", "stop", cid], capture_output=True)
        pytest.fail(
            f"{IMAGE} did not become ready within {READY_TIMEOUT_S}s "
            f"(last error: {last_error}).\n--- container stdout ---\n{logs.stdout}\n"
            f"--- container stderr ---\n{logs.stderr}"
        )

    yield url

    subprocess.run(["docker", "stop", cid], capture_output=True)


@pytest.fixture(scope="session")
def client(server_url: str):
    with httpx.Client(base_url=server_url, timeout=10) as c:
        yield c
