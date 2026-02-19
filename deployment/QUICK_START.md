# Quick Start: Deploy RAG to Your Server

## 🚀 5-Minute Deployment

### Step 1: Prepare Your Server

```bash
# SSH into your server
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install essentials
sudo apt install -y python3 python3-pip python3-venv git nginx
```

### Step 2: Upload Your Project

```bash
# From your local machine
cd /Users/me/PycharmProjects
tar -czf kindlgrab.tar.gz kindlgrab/
scp kindlgrab.tar.gz root@46.225.58.246:~/

# On your server
ssh root@46.225.58.246
tar -xzf kindlgrab.tar.gz
cd kindlgrab
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Generate API key
python3 -c "import secrets; print('RAG_API_KEY=' + secrets.token_urlsafe(32))"

# Edit .env and add your keys
nano .env
```

Add these lines:
```bash
OPENAI_API_KEY=sk-your-openai-key-here
RAG_API_KEY=paste-generated-key-here
PORT=8000
HOST=127.0.0.1
ALLOWED_HOSTS=rag.elicitiq.com,localhost,127.0.0.1
```

### Step 4: Deploy (Choose One)

#### Option A: Quick Deploy with Systemd

```bash
chmod +x deployment/scripts/deploy.sh
./deployment/scripts/deploy.sh
```

#### Option B: Docker Deploy

```bash
# Install Docker first
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Deploy
chmod +x deployment/scripts/docker-deploy.sh
./deployment/scripts/docker-deploy.sh
```

### Step 5: Test It

```bash
# Check health
curl http://localhost:8000/health

# Test search (replace YOUR_API_KEY with your RAG_API_KEY from .env)
curl -X POST http://localhost:8000/search \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "test query", "top_k": 3}'
```

### Step 6: Make It Public (Optional)

#### With Domain Name:

```bash
# Set up nginx
sudo cp deployment/nginx/rag-api.conf /etc/nginx/sites-available/rag-api
sudo nano /etc/nginx/sites-available/rag-api
# Change: server_name your-domain.com;

sudo ln -s /etc/nginx/sites-available/rag-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Set up SSL
sudo chmod +x deployment/scripts/setup-ssl.sh
sudo ./deployment/scripts/setup-ssl.sh
```

#### Without Domain (Use IP):

For maximum safety, do not expose port 8000 publicly. Keep it bound to localhost and use nginx + HTTPS.

---

## 🤖 Connect to ChatGPT

### Create Custom GPT

1. Go to ChatGPT → **Create a GPT**

2. **Configure:**
   - Name: "My Knowledge Base"
   - Description: "Personal knowledge base assistant"

3. **Add Action:**
   - Click "Create new action"
   - Copy content from `deployment/chatgpt/openapi-schema.yaml`
   - Update server URL to: `https://your-domain.com` or `http://your-ip:8000`

4. **Authentication:**
   - Type: Bearer
   - Token: Your `RAG_API_KEY` from `.env`

5. **Test:**
   - Ask: "What topics are in my knowledge base?"

---

## 📝 Common Commands

### Systemd Deployment

```bash
# Start
sudo systemctl start rag-api

# Stop
sudo systemctl stop rag-api

# Restart
sudo systemctl restart rag-api

# Status
sudo systemctl status rag-api

# Logs
sudo journalctl -u rag-api -f
```

### Docker Deployment

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# Logs
docker-compose logs -f rag-api
```

---

## 🔧 Troubleshooting

### Service won't start?

```bash
# Check logs
sudo journalctl -u rag-api -n 50

# Or for Docker
docker-compose logs rag-api
```

### Can't connect?

```bash
# Check if running
sudo systemctl status rag-api

# Check port
sudo netstat -tulpn | grep 8000

# Open firewall for HTTPS
sudo ufw allow 443
```

### Need to update?

```bash
# Pull changes
git pull

# Restart
sudo systemctl restart rag-api
# Or: docker-compose restart
```

---

## 🎯 What You Get

✅ **Secure API** with authentication  
✅ **Auto-restart** on failure  
✅ **HTTPS** support (with domain)  
✅ **ChatGPT integration** ready  
✅ **Health monitoring**  
✅ **Production logging**  

---

## 📚 Full Documentation

See `DEPLOYMENT.md` for complete details on:
- Advanced configuration
- Security best practices
- Monitoring and maintenance
- Backup strategies
- Performance tuning

---

## 🆘 Need Help?

1. Check logs: `sudo journalctl -u rag-api -f`
2. Verify `.env` file has correct keys
3. Test health: `curl http://localhost:8000/health`
4. See `DEPLOYMENT.md` troubleshooting section

---

**You're all set! 🎉**

Your RAG system is now running and ready to use from ChatGPT or any app!
