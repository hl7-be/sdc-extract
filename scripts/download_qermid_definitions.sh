#!/bin/bash
# Download the QERMID FHIR logical models (StructureDefinitions, CodeSystems,
# ValueSets, ImplementationGuide) into data/qermid/.
#
# QERMID's IG build does not produce a definitions.json.zip artifact, so this
# script uses the standard FHIR NPM package (package.tgz) which contains the
# same conformance resources under a `package/` prefix.
#
# Usage:
#   bash scripts/download_qermid_definitions.sh           # download if missing or stale
#   bash scripts/download_qermid_definitions.sh --force   # always re-download

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
URL="https://axelv.github.io/qermid/package.tgz"
TARGET_DIR="$ROOT_DIR/data/qermid"
TGZ_FILE="$TARGET_DIR/package.tgz"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$TARGET_DIR"

CURL_OPTS=(--location --fail --silent --show-error)
if [[ $FORCE -eq 0 && -f "$TGZ_FILE" ]]; then
  # Conditional GET — only re-download if upstream changed.
  CURL_OPTS+=(--time-cond "$TGZ_FILE")
fi

echo "=== Downloading $URL ==="
curl "${CURL_OPTS[@]}" --output "$TGZ_FILE" "$URL"

if [[ ! -s "$TGZ_FILE" ]]; then
  echo "Download failed: $TGZ_FILE is empty." >&2
  exit 1
fi

echo "=== Extracting into $TARGET_DIR ==="
# Remove previously extracted JSON files so deletions upstream propagate; keep the tgz.
find "$TARGET_DIR" -maxdepth 1 -type f ! -name "$(basename "$TGZ_FILE")" -delete
# Strip the leading `package/` directory from the tarball so files land flat in $TARGET_DIR.
tar -xzf "$TGZ_FILE" -C "$TARGET_DIR" --strip-components=1

echo "=== Done. $(find "$TARGET_DIR" -maxdepth 1 -type f ! -name "$(basename "$TGZ_FILE")" | wc -l | tr -d ' ') files extracted to $TARGET_DIR ==="
