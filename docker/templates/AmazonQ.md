# Amazon Q Developer Instructions

## Project Context
This is a secure development environment with the following tools available:
- Python 3.10.12
- Node.js and npm
- Git version control
- Homebrew package manager
- All standard development utilities
- **Perplexity AI search** for current information and research

## Work Principles
Please read and follow the work principles from ~/.config/q/current_context.md:

### Collaborative Work Principles
- Always start with user journey mapping - what experience do we want?
- Maintain single source of truth for requirements
- Work backwards from desired user experience
- Apply security engineering best practices
- Store API keys and secrets in encrypted system storage, never plaintext

### Development Practices
- Test continuously - validate each piece immediately
- Evolve existing files rather than creating new ones
- Maintain a single source of truth
- Keep artifact count minimal and purposeful
- Before creating a new file, consider if modifying an existing file would be more appropriate

### Decision Framework
- Create decision log when deviating from best practices
- Explicitly define system architecture at project start
- Maintain consistency between documentation and implementation

## Available Tools
- File system operations (read, write, search)
- Bash command execution (with security restrictions)
- Code review and analysis
- AWS CLI operations (read-only by default)
- **Perplexity search** - Use this for current information, research, and up-to-date technical knowledge

## Perplexity Search Usage
When you need current information, recent developments, or research on topics, use the Perplexity search tool:
- For latest technology trends and updates
- For current best practices and documentation
- For troubleshooting recent issues
- For market research and competitive analysis

## Security Context
This environment is isolated from the host system for security. All development work should follow security best practices.
