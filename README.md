# Secure AI Agent - Docker Environment with MCP Integration

A secure, isolated development environment that combines Amazon Q CLI with Perplexity AI search capabilities through Model Context Protocol (MCP) integration. Each project runs in its own Docker container with complete isolation and secure API key management.

## 🚀 Features

- **🔒 Complete Isolation**: Each project runs in its own Docker container with access only to its specific files
- **🔐 Secure Key Management**: API keys stored in macOS keychain and injected into containers as needed
- **🧠 AI-Powered Development**: Pre-installed Amazon Q CLI with auto-login support
- **🌐 Live Web Search**: Perplexity AI integration via MCP for current information and research
- **📋 Work Principles Integration**: Automatic setup of development standards and context
- **🛠️ Full Development Stack**: Python, Node.js, Git, and all standard development tools
- **⚡ Zero Setup**: Everything pre-configured - just create, register keys, and code

## 🎯 Quick Start

### Prerequisites

- Docker Desktop for Mac
- docker-compose
- envsubst (install with `brew install gettext`)

### Installation

```bash
cd secure-agent
./install.sh
```

This installs the `secure-agent` command to `~/.local/bin/` (no sudo required).

### Setup API Keys

Register your Perplexity API key:

```bash
# Register Perplexity API key in macOS keychain
secure-agent register-key perplexity "your-perplexity-api-key"
```

### Usage

```bash
# Create a new project environment
secure-agent create my-ai-project

# Activate the environment (drops directly into Q chat with auto-login)
secure-agent activate my-ai-project

# You're now in Q chat - start asking questions
"Search for the latest Python security best practices"
"What are the current trends in containerization?"

# To get a terminal without Q chat, use:
secure-agent terminal my-ai-project

# List all environments
secure-agent list

# Destroy environment (preserves project files)
secure-agent destroy my-ai-project
```

## 🔑 API Key Management

Secure-agent provides a secure way to manage API keys without exposing them in chat transcripts:

### Register Keys
```bash
# Store API keys in macOS keychain
secure-agent register-key perplexity "your-perplexity-api-key"
secure-agent register-key mapquest "your-mapquest-api-key"
secure-agent register-key geocoding "your-geocoding-api-key"
```

### Inject Keys into Containers
```bash
# Inject keys into running containers as needed
secure-agent inject-key mapquest my-project
secure-agent inject-key geocoding my-project

# Q CLI agent can now access keys without transcript exposure
"Get coordinates for downtown Nashville using MapQuest"
```

### Manage Keys
```bash
# List registered keys in macOS keychain
secure-agent list-keys

# List injected keys in a specific container
secure-agent list-keys my-project

# Remove keys from keychain
secure-agent remove-key mapquest
```

### How It Works
- Keys stored securely in macOS keychain (host-side encryption)
- Keys can be injected into a container keyring while the container is running
- MCP servers access keys via `keyring.get_password('service-api', 'default')`
- Keys never appear in Q CLI chat transcripts
- Each container has isolated keyring storage

## 🏗️ Architecture

### Container Components

```
Docker Container (833MB)
├── Amazon Q CLI (pre-installed, auto-login)
├── Perplexity MCP Server (custom implementation)
├── AWS CLI v2 (optional, via setup-aws command)
├── Python + development tools
├── Node.js + npm
├── Git + standard utilities
├── Container keyring for API keys
└── Pre-configured Q CLI profiles and context
```

### MCP Integration Flow

```
Q CLI (MCP Client)
├── Reads ~/.aws/amazonq/mcp.json (global config)
├── Reads .amazonq/mcp.json (workspace config)
├── Starts perplexity-server.py via stdio transport
├── Initializes JSON-RPC communication
├── Makes perplexity_search tool available
└── Handles user permission prompts for tool usage

Perplexity MCP Server
├── Retrieves API key from container keyring
├── Handles persistent stdin/stdout communication
├── Processes JSON-RPC requests (initialize, tools/list, tools/call)
├── Makes HTTPS calls to api.perplexity.ai
└── Returns formatted search results with citations
```

## 🔧 How It Works

### 1. Environment Creation
```bash
secure-agent create my-project
├── Creates ~/Documents/Source/my-project/ directory
├── Copies pre-configured Q CLI context files
├── Copies MCP configuration for Perplexity integration
├── Starts Docker container with pre-built image
├── Sets up container keyring with API keys
└── Ready for Q CLI authentication
```

### 2. Q CLI Integration
```bash
secure-agent activate my-project  # Drops directly into Q chat
├── ✓ perplexity-search loaded in ~0.6s
├── ✓ 1 of 1 mcp servers initialized
└── Ready for AI-powered development with web search
```

### 3. MCP Tool Usage
```bash
# After secure-agent activate, you're directly in Q chat
"Search for Docker security practices"
├── Q CLI recognizes search intent
├── Offers to use perplexity_search tool
├── User approves tool usage (y/n/t for trust)
├── MCP server queries Perplexity API
├── Returns current web search results with citations
└── Q CLI integrates results with response
```

## 🛡️ Security Model

- **🔒 Container Isolation**: Each project isolated from host system and other projects
- **🔐 Keyring Storage**: API keys stored in container keyring, never plaintext files
- **👤 User Permission**: Explicit approval required for external tool usage
- **🌐 Network Security**: Only HTTPS connections to authorized APIs
- **🔑 Authentication**: AWS Builder ID required for Q CLI access
- **📁 File Access**: Container only accesses specific project directory

