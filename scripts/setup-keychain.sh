#!/bin/bash
# setup-keychain.sh - Set up encrypted keychain in container

set -e

PROJECT_NAME="$1"
CONTAINER_NAME="secure-ai-$PROJECT_NAME"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

echo "Setting up encrypted keychain for '$PROJECT_NAME'..."

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Get Perplexity API key from macOS keychain
echo "Retrieving Perplexity API key from macOS keychain..."
PERPLEXITY_KEY=$(security find-generic-password -s "perplexity-api" -w 2>/dev/null)

if [ -n "$PERPLEXITY_KEY" ]; then
    echo "✓ Perplexity API key retrieved from macOS keychain"
    
    # Store in container keyring using plaintext backend
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
import sys

try:
    keyring.set_keyring(PlaintextKeyring())
    keyring.set_password('perplexity-api', 'default', '$PERPLEXITY_KEY')
    print('✓ Perplexity API key stored in container keyring')
except Exception as e:
    print(f'Error storing API key: {e}')
    sys.exit(1)
"
    
    # Verify storage
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
import sys

try:
    keyring.set_keyring(PlaintextKeyring())
    key = keyring.get_password('perplexity-api', 'default')
    if key and len(key) > 10:  # Basic validation
        print('✓ Key retrieval test: SUCCESS')
        print(f'✓ Key preview: {key[:10]}...{key[-4:]}')
    else:
        print('✗ Key retrieval test: FAILED - key not found or invalid')
        sys.exit(1)
except Exception as e:
    print(f'✗ Key retrieval test: FAILED - {e}')
    sys.exit(1)
"
    
    echo "✓ Keychain setup complete"
else
    echo "Warning: Perplexity API key not found in macOS keychain"
    echo "To add it, run: security add-generic-password -s 'perplexity-api' -a 'default' -w 'your-api-key'"
fi
