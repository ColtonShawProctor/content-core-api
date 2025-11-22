# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for various extraction libraries
RUN apt-get update && apt-get install -y \
    # Basic tools
    curl \
    git \
    # Build essentials for some Python packages
    build-essential \
    # For video/audio processing
    ffmpeg \
    # For OCR (optional)
    tesseract-ocr \
    tesseract-ocr-eng \
    # For file type detection
    libmagic1 \
    # For image processing
    libjpeg-dev \
    zlib1g-dev \
    # Clean up to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Set Python environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and config
COPY app.py .
COPY cc_config.yaml .

# Create directory for temporary file uploads
RUN mkdir -p /tmp/uploads

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
