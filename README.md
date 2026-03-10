# KindlGrab RAG API

Lightweight FastAPI server for querying a personal knowledge base via vector similarity search. Designed for ChatGPT Actions integration.

## What This Does

- **FAISS vector search** over academic literature chunks
- **REST API** with `/search` endpoint
- **ChatGPT Actions** integration via OpenAPI schema
- **Metadata-rich responses** with sources, domains, and full context

## Architecture

```
kindlgrab-api/
├── query/
│   └── api_server.py          # FastAPI server (FAISS search only)
├── config/
│   └── domains.py             # Knowledge domain metadata
├── deployment/
│   ├── chatgpt/               # ChatGPT integration files
│   │   ├── openapi-schema.yaml
│   │   └── gpt-instructions.md
│   └── nginx/
│       └── rag-api.conf       # Nginx reverse proxy config
├── docker-compose.yml
├── Dockerfile
├── requirements-api.txt       # Minimal dependencies
└── .env.example

# Data (mounted at runtime, NOT in repo)
embeddings.faiss/              # FAISS index + metadata
output/                        # Original chunk JSONs
```

## Setup

### 1. Environment Variables

```bash
cp .env.example .env
# Edit .env and set:
# RAG_API_KEY=your_secure_key_here
```

### 2. Prepare Embeddings

**Generate embeddings locally** (in the `kindlgrab` ingestion repo):
```bash
# In kindlgrab repo (not this one)
python -m ingest.retrieval.embeddings
```

Then **sync to server**:
```bash
rsync -avz embeddings.faiss/ deploy@your-server:/srv/apps/kindlgrab-rag/embeddings.faiss/
rsync -avz output/ deploy@your-server:/srv/apps/kindlgrab-rag/output/
```

### 3. Deploy

**On server:**
```bash
cd /srv/apps/kindlgrab-rag
docker-compose build --no-cache
docker-compose up -d
```

**Test:**
```bash
curl https://rag.elicitiq.com/health
```

## API Usage

### Health Check
```bash
curl https://rag.elicitiq.com/health
```

### Search
```bash
curl -X POST https://rag.elicitiq.com/search \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the key principles of change management?",
    "top_k": 5,
    "include_metadata": false,
    "max_chars_per_chunk": 1800
  }'
```

**Response:**
```json
{
  "query": "What are the key principles of change management?",
  "chunks": [
    {
      "text": "Content with inline citations...",
      "score": 0.234,
      "source": "Armenakis & Harris, 2009",
      "domain": "Change Management",
      "truncated": false
    }
  ],
  "total_chunks_in_store": 21622
}
```

## ChatGPT Integration

### 1. Create Custom GPT

In ChatGPT:
- Go to **Explore GPTs** → **Create**
- Name: "Personal Knowledge Base"
- Description: "Search my academic library"

### 2. Add Action

- **Actions** → **Create new action**
- **Import from URL**: Paste contents of `deployment/chatgpt/openapi-schema.yaml`
- **Authentication**: API Key, Bearer
  - Header name: `Authorization`
  - Value: `Bearer YOUR_API_KEY`

### 3. Add Instructions

Copy contents of `deployment/chatgpt/gpt-instructions.md` into the **Instructions** field.

### 4. Test

Ask: "What are the key principles of change management?"

ChatGPT should call `searchKnowledgeBase`, retrieve chunks, and synthesize an answer with direct quotes and citations.

For follow-up turns, ChatGPT should rewrite references like "tell me more about that" into a standalone search query before calling the action again. The API itself is stateless; continuity comes from the GPT conversation, not server-side session storage.

## Deployment Notes

### Nginx Setup

```bash
# Copy config
sudo cp deployment/nginx/rag-api.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/rag-api.conf /etc/nginx/sites-enabled/

# Get SSL cert
sudo certbot --nginx -d rag.elicitiq.com

# Reload
sudo nginx -t
sudo systemctl reload nginx
```

### Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

### Update Embeddings

When you regenerate embeddings locally:

```bash
# On local machine (kindlgrab repo)
python -m ingest.retrieval.embeddings

# Sync to server
rsync -avz embeddings.faiss/ deploy@your-server:/srv/apps/kindlgrab-rag/embeddings.faiss/
rsync -avz output/ deploy@your-server:/srv/apps/kindlgrab-rag/output/

# Restart API (to reload vector store)
ssh deploy@your-server "cd /srv/apps/kindlgrab-rag && docker-compose restart"
```

## Dependencies

Minimal set for API-only deployment:

- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `langchain-community` - FAISS loader
- `langchain-huggingface` - Embeddings
- `faiss-cpu` - Vector search
- `sentence-transformers` - Embedding model
- `torch` (CPU-only) - Required by sentence-transformers

See `requirements-api.txt` for pinned versions.

## Troubleshooting

### Container won't start
```bash
docker-compose logs api
```

### Vector store not loading
- Check `embeddings.faiss/` exists and contains `index.faiss` and `index.pkl`
- Check file permissions: `chmod -R 755 embeddings.faiss/`

### 401 Unauthorized
- Verify `RAG_API_KEY` in `.env` matches the key in ChatGPT Actions

### 502 Bad Gateway
- Container is still starting (loading embeddings takes ~30-60s)
- Check: `docker-compose ps` - wait for `(healthy)` status

## Related Repos

- **kindlgrab** - Ingestion pipeline (local only, generates embeddings)
- **kindlgrab-api** - This repo (server deployment, query API only)

## License

Private use only.
