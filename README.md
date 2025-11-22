# Content Core API for Coolify

A containerized API service for content extraction and AI-powered summarization, ready for Coolify deployment.

## Features

- 📄 **Document Extraction**: PDF, Word, Excel, PowerPoint, Markdown
- 🌐 **Web Scraping**: Intelligent URL content extraction with fallback engines
- 🎥 **Media Processing**: Video/audio transcription
- 🖼️ **OCR Support**: Image text extraction
- 🤖 **AI Summarization**: Multiple context-aware summary styles
- 🔄 **RESTful API**: Easy integration with n8n and other tools

## Quick Deploy to Coolify

### Option 1: GitHub Repository Deploy (Recommended)

1. **Fork or Push to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial content-core API setup"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **In Coolify**:
   - Go to your Coolify dashboard
   - Click "New Resource" → "Public Repository"
   - Enter your GitHub repository URL
   - Set Build Pack to "Docker Compose"
   - Configure environment variables (see below)
   - Deploy!

### Option 2: Direct Docker Compose Deploy

1. **In Coolify**:
   - Click "New Resource" → "Docker Compose"
   - Copy the contents of `docker-compose.yml`
   - Configure environment variables
   - Deploy!

## Environment Variables

Configure these in Coolify's environment variables section:

### Required (at least one LLM provider)
```env
# Choose at least one LLM provider for summarization
OPENAI_API_KEY=sk-your-key-here
# OR
ANTHROPIC_API_KEY=sk-ant-your-key-here
# OR
GOOGLE_API_KEY=your-google-key-here
```

### Optional Extraction Engines
```env
# For advanced web scraping
FIRECRAWL_API_KEY=your-firecrawl-key
JINA_API_KEY=your-jina-key

# Engine selection (defaults to auto)
CCORE_DOCUMENT_ENGINE=auto  # auto|simple|docling
CCORE_URL_ENGINE=auto        # auto|simple|firecrawl|jina
```

### Advanced Configuration
```env
# OCR for mathematical PDFs
ENABLE_FORMULA_OCR=true
FORMULA_THRESHOLD=3

# Output format for Docling
DOCLING_OUTPUT_FORMAT=markdown  # markdown|html|json

# Application settings
PORT=8000
WORKERS=1
MAX_UPLOAD_SIZE=100
LOG_LEVEL=INFO
```

## API Endpoints

Once deployed, access the API at your Coolify domain:

- `GET /` - API overview
- `GET /docs` - Interactive Swagger documentation
- `GET /health` - Health check endpoint
- `POST /extract` - Extract content from URL or text
- `POST /extract/file` - Extract from uploaded file
- `POST /clean` - Clean messy content
- `POST /summarize` - AI-powered summarization
- `POST /extract-and-summarize` - Combined operation

## Integration with n8n

### HTTP Request Node Example

1. **Extract Content**:
   ```json
   {
     "method": "POST",
     "url": "https://your-content-core.coolify.app/extract",
     "body": {
       "url": "https://example.com/document.pdf",
       "output_format": "markdown"
     }
   }
   ```

2. **Summarize with Context**:
   ```json
   {
     "method": "POST", 
     "url": "https://your-content-core.coolify.app/summarize",
     "body": {
       "content": "{{$json.content}}",
       "context": "action items"
     }
   }
   ```

3. **File Upload**:
   - Use Form-Data
   - Field: `file` (binary)
   - Field: `output_format` (text/markdown/json)

## Testing After Deployment

### Using curl:
```bash
# Health check
curl https://your-app.coolify.app/health

# Extract from URL
curl -X POST https://your-app.coolify.app/extract \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Upload and extract file
curl -X POST https://your-app.coolify.app/extract/file \
  -F "file=@document.pdf" \
  -F "output_format=markdown"
```

### Using the Interactive Docs:
Navigate to `https://your-app.coolify.app/docs` for Swagger UI

## Customization

### Custom Prompts
Mount a custom prompts directory:
1. Create prompts in your repo
2. Update docker-compose.yml volume mapping

### Configuration File
Edit `cc_config.yaml` to customize:
- Extraction engines
- AI models
- Processing settings
- Summarization contexts

## Monitoring

### Logs in Coolify
- View real-time logs in Coolify dashboard
- Filter by log level using `LOG_LEVEL` env var

### Health Checks
- Automatic health checks every 30 seconds
- Endpoint: `/health`
- Returns engine configuration and status

## Performance Tips

1. **For Large Documents**: 
   - Use `WORKERS=2` or more
   - Increase `MAX_UPLOAD_SIZE` as needed

2. **For Better PDF Extraction**:
   - Set `CCORE_DOCUMENT_ENGINE=docling`
   - Enable `ENABLE_FORMULA_OCR=true` for math-heavy PDFs

3. **For Faster Web Scraping**:
   - Use Firecrawl or Jina with API keys
   - Set specific engine instead of auto

## Troubleshooting

### Common Issues

1. **"No API key configured"**
   - Ensure at least one LLM provider key is set
   - Check environment variables in Coolify

2. **"Extraction failed"**
   - Check file size limits
   - Verify document format is supported
   - Review logs for specific errors

3. **"Timeout errors"**
   - Increase async_timeout in cc_config.yaml
   - Check network connectivity

## Support

- [Content Core Documentation](https://github.com/lfnovo/content-core)
- [API Issues](https://github.com/YOUR_USERNAME/content-core-api/issues)

## License

MIT License - See LICENSE file for details
