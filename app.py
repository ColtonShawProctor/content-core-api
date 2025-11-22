from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import content_core as cc
import asyncio
import os
import tempfile
import logging
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Content Core API starting up...")
    logger.info(f"Document Engine: {os.getenv('CCORE_DOCUMENT_ENGINE', 'auto')}")
    logger.info(f"URL Engine: {os.getenv('CCORE_URL_ENGINE', 'auto')}")
    yield
    # Shutdown
    logger.info("Content Core API shutting down...")

app = FastAPI(
    title="Content Core API",
    description="AI-powered content extraction and processing API",
    version="1.0.0",
    lifespan=lifespan
)

# Request models
class ExtractRequest(BaseModel):
    url: Optional[str] = None
    content: Optional[str] = None
    output_format: Optional[str] = "text"
    document_engine: Optional[str] = None
    url_engine: Optional[str] = None

class CleanRequest(BaseModel):
    content: str

class SummarizeRequest(BaseModel):
    content: str
    context: Optional[str] = None

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "content-core-api",
        "document_engine": os.getenv("CCORE_DOCUMENT_ENGINE", "auto"),
        "url_engine": os.getenv("CCORE_URL_ENGINE", "auto")
    }

# Extract content from URL or text
@app.post("/extract")
async def extract_content(request: ExtractRequest):
    try:
        params = {}
        
        if request.url:
            params["url"] = request.url
            if request.url_engine:
                params["url_engine"] = request.url_engine
        elif request.content:
            params["content"] = request.content
        else:
            raise HTTPException(status_code=400, detail="Either 'url' or 'content' must be provided")
        
        if request.output_format:
            params["output_format"] = request.output_format
            
        if request.document_engine:
            params["document_engine"] = request.document_engine
        
        logger.info(f"Extracting content with params: {params}")
        result = await cc.extract(params)
        
        return {
            "success": True,
            "content": result,
            "source": "url" if request.url else "text"
        }
    except Exception as e:
        logger.error(f"Extraction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Extract content from uploaded file
@app.post("/extract/file")
async def extract_file(
    file: UploadFile = File(...),
    output_format: Optional[str] = Form("text"),
    document_engine: Optional[str] = Form(None)
):
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as tmp_file:
            content = await file.read()
            tmp_file.write(content)
            tmp_path = tmp_file.name
        
        try:
            params = {
                "file_path": tmp_path,
                "output_format": output_format
            }
            
            if document_engine:
                params["document_engine"] = document_engine
            
            logger.info(f"Extracting from file: {file.filename}")
            result = await cc.extract(params)
            
            return {
                "success": True,
                "content": result,
                "filename": file.filename,
                "file_type": os.path.splitext(file.filename)[1]
            }
        finally:
            # Clean up temp file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
                
    except Exception as e:
        logger.error(f"File extraction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Clean content
@app.post("/clean")
async def clean_content(request: CleanRequest):
    try:
        logger.info("Cleaning content")
        result = await cc.clean(request.content)
        return {
            "success": True,
            "cleaned_content": result
        }
    except Exception as e:
        logger.error(f"Cleaning error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Summarize content
@app.post("/summarize")
async def summarize_content(request: SummarizeRequest):
    try:
        logger.info(f"Summarizing content with context: {request.context}")
        result = await cc.summarize_content(
            request.content,
            context=request.context
        )
        return {
            "success": True,
            "summary": result,
            "context": request.context
        }
    except Exception as e:
        logger.error(f"Summarization error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Combined extract and summarize
@app.post("/extract-and-summarize")
async def extract_and_summarize(
    url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    context: Optional[str] = Form(None),
    output_format: Optional[str] = Form("text")
):
    try:
        # Extract content first
        if url:
            params = {"url": url, "output_format": output_format}
            logger.info(f"Extracting from URL: {url}")
            content = await cc.extract(params)
        elif file:
            # Save and extract from file
            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as tmp_file:
                file_content = await file.read()
                tmp_file.write(file_content)
                tmp_path = tmp_file.name
            
            try:
                params = {"file_path": tmp_path, "output_format": output_format}
                logger.info(f"Extracting from file: {file.filename}")
                content = await cc.extract(params)
            finally:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
        else:
            raise HTTPException(status_code=400, detail="Either 'url' or 'file' must be provided")
        
        # Summarize the extracted content
        logger.info(f"Summarizing with context: {context}")
        summary = await cc.summarize_content(content, context=context)
        
        return {
            "success": True,
            "content": content,
            "summary": summary,
            "context": context,
            "source": "url" if url else f"file:{file.filename}"
        }
    except Exception as e:
        logger.error(f"Extract and summarize error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {
        "message": "Content Core API",
        "endpoints": [
            "/health - Health check",
            "/extract - Extract content from URL or text",
            "/extract/file - Extract content from uploaded file",
            "/clean - Clean messy content",
            "/summarize - Summarize content with optional context",
            "/extract-and-summarize - Combined extraction and summarization",
            "/docs - Interactive API documentation"
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
