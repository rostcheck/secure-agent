#!/bin/bash
# build-image.sh - Build Docker image with logging and custom Q CLI support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker"
DOCKER_IMAGE="secure-ai-agent:latest"
LOG_FILE="/tmp/secure-agent-build.log"

# Check for custom Q CLI binary
CUSTOM_Q_CLI="$PROJECT_ROOT/custom-q-cli"
USE_CUSTOM_Q=false

if [[ -L "$CUSTOM_Q_CLI" ]] && [[ -f "$CUSTOM_Q_CLI" ]]; then
    # Verify it's a Linux x86_64 binary
    BINARY_INFO=$(file "$CUSTOM_Q_CLI")
    if [[ "$BINARY_INFO" == *"ELF 64-bit"* ]] && [[ "$BINARY_INFO" == *"x86-64"* ]]; then
        USE_CUSTOM_Q=true
        CUSTOM_Q_SIZE=$(ls -lh "$CUSTOM_Q_CLI" | awk '{print $5}')
        echo "✓ Custom Q CLI binary detected: $CUSTOM_Q_SIZE"
        echo "  Binary: $(readlink -f "$CUSTOM_Q_CLI")"
        echo "  Architecture: x86_64 Linux (compatible)"
    else
        echo "⚠ Custom Q CLI binary found but incompatible architecture"
        echo "  Expected: ELF 64-bit x86-64"
        echo "  Found: $BINARY_INFO"
        echo "  Falling back to default Q CLI installation"
    fi
else
    echo "ℹ No custom Q CLI binary found, using default installation"
fi

echo ""
echo "Building secure AI agent Docker image..."
echo "Custom Q CLI: $([ "$USE_CUSTOM_Q" = true ] && echo "✓ Enabled" || echo "✗ Disabled")"
echo "Build log: $LOG_FILE"

# Clear previous log
> "$LOG_FILE"

# Prepare build context
cd "$DOCKER_DIR"

# Copy custom binary to build context if available
if [[ "$USE_CUSTOM_Q" = true ]]; then
    echo "Copying custom Q CLI binary to build context..."
    cp "$CUSTOM_Q_CLI" ./custom-q-cli
    echo "✓ Custom binary ready for container build"
fi

# Build with output redirected to log and x86_64 platform for Q CLI compatibility
echo "Starting Docker build..."
BUILD_ARGS=""
if [[ "$USE_CUSTOM_Q" = true ]]; then
    BUILD_ARGS="--build-arg USE_CUSTOM_Q=true"
fi

if docker build --platform linux/amd64 $BUILD_ARGS -t "$DOCKER_IMAGE" . >> "$LOG_FILE" 2>&1; then
    echo "✓ Docker image built successfully"
    echo "Image: $DOCKER_IMAGE (linux/amd64)"
    if [[ "$USE_CUSTOM_Q" = true ]]; then
        echo "✓ Custom Q CLI binary integrated"
    fi
else
    echo "✗ Docker build failed"
    echo "Check build log: $LOG_FILE"
    echo ""
    echo "Last 20 lines of build log:"
    tail -20 "$LOG_FILE"
    
    # Clean up custom binary from build context
    if [[ "$USE_CUSTOM_Q" = true ]] && [[ -f ./custom-q-cli ]]; then
        rm ./custom-q-cli
    fi
    
    exit 1
fi

# Clean up custom binary from build context
if [[ "$USE_CUSTOM_Q" = true ]] && [[ -f ./custom-q-cli ]]; then
    rm ./custom-q-cli
    echo "✓ Build context cleaned up"
fi

# Show image info
echo ""
echo "Image details:"
docker images "$DOCKER_IMAGE" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Show Q CLI version that will be used
echo ""
echo "Q CLI version check:"
if docker run --rm --platform linux/amd64 "$DOCKER_IMAGE" q --version 2>/dev/null; then
    echo "✓ Q CLI is working in container"
else
    echo "⚠ Could not verify Q CLI version (this is normal if Q CLI requires initialization)"
fi
