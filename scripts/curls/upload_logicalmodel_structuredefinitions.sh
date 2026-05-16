#!/bin/bash
# Register the OPAT and onco logical-model StructureDefinitions with the local
# Tiro testserver (apps/tiro_sdc_extract).
#
# The server loads StructureDefinitions from $STRUCTURE_DEFINITIONS_DIR at
# startup (default: <repo>/data/structure-definitions/). This script copies the
# two logical-model SDs into that directory; restart the server afterwards so
# the new files are picked up.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
DATA_DIR="$ROOT_DIR/data/samples"
SD_DIR_DEFAULT="$ROOT_DIR/data/structure-definitions"

: "${STRUCTURE_DEFINITIONS_DIR:=$SD_DIR_DEFAULT}"
[ -f "$ROOT_DIR/.env" ] && source "$ROOT_DIR/.env"

mkdir -p "$STRUCTURE_DEFINITIONS_DIR"

SD_OPAT="${DATA_DIR}/StructureDefinition-opat-continuous-infusion-questionnaire.json"
SD_ONCO="${DATA_DIR}/StructureDefinition-onco-trastuzumab-questionnaire.json"

echo "=== Copying OPAT StructureDefinition into $STRUCTURE_DEFINITIONS_DIR ==="
cp "$SD_OPAT" "$STRUCTURE_DEFINITIONS_DIR/"

echo "=== Copying ONCO StructureDefinition into $STRUCTURE_DEFINITIONS_DIR ==="
cp "$SD_ONCO" "$STRUCTURE_DEFINITIONS_DIR/"

echo ""
echo "Done. Restart the Tiro testserver so it picks up the new StructureDefinitions,"
echo "then run working_extraction_opat_logicalmodel.sh / working_extraction_onco_logicalmodel.sh."
