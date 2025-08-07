#!/bin/bash
# setup-q-auth.sh - Transfer Q CLI authentication to container

set -e

PROJECT_NAME="$1"
CONTAINER_NAME="secure-ai-$PROJECT_NAME"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    echo "This script transfers Q CLI authentication from host to container"
    exit 1
fi

echo "Setting up Q CLI authentication for '$PROJECT_NAME'..."

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    echo "Start it with: secure-agent activate $PROJECT_NAME"
    exit 1
fi

echo "Transferring Q CLI authentication files..."

# 1. Create necessary directories in container
docker exec "$CONTAINER_NAME" bash -c "
    mkdir -p /home/aiuser/.aws/amazonq
    mkdir -p /home/aiuser/Library/Application\ Support/amazon-q
    mkdir -p /home/aiuser/.aws
"

# 2. Copy AWS credentials and config
if [ -f ~/.aws/credentials ]; then
    echo "✓ Copying AWS credentials..."
    docker cp ~/.aws/credentials "$CONTAINER_NAME:/home/aiuser/.aws/"
else
    echo "⚠ No AWS credentials file found"
fi

if [ -f ~/.aws/config ]; then
    echo "✓ Copying AWS config..."
    docker cp ~/.aws/config "$CONTAINER_NAME:/home/aiuser/.aws/"
else
    echo "⚠ No AWS config file found"
fi

# 3. Copy Amazon Q CLI authentication data
if [ -d ~/.aws/amazonq ]; then
    echo "✓ Copying Amazon Q CLI data..."
    docker cp ~/.aws/amazonq/. "$CONTAINER_NAME:/home/aiuser/.aws/amazonq/"
else
    echo "⚠ No Amazon Q CLI data directory found"
fi

# 4. Copy Amazon Q application data (macOS specific)
if [ -d ~/Library/Application\ Support/amazon-q ]; then
    echo "✓ Copying Amazon Q application data..."
    docker cp ~/Library/Application\ Support/amazon-q/. "$CONTAINER_NAME:/home/aiuser/Library/Application Support/amazon-q/"
else
    echo "⚠ No Amazon Q application data found"
fi

# 5. Fix permissions in container
docker exec "$CONTAINER_NAME" bash -c "
    chown -R aiuser:aiuser /home/aiuser/.aws
    chown -R aiuser:aiuser /home/aiuser/Library 2>/dev/null || true
    chmod 600 /home/aiuser/.aws/credentials 2>/dev/null || true
    chmod 600 /home/aiuser/.aws/config 2>/dev/null || true
"

# 6. Test Q CLI authentication in container
echo ""
echo "Testing Q CLI authentication in container..."
if docker exec "$CONTAINER_NAME" bash -c "command -v q >/dev/null 2>&1"; then
    # Q CLI is installed, test it
    docker exec "$CONTAINER_NAME" bash -c "
        echo 'Q CLI version:'
        q --version 2>/dev/null || echo 'Version check failed'
        echo ''
        echo 'Q CLI settings:'
        q settings all 2>/dev/null || echo 'Settings check failed - may need interactive login'
    "
else
    echo "⚠ Q CLI not installed in container yet"
    echo "  Install it first with: ./scripts/install-q-cli.sh $PROJECT_NAME"
fi

echo ""
echo "✓ Q CLI authentication setup complete"
echo "Note: If Q CLI requires interactive login, you may need to:"
echo "  1. Activate the container: secure-agent activate $PROJECT_NAME"
echo "  2. Run: q auth login (if available)"
echo "  3. Or use the host Q CLI and sync files as needed"
