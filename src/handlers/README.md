# Task Handlers for AI Personal Assistant

This directory contains handlers for different task types in the AI Personal Assistant project. Each handler is responsible for processing a specific type of task identified by the task classifier.

## Architecture

The AI Personal Assistant uses a task classification architecture:

1. **Telegram Bot** receives messages from users
2. **Task Classifier** (n8n workflow) analyzes the message and determines the task type
3. **Task Handlers** (in this directory) process specific task types
4. **Response** is sent back to the user via Telegram

```
User Message → Telegram Bot → Task Classifier → Task Handler → Response
```

## Available Handlers

### Idea Handler

The `idea_handler.py` script handles the "idea" task type, saving ideas to a JSON file with metadata.

#### Features:
- Saves ideas with timestamp, tags, and source information
- Provides API endpoints to retrieve saved ideas
- Can be run as a standalone API server

#### Usage:

Run as a standalone API server:

```bash
python src/handlers/idea_handler.py --port 8080
```

API Endpoints:
- `POST /webhook/idea-handler`: Webhook endpoint for n8n to send idea tasks
- `GET /ideas`: Get all saved ideas
- `GET /ideas/{idea_id}`: Get a specific idea by ID
- `GET /health`: Health check endpoint

## Adding New Handlers

To add a new task handler:

1. Create a new Python script in this directory (e.g., `todo_handler.py`)
2. Implement the necessary logic to handle the task type
3. Provide a webhook endpoint for n8n to send tasks to
4. Update the task classifier workflow to route to the new handler

## Integration with n8n

The task handlers are designed to work with n8n workflows. The task classifier workflow sends tasks to the appropriate handler via HTTP requests to the webhook endpoints.

Example n8n workflow configuration:

```json
{
  "parameters": {
    "method": "POST",
    "url": "http://localhost:8080/webhook/idea-handler",
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "task_data",
          "value": "={{ $json }}"
        }
      ]
    }
  },
  "name": "Handle Idea",
  "type": "n8n-nodes-base.httpRequest"
}
```

## Environment Variables

- `IDEAS_FILE_PATH`: Path to the JSON file for storing ideas (default: `src/data/ideas.json`)

## Dependencies

- FastAPI
- Uvicorn
- Python-dotenv
- Pydantic 