# tiro_sdc_server (BE FHIR-a-thon June 2026 wrapper)

A thin wrapper around [`Tiro-health/sdc-server`](https://github.com/Tiro-health/sdc-server)
that bakes in:

- The 5 StructureDefinitions for the BE FHIR-a-thon demos
  (`Observation`, `DiagnosticReport`, `DeviceUseStatement`, the OPAT
  continuous-infusion questionnaire, the onco trastuzumab questionnaire).
- A demo JWT license valid until **2026-06-15**.

Participants **build it locally** on top of the public
`Tiro-health/sdc-server` image. After 2026-06-15 the container refuses
to start with `License expired` — ping Tiro for a fresh image.

## Endpoints

Inherited from the upstream image:

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/metadata` | FHIR `CapabilityStatement` |
| POST | `/api/v1/QuestionnaireResponse/$extract` | Definition-based extraction |

## Building locally

```bash
docker build . -t tiro-sdc-server:dev
```

The build tracks `tiro-sdc-server:latest` upstream. Override with
`--build-arg BASE_TAG=<tag>` to pin a specific version.

## Running

```bash
docker run --rm -p 8000:8000 tiro-sdc-server:dev
curl http://localhost:8000/api/v1/metadata
```

## Integration tests

`tests/` boots the image you just built and exercises the OPAT + onco
fixtures over HTTP:

```bash
uv run --no-project --with httpx --with pytest pytest
```

Override the image with the `TIRO_SDC_SERVER_IMAGE` env if you want to
test against a tagged build instead of `tiro-sdc-server:dev`.

CI runs the same suite on every PR (see
[`.github/workflows/tiro-sdc-server-integration-tests.yml`](../../.github/workflows/tiro-sdc-server-integration-tests.yml)).
