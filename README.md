# Secure AI Agent - Docker Environment with MCP Integration

A secure, isolated development environment that combines Amazon Q CLI with Perplexity AI search capabilities through Model Context Protocol (MCP) integration. Each project runs in its own Docker container with complete isolation and secure API key management.

## 🚀 Features

- **🔒 Complete Isolation**: Each project runs in its own Docker container with access only to its specific files
- **🔐 Keyring Security**: Encrypted keyring storage for API keys with persistent container volumes
- **🧠 AI-Powered Development**: Pre-installed Amazon Q CLI v1.13.1 with authentication support
- **🌐 Live Web Search**: Perplexity AI integration via MCP for current information and research
- **📋 Work Principles Integration**: Automatic setup of development standards and context
- **🛠️ Full Development Stack**: Python 3.10.12, Node.js, Git, and all standard development tools
- **⚡ Zero Setup**: Everything pre-configured - just create, authenticate, and code

## 🎯 Quick Start

### Prerequisites

- Docker Desktop for Mac
- docker-compose
- envsubst (install with `brew install gettext`)
- Perplexity API key stored in macOS keychain

### Installation

```bash
cd secure-agent
./install.sh
```

This installs the `secure-agent` command to `~/.local/bin/` (no sudo required).

### Setup API Key

Store your Perplexity API key in macOS keychain:

```bash
# Add Perplexity API key to keychain
security add-generic-password -s "perplexity-api" -a "default" -w "your-perplexity-api-key"
```

### Usage

```bash
# Create a new project environment (everything pre-configured)
secure-agent create my-ai-project

# Activate the environment
secure-agent activate my-ai-project

# Inside container - authenticate Q CLI
q login

# Start using Q CLI with Perplexity search
q chat "Search for the latest Python security best practices"
q chat "What are the current trends in containerization?"

# List all environments
secure-agent list

# Destroy environment (preserves project files)
secure-agent destroy my-ai-project
```

## 🏗️ Architecture

### Container Components

```
Docker Container (833MB)
├── Amazon Q CLI v1.13.1 (pre-installed)
├── Perplexity MCP Server (custom implementation)
├── Python 3.10.12 + development tools
├── Node.js + npm
├── Git + standard utilities
├── Encrypted keyring for API keys
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
├── Retrieves API key from encrypted keyring
├── Handles persistent stdin/stdout communication
├── Processes JSON-RPC requests (initialize, tools/list, tools/call)
├── Makes HTTPS calls to api.perplexity.ai
└── Returns formatted search results with citations
```

### File Structure

```
Host System:
~/Documents/Source/my-project/
├── AmazonQ.md                    # Work principles and project context
├── .amazonq/
│   ├── mcp.json                  # MCP server configuration
│   └── rules/
│       └── project-setup.md     # Development standards
└── README.md                     # Project documentation

Container:
├── ~/.aws/amazonq/
│   ├── agents/default.json      # Clean agent configuration
│   ├── mcp.json                 # Global MCP configuration
│   └── profiles/default/context.json  # Profile with workspace paths
├── /opt/mcp-servers/
│   └── perplexity-server.py     # MCP server implementation
└── /home/aiuser/workspace/      # Mounted project directory
```

## 🔧 How It Works

### 1. Environment Creation
```bash
secure-agent create my-project
├── Creates ~/Documents/Source/my-project/ directory
├── Copies pre-configured Q CLI context files
├── Copies MCP configuration for Perplexity integration
├── Starts Docker container with pre-built image
├── Sets up encrypted keyring with API keys
└── Ready for Q CLI authentication
```

### 2. Q CLI Integration
```bash
q login  # Authenticate with AWS Builder ID
q chat   # Automatically loads MCP servers
├── ✓ perplexity-search loaded in ~0.6s
├── ✓ 1 of 1 mcp servers initialized
└── Ready for AI-powered development with web search
```

### 3. MCP Tool Usage
```bash
q chat "Search for Docker security practices"
├── Q CLI recognizes search intent
├── Offers to use perplexity_search tool
├── User approves tool usage (y/n/t for trust)
├── MCP server queries Perplexity API
├── Returns current web search results with citations
└── Q CLI integrates results with response
```

