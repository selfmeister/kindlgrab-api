#!/bin/bash
set -e

# Deployment script for kindlgrab-api
# Usage: ./deploy.sh

SERVER="root@46.225.58.246"
REMOTE_DIR="~/kindlgrab-api"

echo "🚀 Deploying kindlgrab-api to server..."

# 1. Sync code (excluding data directories)
echo "📦 Syncing code..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='embeddings.faiss' \
  --exclude='output' \
  --exclude='.env' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  ./ ${SERVER}:${REMOTE_DIR}/

# 2. Rebuild and restart
echo "🔨 Rebuilding Docker container..."
ssh ${SERVER} "cd ${REMOTE_DIR} && docker-compose down && docker-compose build --no-cache && docker-compose up -d"

# 3. Wait for health check
echo "⏳ Waiting for service to start..."
sleep 60

# 4. Test
echo "🧪 Testing endpoints..."
ssh ${SERVER} "curl -f http://localhost:8000/health" && echo "✅ Health check passed"

echo ""
echo "✅ Deployment complete!"
echo "🌐 API: https://rag.elicitiq.com"
echo ""
echo "Test with:"
echo "  curl https://rag.elicitiq.com/health"
