# tiro_sdc_server (BE FHIR-a-thon June 2026 wrapper)

A thin wrapper around [`Tiro-health/sdc-server`](https://github.com/Tiro-health/sdc-server)
that bakes in:

- The 5 StructureDefinitions for the BE FHIR-a-thon demos
  (`Observation`, `DiagnosticReport`, `DeviceUseStatement`, the OPAT
  continuous-infusion questionnaire, the onco trastuzumab questionnaire).
- A JWT license valid until **2026-06-15**.

The resulting image is published as multi-arch (linux/amd64 + linux/arm64)
to `ghcr.io/hl7-be/tiro-sdc-server`. Pull and run, no auth, no license
file to plumb:

```bash
docker run --rm -p 8000:8000 ghcr.io/hl7-be/tiro-sdc-server:latest
curl http://localhost:8000/api/v1/metadata
```

After 2026-06-15 the container will refuse to start —
`License expired: Signature has expired`. Cut a new tag if you need it for
longer.

## What the wrapper layers on the upstream image

```
ghcr.io/hl7-be/tiro-sdc-server
  └── (this Dockerfile)
        ├── /app/data/structure-definitions/     ← the 5 SDs below
        └── /etc/sdc-server/license.jwt          ← demo JWT
              ▲
              FROM europe-west1-docker.pkg.dev/tiroapp-4cb17/public/tiro-sdc-server:vX.Y.Z
              (the engine: FastAPI + fhir-sdc Rust core + JWT verifier)
```

The upstream image ships with the JWT verifier, the bytecode integrity
manifest, and zero StructureDefinitions. We supply the SDs and the
license.

## Endpoints

Inherited from the upstream image:

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/metadata` | FHIR `CapabilityStatement` |
| POST | `/api/v1/QuestionnaireResponse/$extract` | Definition-based extraction |

## Building locally

You need:

- gcloud auth with `secretmanager.secretAccessor` on
  `atticus-license-signing-key` (granted to `engineering@tiro.health`)
- Docker with Buildx

```bash
# 1. Mint a fresh test license (1 day is enough for local work).
KEY=$(mktemp); trap 'shred -u "$KEY" 2>/dev/null || rm -f "$KEY"' EXIT
gcloud secrets versions access latest \
    --secret=atticus-license-signing-key --project=tiroapp-4cb17 > "$KEY"

# Adjust the path to wherever Tiro-health/sdc-server is checked out.
uv run --no-project --with cryptography --with pyjwt \
    python ../../../fhir-a-thon-sdc-server/scripts/mint_license.py \
    --private-key "$KEY" \
    --subject "local-dev" \
    --days 1 \
    --out /tmp/dev-license.jwt

# 2. Build the wrapper image.
docker buildx build apps/tiro_sdc_server \
    --secret id=license,src=/tmp/dev-license.jwt \
    -t tiro-sdc-server:dev .
shred -u /tmp/dev-license.jwt 2>/dev/null || rm -f /tmp/dev-license.jwt
```

To pin a specific upstream version:

```bash
docker buildx build apps/tiro_sdc_server \
    --build-arg BASE_TAG=v0.1.0-rc2 \
    --secret id=license,src=/tmp/dev-license.jwt \
    -t tiro-sdc-server:dev .
```

## Integration tests

`apps/tiro_sdc_server/tests/` boots the image and exercises the OPAT +
onco fixtures over HTTP. Build the image first, then:

```bash
cd apps/tiro_sdc_server
uv run --no-project --with httpx --with pytest pytest
```

Override the image with `TIRO_SDC_SERVER_IMAGE` env if you want to test
against a tagged build instead of `tiro-sdc-server:dev`.

## Publishing

Pushed automatically by
[`.github/workflows/tiro-sdc-server-image.yml`](../../.github/workflows/tiro-sdc-server-image.yml)
on every push to `main` and every `v*` tag. The license is supplied via
the GitHub Actions secret `SDC_SERVER_LICENSE`.