## 🛡️ Security Model

- **🔒 Container Isolation**: Each project isolated from host system and other projects
- **🔐 Encrypted Storage**: API keys stored in encrypted keyring, never plaintext
- **👤 User Permission**: Explicit approval required for external tool usage
- **🌐 Network Security**: Only HTTPS connections to authorized APIs
- **🔑 Authentication**: AWS Builder ID required for Q CLI access
- **📁 File Access**: Container only accesses specific project directory

## 🎯 Available Commands

### Environment Management
```bash
secure-agent create <project>     # Create new environment or recreate existing
secure-agent attach <project>     # Add secure-agent to existing project (non-destructive)
secure-agent prepare <project>    # Create compose file for recreatable project (RECREATABLE → CONFIGURED)
secure-agent activate <project>   # Enter/start container environment (auto-prepares if needed)
secure-agent list                 # List all environments by lifecycle state
secure-agent status <project>     # Show detailed environment status
secure-agent suspend <project>    # Stop container, preserve configuration
secure-agent destroy <project>    # Remove container, keep project files
```

### Attach Existing Projects

The `attach` command brings existing software projects into the secure-agent ecosystem:

```bash
# Attach any existing project
secure-agent attach my-existing-project

# What it does:
# ✅ Analyzes project structure and detects features
# ✅ Adds .amazonq/ directory with AI configuration
# ✅ Installs Q CLI context and MCP setup
# ✅ Creates Docker container environment
# ✅ Preserves ALL original project files (non-destructive)

# Then activate and use
secure-agent activate my-existing-project
# Inside container: q login && q chat
```

**Attach Features:**
- 🔍 **Smart Detection** - Recognizes Python, Node.js, Rust, Go, Java projects
- 🛡️ **Non-Destructive** - Never modifies existing files
- 🤖 **AI Context** - Auto-generates project-specific context for Q CLI
- ⚡ **Instant Setup** - Full AI development environment in ~60 seconds

### Environment Lifecycle States

The secure-agent tracks environments through their complete lifecycle:

- **🟢 ACTIVE** - Container running and ready to use
  - Actions: `activate` (enter), `suspend` (stop), `destroy` (remove)

- **🟡 SUSPENDED** - Container exists but stopped
  - Actions: `activate` (start), `destroy` (remove)

- **🔵 CONFIGURED** - Compose file exists, ready to create container
  - Actions: `activate` (create & start), `create` (recreate)

- **🔵 RECREATABLE** - Project files available, can recreate environment
  - Actions: `create` (setup environment)

- **⚪ NOT FOUND** - No environment or project files exist
  - Actions: `create` (setup new environment)

### Lifecycle-Aware Listing

```bash
secure-agent list
```

Shows environments grouped by state:
```
🟢 ACTIVE ENVIRONMENTS (with containers):
   Project              Status                    Created
   -------              ------                    -------
   my-active-project    Up 2 hours               2025-08-18 10:30:15

🟡 SUSPENDED ENVIRONMENTS (containers stopped):
   Project              Status                    Created
   -------              ------                    -------
   my-suspended-proj    Exited (0) 1 hour ago    2025-08-18 09:15:22

🔵 RECREATABLE ENVIRONMENTS (project files available):
   Project              Last Modified             .amazonq Config
   -------              -------------             ---------------
   old-project          2025-08-15 14:30          ✅ Present
   archived-work        2025-08-10 09:45          ✅ Present
```

### Detailed Environment Status

```bash
secure-agent status <project>
```

Provides comprehensive environment information:
```
Environment Status: my-project
=================================

📁 PROJECT DIRECTORY:
   Location: ~/Documents/Source/my-project
   Status: ✅ Present
   Last Modified: 2025-08-18 10:30:15
   .amazonq Config: ✅ Present (secure-agent project)
   MCP Config: ✅ Present
   Contents: 15 items
   Size: 2.3M

🐳 DOCKER ENVIRONMENT:
   Container: ✅ Present (secure-ai-my-project)
   Status: Up 2 hours
   Created: 2025-08-18 08:15:30
   Image: secure-ai-agent:latest
   State: 🟢 Running
   Resource Usage:
   CPU: 0.5%  Memory: 256MB / 2GB  Network: 1.2kB / 856B

⚙️  CONFIGURATION:
   Compose File: ✅ Present
   Location: ~/.secure-agent/docker-compose-my-project.yml
   Size: 1.8K

🎯 ENVIRONMENT STATE:
   Status: 🟢 ACTIVE - Container running and ready
   Actions: activate (enter), suspend (stop), destroy (remove)
```

