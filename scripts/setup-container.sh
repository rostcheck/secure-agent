#!/bin/bash
# setup-container.sh - Consolidated container initialization

set -e

PROJECT_NAME="$1"
CONTAINER_NAME="secure-ai-$PROJECT_NAME"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

echo "Setting up container for '$PROJECT_NAME'..."

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    exit 1
fi

# 1. Initialize keyring system
echo "Initializing keyring system..."
docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
try:
    keyring.set_keyring(PlaintextKeyring())
    keyring.set_password('init', 'test', 'test')
    keyring.delete_password('init', 'test')
    print('✓ Keyring system initialized')
except Exception as e:
    print(f'Error initializing keyring: {e}')
    exit(1)
"

# 2. Inject registered API keys from host keychain
echo "Injecting API keys from host keychain..."

# Perplexity API key
PERPLEXITY_KEY=$(security find-generic-password -s "perplexity-api" -w 2>/dev/null || echo "")
if [ -n "$PERPLEXITY_KEY" ]; then
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
keyring.set_keyring(PlaintextKeyring())
keyring.set_password('perplexity-api', 'default', '$PERPLEXITY_KEY')
print('✓ Perplexity API key injected')
"
else
    echo "Info: No Perplexity API key found in host keychain"
fi

# AWS Q login URL
AWS_Q_URL=$(security find-generic-password -s "aws-q-login-url" -w 2>/dev/null || echo "")
if [ -n "$AWS_Q_URL" ]; then
    docker exec "$CONTAINER_NAME" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
keyring.set_keyring(PlaintextKeyring())
keyring.set_password('aws-q-login-url', 'default', '$AWS_Q_URL')
print('✓ AWS Q login URL injected')
"
else
    echo "Info: No AWS Q login URL found (will use Builder ID)"
fi

# 3. Setup .secure-agent directory structure
echo "Setting up .secure-agent directory structure..."
docker exec "$CONTAINER_NAME" bash -c "
mkdir -p /home/aiuser/workspace/.secure-agent/{bin,config,tools}
echo '# Secure Agent Directory' > /home/aiuser/workspace/.secure-agent/README.md
echo 'This directory contains all secure-agent tooling and configurations.' >> /home/aiuser/workspace/.secure-agent/README.md
echo '' >> /home/aiuser/workspace/.secure-agent/README.md
echo 'Structure:' >> /home/aiuser/workspace/.secure-agent/README.md
echo '- bin/     - Scripts and executables' >> /home/aiuser/workspace/.secure-agent/README.md
echo '- config/  - Configuration files' >> /home/aiuser/workspace/.secure-agent/README.md
echo '- tools/   - Installed tools and packages' >> /home/aiuser/workspace/.secure-agent/README.md
echo '✓ .secure-agent directory structure created'
"

# 4. Create MCP configuration
echo "Creating MCP configuration..."
docker exec "$CONTAINER_NAME" bash -c "
cat > /home/aiuser/workspace/.secure-agent/config/mcp.json << 'EOF'
{
  \"mcpServers\": {
    \"perplexity-search\": {
      \"command\": \"python3\",
      \"args\": [\"/opt/mcp-servers/perplexity-server.py\"],
      \"env\": {
        \"PERPLEXITY_API_KEY_KEYRING_SERVICE\": \"perplexity-api\",
        \"PERPLEXITY_API_KEY_KEYRING_USERNAME\": \"default\"
      },
      \"timeout\": 30000
    }
  }
}
EOF
echo '✓ MCP configuration created'
"

# 5. Configure shell integration
echo "Configuring shell integration..."
docker exec "$CONTAINER_NAME" bash -c "
# Add .secure-agent/bin to PATH if not already present
if ! grep -q '.secure-agent/bin' ~/.bashrc 2>/dev/null; then
    echo '' >> ~/.bashrc
    echo '# Secure Agent Integration' >> ~/.bashrc
    echo 'if [ -d ~/workspace/.secure-agent/bin ]; then' >> ~/.bashrc
    echo '    export PATH=\"~/workspace/.secure-agent/bin:\$PATH\"' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
    echo '✓ Added .secure-agent/bin to PATH'
else
    echo '✓ .secure-agent/bin already in PATH'
fi
"

echo "✓ Container setup complete for '$PROJECT_NAME'"
echo ""
echo "Available features:"
echo "  • Keyring system initialized"
echo "  • API keys injected from host keychain"
echo "  • .secure-agent directory structure ready"
echo "  • MCP configuration for Perplexity search"
echo "  • Shell integration configured"
echo ""
echo "Next steps:"
echo "  secure-agent setup-aws $PROJECT_NAME    # Setup AWS tools"
echo "  secure-agent activate $PROJECT_NAME     # Enter container"
