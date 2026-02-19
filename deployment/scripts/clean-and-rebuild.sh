#!/bin/bash
# Clean Docker and rebuild RAG API

set -e

echo "==================================="
echo "Cleaning Docker and Rebuilding RAG"
echo "==================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Stopping containers...${NC}"
docker-compose down || true

echo -e "${YELLOW}Step 2: Cleaning Docker system...${NC}"
docker system prune -a --volumes -f
docker volume prune -f
docker builder prune -a -f

echo -e "${YELLOW}Step 3: Restarting Docker daemon...${NC}"
sudo systemctl restart docker

echo -e "${YELLOW}Step 4: Building new image...${NC}"
docker-compose build --no-cache

echo -e "${YELLOW}Step 5: Starting container...${NC}"
docker-compose up -d

echo -e "${YELLOW}Step 6: Waiting for health check...${NC}"
sleep 10

# Check if healthy
if docker-compose ps | grep -q "healthy\|Up"; then
    echo -e "${GREEN}✓ Container is running!${NC}"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    echo "Checking logs:"
    docker-compose logs rag-api
    exit 1
fi

echo -e "${YELLOW}Step 7: Testing API...${NC}"
sleep 5

if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API is responding!${NC}"
else
    echo -e "${RED}✗ API not responding${NC}"
    docker-compose logs rag-api
    exit 1
fi

echo ""
echo -e "${GREEN}==================================="
echo "Rebuild Complete!"
echo "===================================${NC}"
echo ""
echo "Container status: docker-compose ps"
echo "View logs: docker-compose logs -f rag-api"
echo "API URL: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo ""