## 🎯 Available Commands

### AWS CLI Setup
```bash
secure-agent setup-aws <project>         # Install AWS CLI v2 and import credentials
```

The `setup-aws` command:
- **Installs AWS CLI v2** using the official installer (not pip)
- **Imports credentials** automatically from your `~/.aws/credentials` file
- **Sets up environment variables** for seamless AWS CLI usage
- **Configures PATH** so `aws` commands work in the container

Prerequisites: Ensure you have AWS credentials configured on your host:
```bash
# On host system - configure your AWS credentials first
aws configure
# OR manually create ~/.aws/credentials with your keys
```

### Environment Management
```bash
secure-agent create <project>     # Create new environment or recreate existing
secure-agent attach <project>     # Add secure-agent to existing project (non-destructive)
secure-agent activate <project>   # Enter/start container environment (auto-login)
secure-agent terminal <project>   # Login to container, without starting a chat session
secure-agent list                 # List all environments by lifecycle state
secure-agent status <project>     # Show detailed environment status
secure-agent suspend <project>    # Stop container, preserve configuration
secure-agent destroy <project>    # Remove container, keep project files
```

### API Key Management
```bash
secure-agent register-key <service> <key>    # Store API key in macOS keychain
secure-agent inject-key <service> <project>  # Inject key into container keyring
secure-agent list-keys [project]             # List registered or injected keys
secure-agent remove-key <service>            # Remove key from macOS keychain
```

### Inside Container
```bash
# After secure-agent activate (drops into Q chat):
"message"                        # Chat with AI (includes MCP tools)
"search for X"                   # Triggers Perplexity search
/mcp                            # Show MCP server status in chat

# After secure-agent terminal (shell access):
q chat "message"                 # Start Q chat session
q doctor                        # Check Q CLI status
```

## 🧪 Testing

### AWS CLI Test
```bash
# Test AWS CLI setup (requires ~/.aws/credentials on host)
secure-agent create aws-test
secure-agent setup-aws aws-test
secure-agent terminal aws-test

# Inside container - test AWS CLI
aws --version                    # Should show: aws-cli/2.28.21
aws configure list              # Should show credentials from env
aws s3 ls                       # Should list your S3 buckets

exit
secure-agent destroy aws-test
```

### Basic Functionality Test
```bash
# Create and test environment
secure-agent create test-project
secure-agent activate test-project

# Inside container - test components
q --version                      # Should show: q 1.13.1
python3 --version               # Should show: Python 3.10.12

# Test API key access
secure-agent register-key test-api "test-key-12345"
secure-agent inject-key test-api test-project
secure-agent list-keys test-project

# Exit and cleanup
exit
secure-agent destroy test-project
```

### MCP Integration Test
```bash
secure-agent create mcp-test
secure-agent register-key perplexity "your-api-key"
secure-agent activate mcp-test

# Test MCP server loading (you're already in Q chat)
"Hello, what tools do you have?"
# Should show: ✓ perplexity-search loaded in ~0.6s

# Test Perplexity search
"Search for the latest AI developments"
# Should offer to use perplexity_search tool

exit
secure-agent destroy mcp-test
```

## 🛠️ Custom Q CLI Builds

The secure-agent supports using custom Q CLI builds for development:

```bash
# 1. Build your custom Q CLI for Linux x86_64
cd /path/to/amazon-q-cli
cargo build --release --target-dir target-optimized

# 2. Create symlink in secure-agent directory
cd secure-agent
mkdir -p custom-binaries
ln -s /path/to/amazon-q-cli/target-optimized/release/chat_cli custom-binaries/q-cli-x86_64-linux

# 3. Rebuild container image
./scripts/build-image.sh
```

## 🚨 Troubleshooting

### Container Won't Start
```bash
# Check Docker Desktop is running
docker ps

# Rebuild image if needed
./scripts/build-image.sh
```

### Q CLI Authentication Issues
```bash
# Inside container, check authentication
q doctor

# Re-authenticate if needed
q login
```

### MCP Server Issues
```bash
# Check API key access
python3 -c "import keyring; print(keyring.get_password('perplexity-api', 'default'))"

# Verify MCP configuration
cat ~/.aws/amazonq/mcp.json
```

### Keyring Issues
```bash
# On macOS host - verify API key is stored
security find-generic-password -s "perplexity-api" -w

# Inside container - test keyring access
python3 -c "import keyring; print('✓ Keyring accessible')"
```

## 🎉 Success Indicators

When everything is working correctly, you should see:

1. **Environment Creation**: `✓ Environment 'project-name' created successfully`
2. **Q CLI Auto-Login**: Automatic authentication on `activate`
3. **MCP Server Loading**: `✓ perplexity-search loaded in 0.6s`
4. **Tool Availability**: Q CLI offers to use `perplexity_search` for search queries
5. **API Integration**: Successful Perplexity API calls with formatted results and citations
6. **AWS CLI Setup**: `✓ AWS CLI v2 installed` and `aws s3 ls` works with your credentials

## 🚀 What's Next

This environment provides a complete AI-powered development setup with:
- ✅ Secure, isolated project environments
- ✅ Amazon Q CLI with auto-login support
- ✅ Live web search via Perplexity AI
- ✅ AWS CLI v2 with automatic credential import
- ✅ Pre-configured work principles and development standards
- ✅ Secure API key management
- ✅ Full development toolchain

Perfect for AI-assisted development, research, and secure coding projects!
