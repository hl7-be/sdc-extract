# syntax=docker/dockerfile:1.7
#
# Thin wrapper around the upstream tiro-sdc-server engine. Layers:
#   1. The 5 StructureDefinitions for the June 2026 BE FHIR-a-thon
#      (generic Observation/DiagnosticReport/DeviceUseStatement + the
#      OPAT and onco questionnaire SDs).
#   2. A JWT license valid until 2026-06-15 (after the event), passed in
#      at build time as a BuildKit secret. The license file lands inside
#      the published image at /etc/sdc-server/license.jwt and is therefore
#      recoverable by anyone who pulls — acceptable here because the JWT
#      expires within weeks and is scoped to this demo.
#
# Local build:
#     # mint a JWT into ./license.jwt (see README), then:
#     docker buildx build apps/tiro_sdc_server \
#         --secret id=license,src=./license.jwt \
#         -t tiro-sdc-server:dev .
#
# CI builds this image multi-arch via .github/workflows/tiro-sdc-server-image.yml.

ARG BASE_TAG=v0.1.0-rc2
FROM europe-west1-docker.pkg.dev/tiroapp-4cb17/public/tiro-sdc-server:${BASE_TAG}

USER root

# Need to relax write protection on the two locations we modify; lock them
# back down at the end of the build.
RUN chmod u+w /app/data/structure-definitions /etc/sdc-server

COPY --chown=sdc:sdc structure-definitions/ /app/data/structure-definitions/

RUN --mount=type=secret,id=license,required=true \
    cp /run/secrets/license /etc/sdc-server/license.jwt \
    && chmod 0444 /etc/sdc-server/license.jwt \
    && chown sdc:sdc /etc/sdc-server/license.jwt

RUN chmod -R a-w /app/data/structure-definitions /etc/sdc-server
USER sdc
