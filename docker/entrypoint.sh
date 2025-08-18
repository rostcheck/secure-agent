#!/bin/bash
# entrypoint.sh - Container initialization script

set -e

echo "Initializing secure AI agent environment..."

# Set up Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true

# Add local bin to PATH
export PATH="/home/aiuser/.local/bin:$PATH"

# Start D-Bus session bus (if available)
if command -v dbus-launch >/dev/null 2>&1; then
    echo "Starting D-Bus session..."
    export $(dbus-launch) 2>/dev/null || true
else
    echo "D-Bus not available, skipping..."
fi

# Start gnome-keyring daemon for secret storage (if available)
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    echo "Starting keyring daemon..."
    gnome-keyring-daemon --start --daemonize --components=secrets 2>/dev/null || true
else
    echo "Gnome keyring not available, skipping..."
fi

# Set up keyring backend
echo "Setting up keyring backend..."
python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
keyring.set_keyring(PlaintextKeyring())
print('✓ Keyring backend configured')
" 2>/dev/null || echo "Warning: Could not configure keyring backend"

# Initialize default keyring if possible
echo "Initializing keyring..."
python3 -c "
import keyring
try:
    keyring.set_password('init', 'test', 'test')
    keyring.delete_password('init', 'test')
    print('✓ Keyring initialized successfully')
except Exception as e:
    print(f'Warning: Keyring initialization failed: {e}')
" 2>/dev/null || echo "Warning: Could not initialize keyring"

# Check Q CLI installation
if command -v q >/dev/null 2>&1; then
    Q_VERSION=$(q --version 2>/dev/null || echo "unknown")
    echo "✓ Q CLI available: $(which q) ($Q_VERSION)"
else
    echo "⚠ Q CLI not found - installing now..."
    # Try to install Q CLI
    if curl -sSL https://q.aws.dev/install.sh | bash 2>/dev/null; then
        echo "✓ Q CLI installed successfully"
        # Reload PATH
        export PATH="/home/aiuser/.local/bin:$PATH"
    else
        echo "✗ Q CLI installation failed"
        echo "  You can install it manually inside the container with:"
        echo "  curl -sSL https://q.aws.dev/install.sh | bash"
        echo "  or check https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-command-line-install.html"
    fi
fi

# Check Homebrew installation
if command -v brew >/dev/null 2>&1; then
    echo "✓ Homebrew available: $(which brew)"
else
    echo "Warning: Homebrew not found in PATH"
fi

# Set up Q CLI environment
if [ -f ~/.config/q/current_context.md ]; then
    echo "✓ Q CLI configuration found"
else
    echo "Warning: Q CLI configuration not found at ~/.config/q/current_context.md"
fi

# Show mounted directories
echo ""
echo "Mounted directories:"
echo "  Workspace: /home/aiuser/workspace -> $(ls -la /home/aiuser/workspace 2>/dev/null | wc -l) items"
echo "  Q Config: /home/aiuser/.config/q -> $(ls -la /home/aiuser/.config/q 2>/dev/null | wc -l) items"
echo "  Keyring: /home/aiuser/.local/share/keyrings"

# Check for API keys in keyring
echo ""
echo "Checking stored credentials..."
python3 -c "
import keyring
try:
    # Check Perplexity API key
    key = keyring.get_password('perplexity-api', 'default')
    if key and len(key) > 0:
        print(f'✓ Perplexity API key available: {key[:8]}...{key[-4:]} (length: {len(key)})')
    else:
        print('Warning: Perplexity API key not found in keyring')
    
    # Check AWS Q login URL
    url = keyring.get_password('aws-q-login-url', 'default')
    if url and url.startswith('https://'):
        print(f'✓ AWS Q Professional license URL available: {url[:30]}...')
    else:
        print('Info: No AWS Q Professional license URL (will use Builder ID)')
        
except Exception as e:
    print(f'Warning: Could not check keyring: {e}')
" 2>/dev/null || echo "Warning: Could not check keyring status"

echo ""
echo "Environment initialization complete"
echo "Working directory: $(pwd)"
echo "Available commands: python, python3, node, npm, git, q, brew"
echo ""
echo "🚀 Q CLI Usage:"
echo "  q login  - Login to Q CLI (choose Builder ID or Professional)"
echo "  q chat   - Start Q chat (after login)"
echo "  q doctor - Check Q CLI status"
echo ""
echo "📁 Project files: ls /home/aiuser/workspace"
echo ""

# If no command specified, keep container running
if [ "$#" -eq 0 ]; then
    echo "Container ready. Use 'docker exec -it <container> /bin/bash' to enter."
    # Keep container alive
    tail -f /dev/null
else
    # Execute the provided command
    exec "$@"
fi
