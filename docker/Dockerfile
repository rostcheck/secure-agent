# Dockerfile for secure AI agent environment
FROM ubuntu:22.04

# Build argument for custom Q CLI binary
ARG USE_CUSTOM_Q=false

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and common development tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    vim \
    joe \
    rsync \
    gnupg \
    dbus \
    gnome-keyring \
    python3-secretstorage \
    python3-keyring \
    python3-keyrings.alt \
    build-essential \
    wget \
    unzip \
    ca-certificates \
    ca-certificates \
    software-properties-common \
    sudo \
    file \
    procps \
    libfuse2 \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install Q CLI - either custom binary or official package
RUN if [ "$USE_CUSTOM_Q" = "true" ]; then \
        echo "Preparing for custom Q CLI binary installation..."; \
        echo "Custom Q CLI will be installed from build context after user creation"; \
    else \
        echo "Installing Q CLI via official Debian package..."; \
        # Download Q CLI package \
        curl --proto '=https' --tlsv1.2 -sSf https://desktop-release.q.us-east-1.amazonaws.com/latest/amazon-q.deb -o /tmp/amazon-q.deb && \
        # Install GUI dependencies required by Q CLI \
        apt-get update && \
        apt-get install -y \
            libgtk-3-0 \
            libwebkit2gtk-4.1-0 \
            libayatana-appindicator3-1 \
        && \
        # Install Q CLI \
        apt-get install -y /tmp/amazon-q.deb && \
        # Clean up \
        rm /tmp/amazon-q.deb && \
        apt-get clean && rm -rf /var/lib/apt/lists/* && \
        echo "Q CLI official installation complete"; \
    fi

# Install Python packages for MCP server
RUN pip3 install --no-cache-dir httpx keyring

# Create MCP servers directory and copy Perplexity MCP server
RUN mkdir -p /opt/mcp-servers
COPY mcp-servers/perplexity-server.py /opt/mcp-servers/
RUN chmod +x /opt/mcp-servers/perplexity-server.py

# Pre-create Q CLI configuration structure
RUN mkdir -p /home/aiuser/.aws/amazonq/agents \
    /home/aiuser/.aws/amazonq/profiles/default

# Create default agent configuration (clean, no mcpServers)
COPY templates/default-agent.json /home/aiuser/.aws/amazonq/agents/default.json

# Create MCP server configuration files
COPY templates/mcp.json /home/aiuser/.aws/amazonq/mcp.json
RUN mkdir -p /home/aiuser/workspace/.amazonq
COPY templates/workspace-mcp.json /home/aiuser/workspace/.amazonq/mcp.json

# Create default profile context
COPY templates/context.json /home/aiuser/.aws/amazonq/profiles/default/context.json

# Create default project context files
COPY templates/AmazonQ.md /home/aiuser/workspace/AmazonQ.md
RUN mkdir -p /home/aiuser/workspace/.amazonq/rules
COPY templates/project-setup.md /home/aiuser/workspace/.amazonq/rules/project-setup.md

# Create python alias
RUN ln -s /usr/bin/python3 /usr/bin/python

# Create non-root user and add to sudo group for package installation autonomy
RUN useradd -m -s /bin/bash -u 1000 aiuser && \
    echo "aiuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up directories with proper ownership
RUN mkdir -p /home/aiuser/workspace \
    /home/aiuser/.config/q \
    /home/aiuser/.local/share/keyrings \
    /home/aiuser/.cache \
    /home/aiuser/.local/bin \
    /home/aiuser/.aws/amazonq \
    /home/aiuser/Library/Application\ Support/amazon-q \
    /home/aiuser/.amazonq/rules \
    && chown -R aiuser:aiuser /home/aiuser

# Install custom Q CLI binary if provided
COPY custom-q-cli* /tmp/
RUN if [ "$USE_CUSTOM_Q" = "true" ] && [ -f /tmp/custom-q-cli ]; then \
        echo "Installing custom Q CLI binary..."; \
        cp /tmp/custom-q-cli /usr/bin/q && \
        chmod +x /usr/bin/q && \
        rm /tmp/custom-q-cli && \
        echo "✓ Custom Q CLI binary installed to /usr/bin/q"; \
        # Verify the binary \
        file /usr/bin/q && \
        ls -lh /usr/bin/q; \
    elif [ "$USE_CUSTOM_Q" = "true" ]; then \
        echo "⚠ Custom Q CLI requested but binary not found in build context"; \
        exit 1; \
    fi

# Switch to non-root user
USER aiuser
WORKDIR /home/aiuser

# Install Homebrew as non-root user
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set up Homebrew environment
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
RUN echo 'export PATH="/home/aiuser/.local/bin:$PATH"' >> ~/.bashrc

# Source Homebrew environment for this build
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Create aliases and auto-login setup
RUN echo 'alias python=python3' >> ~/.bashrc

# Add auto-login logic to both bashrc and bash_profile for login shells
RUN echo '' >> ~/.bashrc && \
    echo '# Auto Q CLI login for interactive sessions' >> ~/.bashrc && \
    echo 'if [[ $- == *i* ]] && [[ -t 0 ]] && [[ -z "$AUTO_LOGIN_DONE" ]]; then' >> ~/.bashrc && \
    echo '    export AUTO_LOGIN_DONE=1' >> ~/.bashrc && \
    echo '    if [[ -f /home/aiuser/auto-q-login.sh ]]; then' >> ~/.bashrc && \
    echo '        echo "🚀 Starting automatic Q CLI login..."' >> ~/.bashrc && \
    echo '        /home/aiuser/auto-q-login.sh' >> ~/.bashrc && \
    echo '    fi' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc

# Also add to .bash_profile for login shells (used by secure-agent activate)
RUN echo '# Source bashrc for login shells' >> ~/.bash_profile && \
    echo 'if [ -f ~/.bashrc ]; then' >> ~/.bash_profile && \
    echo '    source ~/.bashrc' >> ~/.bash_profile && \
    echo 'fi' >> ~/.bash_profile

# Note: Q CLI installation method depends on USE_CUSTOM_Q build arg

# Copy entry point script
COPY --chown=aiuser:aiuser entrypoint.sh /home/aiuser/
RUN chmod +x /home/aiuser/entrypoint.sh

ENTRYPOINT ["/home/aiuser/entrypoint.sh"]
CMD ["/bin/bash"]
