# AI Personal Assistant

A personal assistant AI agent built with n8n and vector database technology, accessible via Telegram.

## Overview

This project implements a personal assistant that can:
- Respond to text and voice messages via Telegram
- Use Retrieval-Augmented Generation (RAG) to provide personalized responses
- Automate tasks through n8n workflows
- Store and retrieve information using vector embeddings

## Project Structure

```
ai-agent-personal-assistant/
├── planning/           # Project planning documents
├── src/                # Source code
│   ├── workflows/      # n8n workflow JSON files
│   └── scripts/        # Helper scripts
├── docs/               # Documentation
└── tests/              # Test cases and testing utilities
```

## Prerequisites

- Node.js (v14 or later)
- npm or yarn
- Git
- Telegram account
- Vector database (to be selected)

## Setup

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd ai-agent-personal-assistant
   ```

2. Install n8n globally
   ```bash
   npm install n8n -g
   ```

3. Configure n8n
   ```bash
   mkdir -p ~/.n8n
   cp .env.example ~/.n8n/.env
   # Edit ~/.n8n/.env with your configuration
   ```

4. Start n8n
   ```bash
   n8n start
   ```

5. Import workflows
   - Open n8n UI at http://localhost:5678
   - Import workflows from src/workflows directory

## Development

See the [project plan](planning/project_plan.md) for detailed development stages and tasks.

## License

[MIT](LICENSE) 