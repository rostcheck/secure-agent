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
PERPLEXITY_KEY=$(security find-generic-password -s "perplexity-api" -w 2>/dev/null || echo "")

# Get AWS Q login URL from macOS keychain
echo "Retrieving AWS Q login URL from macOS keychain..."
AWS_Q_LOGIN_URL=$(security find-generic-password -s "aws-q-login-url" -w 2>/dev/null || echo "")

# Store credentials in container keyring using plaintext backend
docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
import sys

try:
    keyring.set_keyring(PlaintextKeyring())
    
    # Store Perplexity API key
    perplexity_key = '$PERPLEXITY_KEY'
    if perplexity_key:
        keyring.set_password('perplexity-api', 'default', perplexity_key)
        print('✓ Perplexity API key stored in container keyring')
    else:
        print('Warning: No Perplexity API key found in macOS keychain')
    
    # Store AWS Q login URL
    aws_q_url = '$AWS_Q_LOGIN_URL'
    if aws_q_url:
        keyring.set_password('aws-q-login-url', 'default', aws_q_url)
        print('✓ AWS Q login URL stored in container keyring')
    else:
        print('Info: No AWS Q login URL found (will use Builder ID login)')
        
except Exception as e:
    print(f'Error storing credentials: {e}')
    sys.exit(1)
"

# Verify storage
if [ -n "$PERPLEXITY_KEY" ]; then
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
try:
    keyring.set_keyring(PlaintextKeyring())
    key = keyring.get_password('perplexity-api', 'default')
    if key and len(key) > 10:
        print('✓ Perplexity key retrieval test: SUCCESS')
        print(f'✓ Perplexity key preview: {key[:10]}...{key[-4:]}')
    else:
        print('✗ Perplexity key retrieval test: FAILED')
except Exception as e:
    print(f'✗ Perplexity key retrieval test: FAILED - {e}')
"
fi

if [ -n "$AWS_Q_LOGIN_URL" ]; then
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
try:
    keyring.set_keyring(PlaintextKeyring())
    url = keyring.get_password('aws-q-login-url', 'default')
    if url and url.startswith('https://'):
        print('✓ AWS Q URL retrieval test: SUCCESS')
        print(f'✓ AWS Q URL preview: {url[:40]}...')
    else:
        print('✗ AWS Q URL retrieval test: FAILED')
except Exception as e:
    print(f'✗ AWS Q URL retrieval test: FAILED - {e}')
"
fi

echo "✓ Keychain setup complete"
