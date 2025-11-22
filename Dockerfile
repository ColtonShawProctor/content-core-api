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

# Install ALL Python dependencies directly (no requirements.txt needed)
RUN pip install --no-cache-dir \
    fastapi==0.109.0 \
    uvicorn[standard]==0.27.0 \
    python-multipart==0.0.6 \
    content-core==0.1.9 \
    openai==1.10.0 \
    anthropic==0.18.1 \
    google-generativeai==0.3.2 \
    beautifulsoup4==4.12.3 \
    PyMuPDF==1.23.21 \
    python-dotenv==1.0.0 \
    aiofiles==23.2.1 \
    httpx==0.26.0

# Copy application code only (no requirements.txt needed)
COPY app.py .

# Create temp directory
RUN mkdir -p /tmp/uploads

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
