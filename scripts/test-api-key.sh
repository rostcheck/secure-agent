#!/bin/bash
# test-api-key.sh - Test API key retrieval in container

set -e

PROJECT_NAME="$1"
CONTAINER_NAME="secure-ai-$PROJECT_NAME"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

echo "Testing API key retrieval for project: $PROJECT_NAME"
echo "Container: $CONTAINER_NAME"
echo ""

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    echo "Start it with: secure-agent activate $PROJECT_NAME"
    exit 1
fi

echo "Testing keyring access..."
docker exec "$CONTAINER_NAME" python3 -c "
import keyring
import sys

print('Keyring backend:', keyring.get_keyring())
print()

try:
    # Try to get the Perplexity API key
    key = keyring.get_password('perplexity-api', 'default')
    if key and len(key) > 0:
        print(f'✓ Perplexity API key found!')
        print(f'  Key preview: {key[:8]}...{key[-4:]}')
        print(f'  Key length: {len(key)} characters')
        print(f'  Key type: {type(key)}')
    else:
        print('✗ Perplexity API key not found or empty')
        
    # List all stored keys
    print()
    print('Attempting to list all stored credentials...')
    # Note: This may not work with all keyring backends
    
except Exception as e:
    print(f'✗ Error accessing keyring: {e}')
    print(f'Error type: {type(e)}')
    sys.exit(1)
"

echo ""
echo "Testing Q CLI availability..."
docker exec "$CONTAINER_NAME" bash -c "
if command -v q >/dev/null 2>&1; then
    echo '✓ Q CLI found at: $(which q)'
    echo '  Version info:'
    q --version 2>/dev/null || echo '  Could not get version'
else
    echo '✗ Q CLI not found in PATH'
    echo '  PATH: $PATH'
fi
"

echo ""
echo "Testing qp alias..."
docker exec "$CONTAINER_NAME" bash -c "
source ~/.bashrc
if alias qp >/dev/null 2>&1; then
    echo '✓ qp alias is configured'
    echo '  Alias definition:'
    alias qp
else
    echo '✗ qp alias not found'
fi
"
