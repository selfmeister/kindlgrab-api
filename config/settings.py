"""
Configuration settings for the RAG system.
"""

# Search settings
TOP_K_RESULTS = 5
SIMILARITY_THRESHOLD = 0.5
RERANKER_MODEL = "cross-encoder/ms-marco-MiniLM-L-6-v2"
USE_HYBRID_SEARCH = True
BM25_WEIGHT = 0.3
SEMANTIC_WEIGHT = 0.7

# Model settings
EMBEDDING_MODEL = "sentence-transformers/all-mpnet-base-v2"
LLM_MODEL = "gpt-4"
TEMPERATURE = 0.0

# Processing settings
CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200
MAX_CHUNKS_PER_DOCUMENT = 50 