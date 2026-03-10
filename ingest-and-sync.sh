#!/bin/bash
set -euo pipefail

# End-to-end update:
# 1) Ingest new PDFs in local kindlgrab
# 2) Regenerate FAISS embeddings from output/chunks.json
# 3) Sync to server and restart API
#
# Usage:
#   ./ingest-and-sync.sh
#   ./ingest-and-sync.sh --limit 2
#   ./ingest-and-sync.sh --skip "some_file.pdf"

LOCAL_KINDLGRAB="/Users/me/PycharmProjects/kindlgrab"
INGEST_CLI="${LOCAL_KINDLGRAB}/ingest_cli.py"
REGENERATE_CMD="python -m ingest.regenerate_embeddings"
SYNC_SCRIPT="$(cd "$(dirname "$0")" && pwd)/sync-embeddings.sh"

if [ ! -d "${LOCAL_KINDLGRAB}" ]; then
    echo "Error: kindlgrab repo not found at ${LOCAL_KINDLGRAB}"
    exit 1
fi

if [ ! -f "${INGEST_CLI}" ]; then
    echo "Error: ingest_cli.py not found at ${INGEST_CLI}"
    exit 1
fi

if [ ! -f "${SYNC_SCRIPT}" ]; then
    echo "Error: sync script not found at ${SYNC_SCRIPT}"
    exit 1
fi

echo "Step 1/3: Running local ingestion pipeline..."
cd "${LOCAL_KINDLGRAB}"

# Activate venv if available, otherwise rely on current python env
if [ -f "venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    source "venv/bin/activate"
fi

python ingest_cli.py "$@"

echo "Step 2/3: Regenerating FAISS embeddings..."
${REGENERATE_CMD}

echo "Step 3/3: Syncing embeddings to server..."
bash "${SYNC_SCRIPT}"

echo ""
echo "Done. New documents have been ingested and deployed."
