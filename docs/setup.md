# Setup Instructions

This document provides detailed setup instructions for the AI Personal Assistant project.

## Prerequisites

- Git
- Node.js v18.17.0 (recommended), v20, or v22 (n8n is not compatible with Node.js v23+)
- npm or yarn
- Telegram account
- Vector database (Chroma or Pinecone recommended)

## Node.js Setup

n8n requires a specific Node.js version. If you have a newer version (like v23+), you'll need to use a version manager like nvm:

```bash
# Install nvm (if not already installed)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load nvm in your shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install the recommended Node.js version
nvm install 18.17.0

# Use the installed version
nvm use 18.17.0

# Verify the version
node -v  # Should output v18.17.0
```

## n8n Installation

```bash
# Install n8n globally
npm install n8n -g

# Verify installation
n8n --version
```

## n8n Configuration

1. Create the n8n configuration directory:
   ```bash
   mkdir -p ~/.n8n
   ```

2. Create a .env file for n8n:
   ```bash
   cp .env.example ~/.n8n/.env
   ```

3. Generate a random encryption key:
   ```bash
   openssl rand -hex 24
   ```

4. Update the encryption key in the .env file:
   ```bash
   # Edit ~/.n8n/.env and replace the value for N8N_ENCRYPTION_KEY
   ```

5. Start n8n:
   ```bash
   n8n start
   ```

6. Access the n8n UI at http://localhost:5678

## Telegram Bot Setup

Follow the instructions in [telegram_bot_setup.md](../planning/telegram_bot_setup.md) to create and configure your Telegram bot.

## Vector Database Setup

Based on our [vector database comparison](../planning/vector_database_comparison.md), we recommend two options:

### Option 1: Chroma (Local Development)

Chroma is ideal for local development and testing. Setup instructions for Chroma will be added in a separate document.

### Option 2: Pinecone (Production/Scaling)

Pinecone is a managed service that's excellent for production use:

1. Sign up for a Pinecone account at [https://www.pinecone.io/](https://www.pinecone.io/)
2. Create a new project and get your API key
3. Create an index with the appropriate dimensions for your embeddings
4. Update your environment variables with the Pinecone credentials:
   ```
   PINECONE_API_KEY=your-pinecone-api-key
   PINECONE_ENVIRONMENT=your-pinecone-environment
   PINECONE_INDEX=your-pinecone-index
   ```

Detailed setup instructions for both options will be provided in separate documents.

## Next Steps

After completing the setup:

1. Create your first n8n workflow
2. Test the Telegram bot integration
3. Set up your chosen vector database
4. Develop your first RAG workflow 