FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements-api.txt .

# Install Python dependencies (slim API-only requirements)
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu -r requirements-api.txt

# Copy ONLY app code (not data)
COPY query/ ./query/
COPY config/ ./config/
COPY .env.example .env

# Create directories for mounting
RUN mkdir -p embeddings.faiss output

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the API server
CMD ["python", "-m", "uvicorn", "query.api_server:app", "--host", "0.0.0.0", "--port", "8000"]
