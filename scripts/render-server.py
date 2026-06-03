#!/usr/bin/env python3
"""Dev server for the in-browser SDC extract + bundle-view demo.

Serves the repo as static files AND proxies ``POST /extract`` to an R4 SDC
``$extract`` backend. The proxy exists so the browser can stay *same-origin*:
the local ``tiro_sdc_server`` image ships no CORS headers, and the public
``sdc.tiro.health`` endpoint is R5 (it rejects this repo's R4 samples).

Usage::

    # 1. Start the R4 extract backend (the repo's tiro_sdc_server):
    docker compose --profile server up --build -d extract   # -> :8000/api/v1

    # 2. Serve the pages and proxy $extract through one origin:
    python3 scripts/render-server.py                         # -> :8888

Then open http://localhost:8888/extract-demo.html

Point the proxy elsewhere with EXTRACT_URL, e.g. the eHealth HAPI testserver::

    EXTRACT_URL='https://hapi.fhir-testserver.be/fhir/<tenant>/QuestionnaireResponse/$extract?api_key=<key>' \
        python3 scripts/render-server.py
"""
from __future__ import annotations

import argparse
import os
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_EXTRACT_URL = "http://localhost:8000/api/v1/QuestionnaireResponse/$extract"
EXTRACT_URL = os.environ.get("EXTRACT_URL", DEFAULT_EXTRACT_URL)
FHIR_JSON = "application/fhir+json"


def _outcome(text: str) -> bytes:
    """A minimal FHIR OperationOutcome the bundle-view page can surface."""
    import json

    return json.dumps(
        {
            "resourceType": "OperationOutcome",
            "issue": [{"severity": "error", "code": "exception", "details": {"text": text}}],
        }
    ).encode()


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, directory=REPO_ROOT, **kwargs)

    def do_POST(self) -> None:  # noqa: N802 (stdlib naming)
        if self.path.rstrip("/") != "/extract":
            self.send_error(404, "Only POST /extract is proxied")
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        request = urllib.request.Request(
            EXTRACT_URL,
            data=body,
            method="POST",
            headers={"Content-Type": FHIR_JSON, "Accept": FHIR_JSON},
        )

        try:
            with urllib.request.urlopen(request, timeout=120) as resp:
                data, status, ctype = resp.read(), resp.status, resp.headers.get("Content-Type", FHIR_JSON)
        except urllib.error.HTTPError as exc:  # backend answered with an error status
            data, status, ctype = exc.read(), exc.code, exc.headers.get("Content-Type", FHIR_JSON)
        except Exception as exc:  # backend unreachable / timed out
            data, status, ctype = _outcome(f"Cannot reach extract backend at {EXTRACT_URL}: {exc}"), 502, FHIR_JSON

        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8888")))
    args = parser.parse_args()

    print(f"Serving {REPO_ROOT}")
    print(f"  http://localhost:{args.port}/                  (renderers, index.html)")
    print(f"  http://localhost:{args.port}/extract-demo.html (form -> $extract -> bundle view)")
    print(f"Proxying POST /extract -> {EXTRACT_URL}")
    ThreadingHTTPServer(("", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
