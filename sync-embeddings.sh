#!/bin/bash
set -e

# Sync embeddings from local kindlgrab repo to server
# Run this after regenerating embeddings locally

SERVER="root@46.225.58.246"
REMOTE_DIR="~/kindlgrab-api"
LOCAL_KINDLGRAB="/Users/me/PycharmProjects/kindlgrab"

echo "📊 Syncing embeddings to server..."

# Check if local embeddings exist
if [ ! -d "${LOCAL_KINDLGRAB}/embeddings.faiss" ]; then
    echo "❌ Error: ${LOCAL_KINDLGRAB}/embeddings.faiss not found"
    echo "Run embedding generation first in the kindlgrab repo"
    exit 1
fi

# Sync embeddings
echo "📤 Uploading FAISS index..."
rsync -avz --progress \
    ${LOCAL_KINDLGRAB}/embeddings.faiss/ \
    ${SERVER}:${REMOTE_DIR}/embeddings.faiss/

# Sync output chunks (optional, for metadata)
echo "📤 Uploading chunk files..."
rsync -avz --progress \
    ${LOCAL_KINDLGRAB}/output/ \
    ${SERVER}:${REMOTE_DIR}/output/

# Restart API to reload vector store
echo "🔄 Restarting API..."
ssh ${SERVER} "cd ${REMOTE_DIR} && docker-compose restart"

echo "⏳ Waiting for service to reload..."
sleep 30

# Test
echo "🧪 Testing..."
ssh ${SERVER} "curl -f http://localhost:8000/health" && echo "✅ Embeddings synced successfully"

echo ""
echo "✅ Done! Vector store updated with latest embeddings."