### Inside Container
```bash
q login                          # Authenticate Q CLI
q chat "message"                 # Chat with AI (includes MCP tools)
q chat "search for X"           # Triggers Perplexity search
q doctor                        # Check Q CLI status
/mcp                            # Show MCP server status in chat
```

## 🧪 Testing

### Basic Functionality Test
```bash
# Create and test environment
secure-agent create test-project
secure-agent activate test-project

# Inside container - test components
q --version                      # Should show: q 1.13.1
python3 --version               # Should show: Python 3.10.12
python3 -c "import keyring; print('✓ Keyring works')"

# Test API key access
python3 -c "import keyring; key = keyring.get_password('perplexity-api', 'default'); print(f'✓ API key: {key[:8]}...{key[-4:]}')"

# Exit and cleanup
exit
secure-agent destroy test-project
```

### MCP Integration Test
```bash
secure-agent create mcp-test
secure-agent activate mcp-test

# Authenticate Q CLI
q login

# Test MCP server loading
q chat "Hello, what tools do you have?"
# Should show: ✓ perplexity-search loaded in ~0.6s

# Test Perplexity search
q chat "Search for the latest AI developments"
# Should offer to use perplexity_search tool

exit
secure-agent destroy mcp-test
```

## 🔧 Project Structure

```
secure-agent/
├── secure-agent                 # Main CLI script
├── install.sh                  # Installation script
├── README.md                   # This file
├── docker/
│   ├── Dockerfile              # Container image with Q CLI + MCP
│   ├── entrypoint.sh           # Container initialization
│   ├── docker-compose.yml.template
│   ├── mcp-servers/
│   │   └── perplexity-server.py  # MCP server implementation
│   └── templates/
│       ├── AmazonQ.md          # Work principles template
│       ├── project-setup.md    # Development standards
│       ├── default-agent.json  # Clean agent configuration
│       ├── context.json        # Profile context template
│       ├── mcp.json           # Global MCP configuration
│       └── workspace-mcp.json  # Workspace MCP configuration
└── scripts/
    ├── build-image.sh          # Docker image builder
    ├── setup-q-config.sh       # Q CLI configuration setup
    └── setup-keychain.sh       # Encrypted keyring setup
```

## 🚨 Troubleshooting

### Container Won't Start
```bash
# Check Docker Desktop is running
docker ps

# Rebuild image if needed
./scripts/build-image.sh

# Check logs
docker logs secure-ai-project-name
```

### Q CLI Authentication Issues
```bash
# Inside container, check authentication
q doctor

# Re-authenticate if needed
q login

# Check if MCP servers load
q chat "test" # Should show MCP server initialization
```

### MCP Server Issues
```bash
# Test MCP server directly
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}' | python3 /opt/mcp-servers/perplexity-server.py

# Check API key access
python3 -c "import keyring; print(keyring.get_password('perplexity-api', 'default'))"

# Verify MCP configuration
cat ~/.aws/amazonq/mcp.json
cat /home/aiuser/workspace/.amazonq/mcp.json
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
2. **Q CLI Authentication**: `Device authorized` and `Logged in successfully`
3. **MCP Server Loading**: `✓ perplexity-search loaded in 0.6s`
4. **Tool Availability**: Q CLI offers to use `perplexity_search` for search queries
5. **API Integration**: Successful Perplexity API calls with formatted results and citations

## 🚀 What's Next

This environment provides a complete AI-powered development setup with:
- ✅ Secure, isolated project environments
- ✅ Amazon Q CLI with professional license support
- ✅ Live web search via Perplexity AI
- ✅ Pre-configured work principles and development standards
- ✅ Encrypted API key management
- ✅ Full development toolchain

Perfect for AI-assisted development, research, and secure coding projects!
