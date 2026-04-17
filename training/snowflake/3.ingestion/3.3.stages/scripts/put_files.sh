#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE_DIR="$(realpath "$SCRIPT_DIR/../../../../../archive")"

STAGE="@RAW_DEV.SQL_SERVER.LANDING"
CONNECTION="ingestion"

echo "Uploading files from: $ARCHIVE_DIR"
echo "Target stage: $STAGE"
echo "---"

for filepath in "$ARCHIVE_DIR"/*.csv; do
    [ -f "$filepath" ] || { echo "No CSV files found in $ARCHIVE_DIR"; exit 1; }
    filename="$(basename "$filepath")"
    echo "Uploading $filename ..."
    uv run snow sql \
        -q "PUT file://$filepath $STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;" \
        -c "$CONNECTION"
done

echo "---"
echo "Done."
