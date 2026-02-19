"""
Lightweight RAG Search API

FAISS vector search only — no LLM calls on the server.
ChatGPT (or any client) handles synthesis from the returned chunks.
"""

import os
import secrets
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Depends, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from dotenv import load_dotenv

try:
    from langchain_community.vectorstores import FAISS
except ModuleNotFoundError:
    from langchain.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings

from config.domains import get_all_domains, get_domain_metadata

# Load environment variables
load_dotenv()

# Security
security = HTTPBearer(auto_error=True)
API_KEY = os.getenv("RAG_API_KEY")
if not API_KEY:
    raise RuntimeError("RAG_API_KEY must be set in the environment.")

# Initialize FastAPI
app = FastAPI(
    title="Personal RAG Knowledge Base",
    description="Vector search API for your personal knowledge base. Returns relevant document chunks — let ChatGPT synthesize the answer.",
    version="3.0.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)

allowed_hosts_env = os.getenv("ALLOWED_HOSTS", "rag.elicitiq.com,localhost,127.0.0.1")
allowed_hosts = [h.strip() for h in allowed_hosts_env.split(",") if h.strip()]
app.add_middleware(TrustedHostMiddleware, allowed_hosts=allowed_hosts)

# Global vectorstore
vectorstore: Optional[FAISS] = None


# ── Models ────────────────────────────────────────────────────────────────────

class SearchRequest(BaseModel):
    query: str = Field(..., description="The question to search for", min_length=1)
    top_k: int = Field(default=8, description="Number of chunks to return", ge=1, le=30)


class Chunk(BaseModel):
    text: str = Field(..., description="Content of the chunk, often containing inline academic citations")
    score: float = Field(..., description="Similarity score (lower = more similar)")
    source: Optional[str] = Field(default=None, description="Source document (book or paper title, e.g. 'Armenakis & Harris, 2009')")
    domain: Optional[str] = Field(default=None, description="Primary knowledge domain")
    metadata: Optional[dict] = Field(default=None, description="All available metadata for this chunk")


class SearchResponse(BaseModel):
    query: str
    chunks: List[Chunk]
    total_chunks_in_store: int


class HealthResponse(BaseModel):
    status: str
    vectorstore_loaded: bool
    total_chunks: int
    available_domains: List[str]


# ── Auth ──────────────────────────────────────────────────────────────────────

async def verify_api_key(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    if credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization scheme",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not secrets.compare_digest(credentials.credentials, API_KEY):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return credentials.credentials


# ── Vectorstore loading ───────────────────────────────────────────────────────

def load_vectorstore() -> FAISS:
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-mpnet-base-v2",
        model_kwargs={"device": "cpu"}
    )
    vectorstore_dir = "embeddings.faiss"
    index_path = os.path.join(vectorstore_dir, "index.faiss")
    pkl_path = os.path.join(vectorstore_dir, "index.pkl")

    if not os.path.isdir(vectorstore_dir) or not os.path.exists(index_path) or not os.path.exists(pkl_path):
        raise FileNotFoundError("Vector store not found. Please process documents first.")

    if not os.getenv("DOCKER_CONTAINER"):
        stats = os.stat(index_path)
        if stats.st_uid != os.getuid():
            raise PermissionError("Embeddings file ownership mismatch.")

    return FAISS.load_local(
        vectorstore_dir, embeddings, allow_dangerous_deserialization=True
    )


def _extract_domain(metadata: dict) -> Optional[str]:
    domains = metadata.get("domains")
    if isinstance(domains, dict):
        primary = domains.get("primary")
        if isinstance(primary, dict):
            return primary.get("name")
        if isinstance(primary, str):
            return primary
    if isinstance(domains, list) and domains:
        return domains[0]
    if isinstance(domains, str):
        return domains
    return metadata.get("domain")


# ── Startup ───────────────────────────────────────────────────────────────────

@app.on_event("startup")
async def startup_event():
    global vectorstore
    try:
        print("Loading vector store...")
        vectorstore = load_vectorstore()
        n = vectorstore.index.ntotal
        print(f"Vector store loaded: {n} chunks")
    except Exception as e:
        print(f"Error loading vector store: {e}")
        raise


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", response_model=HealthResponse, tags=["General"])
async def health_check():
    if vectorstore is None:
        raise HTTPException(status_code=503, detail="Vector store not loaded")
    domains = [
        get_domain_metadata(d).name
        for d in get_all_domains()
        if get_domain_metadata(d)
    ]
    return HealthResponse(
        status="healthy",
        vectorstore_loaded=True,
        total_chunks=vectorstore.index.ntotal,
        available_domains=domains,
    )


@app.post("/search", response_model=SearchResponse, tags=["Search"])
async def search(
    request: SearchRequest,
    api_key: str = Depends(verify_api_key),
):
    """
    Search the knowledge base and return the most relevant document chunks.
    No LLM processing — just fast vector similarity search.
    Use these chunks as context for ChatGPT to synthesize an answer.
    """
    if vectorstore is None:
        raise HTTPException(status_code=503, detail="Vector store not loaded")

    try:
        results = vectorstore.similarity_search_with_score(request.query, k=request.top_k)

        chunks = []
        for doc, score in results:
            meta = doc.metadata or {}
            chunks.append(Chunk(
                text=doc.page_content,
                score=round(float(score), 4),
                source=meta.get("source"),
                domain=_extract_domain(meta),
                metadata=meta,
            ))

        return SearchResponse(
            query=request.query,
            chunks=chunks,
            total_chunks_in_store=vectorstore.index.ntotal,
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {str(e)}")

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "status_code": exc.status_code},
    )


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "127.0.0.1")
    uvicorn.run(app, host=host, port=port, log_level="info")
