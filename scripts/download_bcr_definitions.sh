#!/bin/bash
# Download the Belgian Cancer Registry (BCR) FHIR definitions (StructureDefinitions,
# CodeSystems, ValueSets, ImplementationGuide) into data/bcr/.
#
# Usage:
#   bash scripts/download_bcr_definitions.sh           # download if missing or stale
#   bash scripts/download_bcr_definitions.sh --force   # always re-download

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
URL="https://axelv.github.io/bcr/definitions.json.zip"
TARGET_DIR="$ROOT_DIR/data/bcr"
ZIP_FILE="$TARGET_DIR/definitions.json.zip"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$TARGET_DIR"

CURL_OPTS=(--location --fail --silent --show-error)
if [[ $FORCE -eq 0 && -f "$ZIP_FILE" ]]; then
  # Conditional GET — only re-download if upstream changed.
  CURL_OPTS+=(--time-cond "$ZIP_FILE")
fi

echo "=== Downloading $URL ==="
curl "${CURL_OPTS[@]}" --output "$ZIP_FILE" "$URL"

if [[ ! -s "$ZIP_FILE" ]]; then
  echo "Download failed: $ZIP_FILE is empty." >&2
  exit 1
fi

echo "=== Extracting into $TARGET_DIR ==="
# Remove previously extracted JSON files so deletions upstream propagate; keep the zip.
find "$TARGET_DIR" -maxdepth 1 -type f ! -name "$(basename "$ZIP_FILE")" -delete
unzip -o -q "$ZIP_FILE" -d "$TARGET_DIR"

echo "=== Done. $(find "$TARGET_DIR" -maxdepth 1 -type f ! -name "$(basename "$ZIP_FILE")" | wc -l | tr -d ' ') files extracted to $TARGET_DIR ==="
