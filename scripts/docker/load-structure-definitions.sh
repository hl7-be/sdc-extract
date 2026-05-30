#!/bin/sh
# Seed the BE FHIR-a-thon StructureDefinitions into the local HAPI server.
#
# Run as a one-shot container by docker-compose (service: hapi-loader). Waits
# for HAPI to answer /metadata, then PUTs each StructureDefinition by its own
# resource id so the load is idempotent. Per-file failures are logged but do
# not abort the run — a single bad profile must not block onboarding.
set -eu

HAPI_BASE_URL="${HAPI_BASE_URL:-http://hapi:8080/fhir}"
SD_DIR="${SD_DIR:-/sd}"
MAX_WAIT_TRIES="${MAX_WAIT_TRIES:-60}"
WAIT_INTERVAL="${WAIT_INTERVAL:-5}"

echo "[loader] installing curl + jq ..."
apk add --no-cache curl jq >/dev/null

echo "[loader] waiting for HAPI at ${HAPI_BASE_URL}/metadata ..."
tries=0
until curl -sf "${HAPI_BASE_URL}/metadata" >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "${tries}" -ge "${MAX_WAIT_TRIES}" ]; then
    echo "[loader] ERROR: HAPI did not become ready after $((MAX_WAIT_TRIES * WAIT_INTERVAL))s" >&2
    exit 1
  fi
  sleep "${WAIT_INTERVAL}"
done
echo "[loader] HAPI is ready."

loaded=0
failed=0
for f in "${SD_DIR}"/*.json; do
  [ -e "${f}" ] || continue
  id=$(jq -r '.id // empty' "${f}")
  if [ -z "${id}" ]; then
    echo "[loader] SKIP $(basename "${f}") — no .id field" >&2
    failed=$((failed + 1))
    continue
  fi

  status=$(curl -s -o /tmp/resp -w '%{http_code}' \
    -X PUT "${HAPI_BASE_URL}/StructureDefinition/${id}" \
    -H 'Content-Type: application/fhir+json' \
    --data-binary "@${f}")

  case "${status}" in
    20*)
      echo "[loader] OK   ${id} (HTTP ${status})"
      loaded=$((loaded + 1))
      ;;
    *)
      echo "[loader] FAIL ${id} (HTTP ${status})" >&2
      head -c 500 /tmp/resp >&2 2>/dev/null || true
      echo >&2
      failed=$((failed + 1))
      ;;
  esac
done

echo "[loader] done — ${loaded} loaded, ${failed} failed."
