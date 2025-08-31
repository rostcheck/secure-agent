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

# Create auto-login script
cat > /home/aiuser/auto-q-login.sh << 'EOF'
#!/bin/bash
# auto-q-login.sh - Automatic Q CLI login and chat startup

set -e

echo "🔐 Checking Q CLI authentication status..."

# Check if Q CLI is available
if ! command -v q >/dev/null 2>&1; then
    echo "❌ Q CLI not found. Please ensure Q CLI is installed."
    return 1
fi

# Check if already logged in using q whoami
if q whoami 2>&1 | grep -q "Not logged in"; then
    # Got "Not logged in" error, so we need to login
    echo "🔑 Not logged in, attempting automatic login..."
else
    # q whoami shows we're authenticated
    echo "✅ Already logged in to Q CLI"
    echo "🚀 Starting Q chat..."
    exec q chat
    return 0
fi

# Try to get AWS Q login URL from keyring
AWS_Q_URL=""
if command -v python3 >/dev/null 2>&1; then
    AWS_Q_URL=$(python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
try:
    keyring.set_keyring(PlaintextKeyring())
    url = keyring.get_password('aws-q-login-url', 'default')
    if url and url.startswith('https://'):
        print(url)
    else:
        print('')
except:
    print('')
" 2>/dev/null)
fi

if [ -n "$AWS_Q_URL" ]; then
    echo "🏢 Found Q Professional license URL"
    echo "📋 Identity Center URL: ${AWS_Q_URL:0:40}..."
    echo ""
    echo "⚠️  IMPORTANT: AWS Q Professional requires Identity Center authentication"
    echo "   Please complete authentication in your browser when prompted"
    echo ""
    echo "⏳ Starting Q login with professional license..."
    
    # Use yes command to automatically send empty lines (accept defaults)
    # The Q CLI will use the provided --identity-provider and --region as defaults
    if yes "" | q login --license pro --identity-provider "$AWS_Q_URL" --region us-east-1 --use-device-flow; then
        echo "✅ Q CLI login successful!"
        echo "🚀 Starting Q chat..."
        exec q chat
    else
        echo "❌ Q CLI professional login failed"
        echo ""
        echo "💡 This might be because:"
        echo "   • You're not logged into the AWS console"
        echo "   • The Identity Center URL is incorrect"
        echo "   • Network connectivity issues"
        echo ""
        echo "🔄 Falling back to Builder ID login..."
        if q login --license free; then
            echo "✅ Q CLI login successful with Builder ID!"
            echo "🚀 Starting Q chat..."
            exec q chat
        else
            echo "❌ All login attempts failed"
            echo "💡 You can try manual login with: q login"
            return 1
        fi
    fi
else
    echo "🔨 No professional license URL found, using Builder ID login"
    echo "⏳ Starting Q login..."
    
    if q login --license free; then
        echo "✅ Q CLI login successful!"
        echo "🚀 Starting Q chat..."
        exec q chat
    else
        echo "❌ Q CLI login failed"
        echo "💡 You can try manual login with: q login"
        return 1
    fi
fi
EOF

chmod +x /home/aiuser/auto-q-login.sh

# Add AWS credential auto-loading to .bashrc (if aws-creds exists)
if ! grep -q "aws-creds" /home/aiuser/.bashrc 2>/dev/null; then
    echo "" >> /home/aiuser/.bashrc
    echo "# Auto-load AWS credentials from keyring (if aws-creds exists)" >> /home/aiuser/.bashrc
    echo "[ -f ~/workspace/.secure-agent/bin/aws-creds ] && source ~/workspace/.secure-agent/bin/aws-creds 2>/dev/null || true" >> /home/aiuser/.bashrc
fi

# Add .secure-agent/bin to PATH if directory exists
if ! grep -q ".secure-agent/bin" /home/aiuser/.bashrc 2>/dev/null; then
    echo "" >> /home/aiuser/.bashrc
    echo "# Secure Agent Integration" >> /home/aiuser/.bashrc
    echo "if [ -d ~/workspace/.secure-agent/bin ]; then" >> /home/aiuser/.bashrc
    echo "    export PATH=\"~/workspace/.secure-agent/bin:\$PATH\"" >> /home/aiuser/.bashrc
    echo "fi" >> /home/aiuser/.bashrc
fi

echo ""
echo "Environment initialization complete"
echo "Working directory: $(pwd)"
echo "Available commands: python, python3, node, npm, git, q, brew"
echo ""
echo "🚀 Q CLI Auto-Login:"
echo "  • Auto-login will run when you enter an interactive shell"
echo "  • Uses Professional license if URL is configured"
echo "  • Falls back to Builder ID if needed"
echo "  • Manual login: q login"
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
