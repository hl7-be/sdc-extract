# syntax=docker/dockerfile:1.7
#
# Thin wrapper around the upstream tiro-sdc-server engine. Layers:
#   1. The 5 StructureDefinitions for the June 2026 BE FHIR-a-thon.
#   2. A JWT license valid until 2026-06-15, fetched at build time from a
#      public GitHub gist. The JWT lands inside the image at
#      /etc/sdc-server/license.jwt and is recoverable by anyone who pulls
#      — acceptable here because the JWT expires within weeks and the
#      gist URL is itself effectively public.
#
# To rotate the license: mint a new JWT, replace the gist content (or
# create a new gist), update LICENSE_URL below, rebuild.
#
# Local build:
#     docker build . -t tiro-sdc-server:dev

ARG BASE_TAG=latest
ARG LICENSE_URL=https://gist.githubusercontent.com/axelv/fd1739296c58e109ce15e054b43c340e/raw/beb3b821056f603042b569c56f437f70cc507fff/license.jwt

FROM europe-west1-docker.pkg.dev/tiroapp-4cb17/public/tiro-sdc-server:${BASE_TAG}

ARG LICENSE_URL
USER root

# Need to relax write protection on the two locations we modify; lock them
# back down at the end of the build.
RUN chmod u+w /app/data/structure-definitions /etc/sdc-server

COPY --chown=sdc:sdc structure-definitions/ /app/data/structure-definitions/

# Fetch the demo JWT from the public gist. The Python base image has
# urllib.request available; no extra packages needed.
RUN set -eu \
    && case "${LICENSE_URL}" in *REPLACE-ME*) \
         echo "ERROR: LICENSE_URL has not been set. Edit the Dockerfile default or pass --build-arg LICENSE_URL=https://gist.githubusercontent.com/<owner>/<id>/raw/license.jwt" >&2; \
         exit 1;; esac \
    && python3 -c "import urllib.request; urllib.request.urlretrieve('${LICENSE_URL}', '/etc/sdc-server/license.jwt')" \
    && chmod 0444 /etc/sdc-server/license.jwt \
    && chown sdc:sdc /etc/sdc-server/license.jwt

RUN chmod -R a-w /app/data/structure-definitions /etc/sdc-server
USER sdc
