#!/bin/bash
# Docker deployment script for RAG API

set -e

echo "==================================="
echo "RAG API Docker Deployment"
echo "==================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed${NC}"
    echo "Install Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}docker-compose is not installed${NC}"
    echo "Install docker-compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${YELLOW}Step 1: Checking .env file...${NC}"

if [ ! -f .env ]; then
    echo -e "${RED}.env file not found!${NC}"
    echo "Creating from .env.example..."
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env file with your API keys${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 2: Building Docker image...${NC}"
docker-compose build

echo -e "${YELLOW}Step 3: Starting containers...${NC}"
docker-compose up -d

echo -e "${YELLOW}Step 4: Waiting for service to be ready...${NC}"
sleep 10

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}Container is running!${NC}"
else
    echo -e "${RED}Container failed to start${NC}"
    echo "Check logs: docker-compose logs"
    exit 1
fi

# Test health endpoint
echo -e "${YELLOW}Step 5: Testing health endpoint...${NC}"
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}Health check passed!${NC}"
else
    echo -e "${RED}Health check failed${NC}"
    echo "Check logs: docker-compose logs rag-api"
    exit 1
fi

echo ""
echo -e "${GREEN}==================================="
echo "Docker Deployment Complete!"
echo "===================================${NC}"
echo ""
echo "Container status: docker-compose ps"
echo "View logs: docker-compose logs -f rag-api"
echo "Stop: docker-compose down"
echo "Restart: docker-compose restart"
echo ""
echo "API URL: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo ""
