# tiro_sdc_server (BE FHIR-a-thon June 2026 wrapper)

A thin wrapper around [`Tiro-health/sdc-server`](https://github.com/Tiro-health/sdc-server)
that bakes in:

- The 5 StructureDefinitions for the BE FHIR-a-thon demos
  (`Observation`, `DiagnosticReport`, `DeviceUseStatement`, the OPAT
  continuous-infusion questionnaire, the onco trastuzumab questionnaire).
- A JWT license valid until **2026-06-15**.

There's no published image — participants **build it locally**. The base
engine image is public on Tiro's GAR (`tiro-sdc-server:v0.1.0-rc2`); the
license JWT comes from `engineering@tiro.health` via Google Secret
Manager (or someone hands you a `license.jwt` file directly).

After 2026-06-15 the wrapper will refuse to start —
`License expired: Signature has expired`. Mint a new JWT and rebuild.

## What the wrapper layers on the upstream image

```
tiro-sdc-server:dev  (your locally-built image)
  └── (this Dockerfile)
        ├── /app/data/structure-definitions/     ← the 5 SDs below
        └── /etc/sdc-server/license.jwt          ← demo JWT
              ▲
              FROM europe-west1-docker.pkg.dev/tiroapp-4cb17/public/tiro-sdc-server:v0.1.0-rc2
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
  `atticus-license-signing-key` (granted to `engineering@tiro.health`),
  **or** a `license.jwt` file someone else minted for you.
- Docker with Buildx.

If you have gcloud access, mint a fresh license:

```bash
KEY=$(mktemp); trap 'shred -u "$KEY" 2>/dev/null || rm -f "$KEY"' EXIT
gcloud secrets versions access latest \
    --secret=atticus-license-signing-key --project=tiroapp-4cb17 > "$KEY"

# Adjust the path to wherever Tiro-health/sdc-server is checked out.
uv run --no-project --with cryptography --with pyjwt \
    python ../../../fhir-a-thon-sdc-server/scripts/mint_license.py \
    --private-key "$KEY" \
    --subject "local-dev" \
    --days 21 \
    --out /tmp/dev-license.jwt
```

If you've been handed a `license.jwt`, just use it directly. Then build:

```bash
docker buildx build apps/tiro_sdc_server \
    --secret id=license,src=/tmp/dev-license.jwt \
    -t tiro-sdc-server:dev .

shred -u /tmp/dev-license.jwt 2>/dev/null || rm -f /tmp/dev-license.jwt
```

To pin a specific upstream version:

```bash
docker buildx build apps/tiro_sdc_server \
    --build-arg BASE_TAG=v0.1.0-rc3 \
    --secret id=license,src=/tmp/dev-license.jwt \
    -t tiro-sdc-server:dev .
```

## Running

```bash
docker run --rm -p 8000:8000 tiro-sdc-server:dev
curl http://localhost:8000/api/v1/metadata
```

## Integration tests

`apps/tiro_sdc_server/tests/` boots the image you just built and
exercises the OPAT + onco fixtures over HTTP:

```bash
cd apps/tiro_sdc_server
uv run --no-project --with httpx --with pytest pytest
```

Override the image with the `TIRO_SDC_SERVER_IMAGE` env if you want to
test against a tagged build instead of `tiro-sdc-server:dev`.

CI runs the same suite on every PR (see
[`.github/workflows/tiro-sdc-server-integration-tests.yml`](../../.github/workflows/tiro-sdc-server-integration-tests.yml)).
