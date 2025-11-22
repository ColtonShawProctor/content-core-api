FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set Python environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install Python dependencies with compatible versions
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    python-multipart \
    content-core \
    openai \
    anthropic \
    google-generativeai \
    beautifulsoup4 \
    PyMuPDF \
    python-dotenv \
    aiofiles \
    httpx

# Copy application code and config
COPY app.py .
COPY cc_config.yaml .

# Create temp directory
RUN mkdir -p /tmp/uploads

# Expose port (default 3000, can be overridden by PORT env var)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD sh -c "curl -f http://localhost:${PORT:-3000}/health || exit 1"

# Run the application (PORT env var can be set to change the port)
CMD sh -c "uvicorn app:app --host 0.0.0.0 --port ${PORT:-3000}"
