#!/bin/bash
# setup-q-config.sh - Set up Q CLI configuration with pre-created configs

set -e

PROJECT_NAME="$1"
CONTAINER_NAME="secure-ai-$PROJECT_NAME"

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name required"
    exit 1
fi

echo "Setting up Q CLI configuration for '$PROJECT_NAME'..."

# Check if Q CLI config is mounted from host
docker exec "$CONTAINER_NAME" bash -c "
if [ -d /home/aiuser/.config/q ]; then
    echo '✓ Q CLI config mounted from host'
    
    # Check for current context
    if [ -f /home/aiuser/.config/q/current_context.md ]; then
        echo '✓ Current context available'
    else
        echo 'Warning: current_context.md not found'
    fi
    
    # Check for persistent learnings
    if [ -f /home/aiuser/.config/q/persistent_learnings.md ]; then
        echo '✓ Persistent learnings available'
    else
        echo 'Warning: persistent_learnings.md not found'
    fi
    
    # Count context files
    CONTEXT_COUNT=\$(find /home/aiuser/.config/q/contexts -name '*.md' 2>/dev/null | wc -l)
    echo \"✓ \$CONTEXT_COUNT context files available\"
else
    echo 'Warning: Q CLI config directory not found in mounted config'
fi

# Set up writable AWS directory for Q CLI profiles (configs are pre-created)
if [ -d /home/aiuser/.aws-readonly ]; then
    echo 'Setting up writable AWS directory for Q CLI profiles...'
    cp -r /home/aiuser/.aws-readonly /home/aiuser/.aws
    chown -R aiuser:aiuser /home/aiuser/.aws
    echo '✓ Created writable AWS directory from read-only mount'
    
    # Verify pre-created configs
    if [ -f /home/aiuser/.aws/amazonq/agents/default.json ]; then
        echo '✓ Pre-created agent configuration found'
        # Check if MCP server is configured
        if grep -q 'perplexity-search' /home/aiuser/.aws/amazonq/agents/default.json; then
            echo '✓ Perplexity MCP server configured in agent'
        else
            echo 'Warning: Perplexity MCP server not found in agent config'
        fi
    else
        echo 'Warning: Agent configuration not found'
    fi
    
    if [ -f /home/aiuser/.aws/amazonq/profiles/default/context.json ]; then
        echo '✓ Pre-created profile context found'
    else
        echo 'Warning: Profile context not found'
    fi
else
    echo 'Warning: AWS readonly mount not found'
fi

# Verify pre-created project files
if [ -f /home/aiuser/workspace/AmazonQ.md ]; then
    echo '✓ Pre-created AmazonQ.md found'
else
    echo 'Warning: AmazonQ.md not found'
fi

if [ -f /home/aiuser/workspace/.amazonq/rules/project-setup.md ]; then
    echo '✓ Pre-created project rules found'
else
    echo 'Warning: Project rules not found'
fi

# Create a writable config overlay for container-specific settings
mkdir -p /home/aiuser/.config/q-local
echo '# Container-specific Q CLI settings with MCP' > /home/aiuser/.config/q-local/container_settings.md
echo '✓ Created writable config overlay at ~/.config/q-local'
"

echo "Q CLI configuration setup complete"
echo "✅ Features enabled:"
echo "   • Pre-installed Q CLI with authentication"
echo "   • Pre-created agent and profile configurations"
echo "   • Perplexity MCP server for web search"
echo "   • Project context and work principles"
echo "   • Secure API key storage via keyring"
