#!/bin/bash
# SSL setup script using Let's Encrypt

set -e

echo "==================================="
echo "SSL Setup with Let's Encrypt"
echo "==================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Get domain name
read -p "Enter your domain name (e.g., rag.example.com): " DOMAIN
read -p "Enter your email for Let's Encrypt notifications: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}Domain and email are required${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing certbot...${NC}"

# Install certbot
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

echo -e "${YELLOW}Step 2: Obtaining SSL certificate...${NC}"

# Stop nginx temporarily
systemctl stop nginx

# Get certificate
certbot certonly --standalone \
    --preferred-challenges http \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

echo -e "${YELLOW}Step 3: Configuring nginx with SSL...${NC}"

# Update nginx config with domain
NGINX_CONFIG="/etc/nginx/sites-available/rag-api"
sed -i "s/your-domain.com/$DOMAIN/g" "$NGINX_CONFIG"

# Uncomment HTTPS section
sed -i '/# HTTPS configuration/,/# }/s/^# //' "$NGINX_CONFIG"

# Test nginx configuration
nginx -t

# Start nginx
systemctl start nginx
systemctl enable nginx

echo -e "${YELLOW}Step 4: Setting up auto-renewal...${NC}"

# Test renewal
certbot renew --dry-run

echo ""
echo -e "${GREEN}==================================="
echo "SSL Setup Complete!"
echo "===================================${NC}"
echo ""
echo "Your API is now available at: https://$DOMAIN"
echo "Certificate will auto-renew via certbot"
echo ""
echo "Test your setup:"
echo "curl https://$DOMAIN/health"
echo ""
