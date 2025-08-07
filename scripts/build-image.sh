#!/bin/bash
# build-image.sh - Build Docker image with logging

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")/docker"
DOCKER_IMAGE="secure-ai-agent:latest"
LOG_FILE="/tmp/secure-agent-build.log"

echo "Building secure AI agent Docker image..."
echo "Build log: $LOG_FILE"

# Clear previous log
> "$LOG_FILE"

# Build with output redirected to log and x86_64 platform for Q CLI compatibility
cd "$DOCKER_DIR"
if docker build --platform linux/amd64 -t "$DOCKER_IMAGE" . >> "$LOG_FILE" 2>&1; then
    echo "✓ Docker image built successfully"
    echo "Image: $DOCKER_IMAGE (linux/amd64)"
else
    echo "✗ Docker build failed"
    echo "Check build log: $LOG_FILE"
    echo ""
    echo "Last 20 lines of build log:"
    tail -20 "$LOG_FILE"
    exit 1
fi

# Show image info
echo ""
echo "Image details:"
docker images "$DOCKER_IMAGE" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
