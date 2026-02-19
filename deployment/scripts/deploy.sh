#!/bin/bash
# Deployment script for RAG API on your server

set -e  # Exit on error

echo "==================================="
echo "RAG API Deployment Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run as root${NC}"
    exit 1
fi

# Configuration
PROJECT_DIR="$HOME/kindlgrab"
VENV_DIR="$PROJECT_DIR/venv"
LOG_DIR="/var/log/rag-api"

echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $PYTHON_VERSION"

echo -e "${YELLOW}Step 2: Setting up project directory...${NC}"

# Create project directory if it doesn't exist
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}.env file not found!${NC}"
    echo "Creating from .env.example..."
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env file with your API keys${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 3: Setting up Python virtual environment...${NC}"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

echo -e "${YELLOW}Step 4: Installing dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt
pip install uvicorn[standard] fastapi

echo -e "${YELLOW}Step 5: Setting up logging...${NC}"

# Create log directory
sudo mkdir -p "$LOG_DIR"
sudo chown $USER:$USER "$LOG_DIR"

echo -e "${YELLOW}Step 6: Testing the API...${NC}"

# Test if API can start
timeout 10s python -m uvicorn query.api_server:app --host 127.0.0.1 --port 8001 &
PID=$!
sleep 5

if ps -p $PID > /dev/null; then
    echo -e "${GREEN}API test successful!${NC}"
    kill $PID
else
    echo -e "${RED}API failed to start${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 7: Setting up systemd service...${NC}"

# Update systemd service file with actual paths
SERVICE_FILE="deployment/systemd/rag-api.service"
TEMP_SERVICE="/tmp/rag-api.service"

sed "s|YOUR_USERNAME|$USER|g" "$SERVICE_FILE" | \
sed "s|/path/to/kindlgrab|$PROJECT_DIR|g" > "$TEMP_SERVICE"

# Install systemd service
sudo cp "$TEMP_SERVICE" /etc/systemd/system/rag-api.service
sudo systemctl daemon-reload
sudo systemctl enable rag-api.service

echo -e "${GREEN}Systemd service installed${NC}"

echo -e "${YELLOW}Step 8: Starting the service...${NC}"

sudo systemctl start rag-api.service
sleep 3

if sudo systemctl is-active --quiet rag-api.service; then
    echo -e "${GREEN}Service started successfully!${NC}"
else
    echo -e "${RED}Service failed to start. Check logs:${NC}"
    echo "sudo journalctl -u rag-api.service -n 50"
    exit 1
fi

echo ""
echo -e "${GREEN}==================================="
echo "Deployment Complete!"
echo "===================================${NC}"
echo ""
echo "Service status: sudo systemctl status rag-api.service"
echo "View logs: sudo journalctl -u rag-api.service -f"
echo "API URL: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo ""
echo "Next steps:"
echo "1. Set up nginx reverse proxy (see deployment/nginx/rag-api.conf)"
echo "2. Set up SSL with Let's Encrypt"
echo "3. Test the API: curl http://localhost:8000/health"
echo ""
