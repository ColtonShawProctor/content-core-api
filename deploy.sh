#!/bin/bash

# Content Core API Deployment Helper Script
# Usage: ./deploy.sh [local|build|push]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="content-core-api"
REGISTRY="${DOCKER_REGISTRY:-docker.io}"
REPO_NAME="${DOCKER_REPO:-yourusername}"
TAG="${VERSION:-latest}"
FULL_IMAGE="${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"

function print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Content Core API Deployment Helper${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

function check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed!${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose is not installed. Using docker compose command.${NC}"
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    echo -e "${GREEN}✓ Requirements satisfied${NC}"
}

function setup_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Creating .env file from template...${NC}"
        cp .env.template .env
        echo -e "${YELLOW}Please edit .env file with your API keys${NC}"
        echo -e "${YELLOW}Press Enter to continue after editing...${NC}"
        read
    fi
}

function local_test() {
    echo -e "${GREEN}Starting local test environment...${NC}"
    setup_env
    
    # Build the image
    echo -e "${YELLOW}Building Docker image...${NC}"
    docker build -t ${IMAGE_NAME}:local .
    
    # Start with docker-compose
    echo -e "${YELLOW}Starting services...${NC}"
    $COMPOSE_CMD up -d
    
    # Wait for health check
    echo -e "${YELLOW}Waiting for service to be healthy...${NC}"
    sleep 5
    
    # Test health endpoint
    echo -e "${YELLOW}Testing health endpoint...${NC}"
    curl -f http://localhost:8000/health || {
        echo -e "${RED}Health check failed!${NC}"
        echo -e "${YELLOW}Checking logs...${NC}"
        $COMPOSE_CMD logs --tail=50
        exit 1
    }
    
    echo -e "${GREEN}✓ Service is running at http://localhost:8000${NC}"
    echo -e "${GREEN}✓ API docs available at http://localhost:8000/docs${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  View logs:  $COMPOSE_CMD logs -f"
    echo "  Stop:       $COMPOSE_CMD down"
    echo "  Restart:    $COMPOSE_CMD restart"
}

function build_image() {
    echo -e "${GREEN}Building production Docker image...${NC}"
    
    docker build -t ${FULL_IMAGE} .
    
    echo -e "${GREEN}✓ Image built: ${FULL_IMAGE}${NC}"
}

function push_image() {
    echo -e "${GREEN}Pushing image to registry...${NC}"
    
    # Login check
    echo -e "${YELLOW}Make sure you're logged in to ${REGISTRY}${NC}"
    docker push ${FULL_IMAGE}
    
    echo -e "${GREEN}✓ Image pushed: ${FULL_IMAGE}${NC}"
}

function coolify_deploy() {
    echo -e "${GREEN}Preparing for Coolify deployment...${NC}"
    
    # Initialize git if needed
    if [ ! -d .git ]; then
        echo -e "${YELLOW}Initializing git repository...${NC}"
        git init
        git add .
        git commit -m "Initial content-core API setup"
    fi
    
    echo -e "${YELLOW}Steps to deploy to Coolify:${NC}"
    echo "1. Push to GitHub:"
    echo "   git remote add origin YOUR_GITHUB_REPO_URL"
    echo "   git push -u origin main"
    echo ""
    echo "2. In Coolify:"
    echo "   - New Resource → Public Repository"
    echo "   - Enter your GitHub URL"
    echo "   - Set Build Pack to 'Docker Compose'"
    echo "   - Configure environment variables from .env.template"
    echo ""
    echo "3. Required environment variables:"
    echo "   - OPENAI_API_KEY or ANTHROPIC_API_KEY or GOOGLE_API_KEY"
    echo "   - Optional: FIRECRAWL_API_KEY, JINA_API_KEY"
}

function test_api() {
    local API_URL="${1:-http://localhost:8000}"
    
    echo -e "${GREEN}Testing API endpoints at ${API_URL}...${NC}"
    
    # Test health
    echo -e "${YELLOW}Testing /health...${NC}"
    curl -s "${API_URL}/health" | python3 -m json.tool
    
    # Test extraction
    echo -e "${YELLOW}Testing /extract...${NC}"
    curl -s -X POST "${API_URL}/extract" \
        -H "Content-Type: application/json" \
        -d '{"content": "This is a test content for extraction."}' \
        | python3 -m json.tool
    
    echo -e "${GREEN}✓ API tests completed${NC}"
}

# Main script
print_header
check_requirements

case "${1}" in
    local)
        local_test
        ;;
    build)
        build_image
        ;;
    push)
        build_image
        push_image
        ;;
    test)
        test_api "${2}"
        ;;
    coolify)
        coolify_deploy
        ;;
    stop)
        echo -e "${YELLOW}Stopping services...${NC}"
        $COMPOSE_CMD down
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    logs)
        $COMPOSE_CMD logs -f
        ;;
    *)
        echo "Usage: $0 {local|build|push|test|coolify|stop|logs}"
        echo ""
        echo "Commands:"
        echo "  local    - Run locally with docker-compose"
        echo "  build    - Build production Docker image"
        echo "  push     - Build and push to registry"
        echo "  test     - Test API endpoints"
        echo "  coolify  - Show Coolify deployment instructions"
        echo "  stop     - Stop local services"
        echo "  logs     - View service logs"
        echo ""
        echo "Environment variables:"
        echo "  DOCKER_REGISTRY - Docker registry (default: docker.io)"
        echo "  DOCKER_REPO     - Repository name"
        echo "  VERSION         - Image tag (default: latest)"
        exit 1
        ;;
esac
