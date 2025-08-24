#!/bin/bash
# install-symlink.sh - Install secure-agent CLI using symlinks (cleaner approach)

set -e

INSTALL_DIR="$HOME/.local/bin"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SOURCE_DIR/secure-agent"

echo "Installing Secure AI Agent CLI (symlink approach)..."

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

# Remove existing installation (copy or symlink)
if [[ -f "$INSTALL_DIR/secure-agent" ]] || [[ -L "$INSTALL_DIR/secure-agent" ]]; then
    echo "Removing existing secure-agent installation..."
    rm "$INSTALL_DIR/secure-agent"
fi

# Remove old ~/.secure-agent directory if it exists (from copy-based install)
if [[ -d "$HOME/.secure-agent" ]]; then
    echo "Removing old ~/.secure-agent directory (copy-based install)..."
    rm -rf "$HOME/.secure-agent"
fi

# Create symlink to source script
echo "Creating symlink: $INSTALL_DIR/secure-agent -> $SOURCE_SCRIPT"
ln -s "$SOURCE_SCRIPT" "$INSTALL_DIR/secure-agent"

echo "✓ Installation complete (symlink approach)"
echo ""
echo "The secure-agent command is symlinked to: $SOURCE_SCRIPT"
echo "✓ Always uses latest version from source directory"
echo "✓ No sync issues between installed and development versions"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✓ ~/.local/bin is already in your PATH"
else
    echo "⚠️  ~/.local/bin is not in your PATH"
    echo "Add this to your ~/.bash_profile or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "⚠️  IMPORTANT: Keep the source directory at:"
echo "    $SOURCE_DIR"
echo "    Moving or deleting it will break the symlink."

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
