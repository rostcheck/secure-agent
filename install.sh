#!/bin/bash
# install.sh - Install secure-agent CLI without sudo

set -e

INSTALL_DIR="$HOME/.local/bin"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Secure AI Agent CLI..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed"
    echo "Please install docker-compose or use Docker Desktop which includes it"
    exit 1
fi

# Check if envsubst is available
if ! command -v envsubst &> /dev/null; then
    echo "Installing envsubst..."
    if command -v brew &> /dev/null; then
        brew install gettext
    else
        echo "Error: envsubst not found. Please install gettext package"
        exit 1
    fi
fi

# Create ~/.local/bin if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy secure-agent to user's local bin (no sudo needed)
echo "Installing secure-agent command to ~/.local/bin..."
cp "$SOURCE_DIR/secure-agent" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/secure-agent"

# Create ~/.secure-agent directory for configuration
mkdir -p "$HOME/.secure-agent"
cp -r "$SOURCE_DIR/docker" "$HOME/.secure-agent/"
cp -r "$SOURCE_DIR/scripts" "$HOME/.secure-agent/"

# Update paths in the installed script
sed -i '' "s|SCRIPT_DIR=\".*\"|SCRIPT_DIR=\"$HOME/.secure-agent\"|" "$INSTALL_DIR/secure-agent"

echo "✓ Installation complete"
echo ""
echo "The secure-agent command is installed to: $INSTALL_DIR/secure-agent"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✓ ~/.local/bin is already in your PATH"
else
    echo "⚠️  ~/.local/bin is not in your PATH"
    echo "Add this to your ~/.bash_profile or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "Usage:"
echo "  secure-agent create <project-name>    # Create new environment"
echo "  secure-agent activate <project-name>  # Enter environment"
echo "  secure-agent list                     # List environments"
echo "  secure-agent --help                   # Show help"
echo ""
echo "Example:"
echo "  secure-agent create my-ai-project"
echo "  secure-agent activate my-ai-project"
