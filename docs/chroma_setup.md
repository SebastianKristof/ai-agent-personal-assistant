# Chroma Setup Guide

This document provides detailed instructions for setting up Chroma as the vector database for the AI Personal Assistant project.

## Overview

Chroma is an open-source embedding database designed for AI applications that provides:
- Simple Python API for vector storage and retrieval
- Local deployment option
- Metadata filtering
- Integration with popular embedding models
- Free for self-hosted use

## Prerequisites

- Python 3.7+ installed
- pip (Python package manager)
- n8n installed and configured
- Basic knowledge of Python (for integration)

## Setup Steps

### 1. Install Chroma

You can install Chroma using pip:

```bash
pip install chromadb
```

For a more isolated environment, consider using a virtual environment:

```bash
# Create a virtual environment
python -m venv chroma-env

# Activate the virtual environment
# On macOS/Linux:
source chroma-env/bin/activate
# On Windows:
# chroma-env\Scripts\activate

# Install Chroma
pip install chromadb
```

### 2. Create a Simple Chroma Server

For better integration with n8n, it's recommended to run Chroma as a server. Create a file named `chroma_server.py`:

```python
import chromadb
from chromadb.config import Settings
import uvicorn
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set up the server
chroma_client = chromadb.Client(Settings(
    chroma_server_host="localhost",
    chroma_server_http_port=8000,
    persist_directory="./chroma_data"  # Data will be stored in this directory
))

# Create a collection for the assistant
collection = chroma_client.get_or_create_collection(
    name="assistant_collection",
    metadata={"hnsw:space": "cosine"}  # Use cosine similarity
)

# Start the server
if __name__ == "__main__":
    uvicorn.run(
        "chromadb.server.fastapi:app",
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
```

Install the additional required packages:

```bash
pip install uvicorn python-dotenv
```

### 3. Run the Chroma Server

Start the Chroma server:

```bash
python chroma_server.py
```

The server will be available at `http://localhost:8000`.

### 4. Create a Python Client for n8n Integration

Since n8n doesn't have a direct Chroma integration, we'll create a simple Python API that n8n can call. Create a file named `chroma_api.py`:

```python
from fastapi import FastAPI, HTTPException, Body
import chromadb
from chromadb.config import Settings
import uvicorn
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import uuid

app = FastAPI(title="Chroma API for n8n")

# Connect to Chroma
client = chromadb.HttpClient(host="localhost", port=8000)
collection = client.get_or_create_collection("assistant_collection")

# Define data models
class EmbeddingData(BaseModel):
    text: str
    embedding: List[float]
    metadata: Optional[Dict[str, Any]] = None
    id: Optional[str] = None

class QueryData(BaseModel):
    embedding: List[float]
    n_results: int = 5
    where: Optional[Dict[str, Any]] = None

# API endpoints
@app.post("/add")
async def add_embedding(data: EmbeddingData):
    try:
        # Generate ID if not provided
        if not data.id:
            data.id = str(uuid.uuid4())
        
        # Add to collection
        collection.add(
            embeddings=[data.embedding],
            documents=[data.text],
            metadatas=[data.metadata or {}],
            ids=[data.id]
        )
        return {"status": "success", "id": data.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query")
async def query_embeddings(data: QueryData):
    try:
        results = collection.query(
            query_embeddings=[data.embedding],
            n_results=data.n_results,
            where=data.where
        )
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    try:
        # Simple health check
        collection.count()
        return {"status": "healthy"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

Install FastAPI:

```bash
pip install fastapi
```

### 5. Run the API Server

Start the API server:

```bash
python chroma_api.py
```

The API will be available at `http://localhost:8001`.

### 6. Configure Environment Variables

Create a `.env` file in the same directory as your Python scripts:

```
CHROMA_HOST=localhost
CHROMA_PORT=8000
API_HOST=localhost
API_PORT=8001
```

### 7. Create a Startup Script

For convenience, create a `start_chroma.sh` script:

```bash
#!/bin/bash
# Start Chroma server and API
python chroma_server.py &
sleep 5  # Wait for Chroma server to start
python chroma_api.py
```

Make it executable:

```bash
chmod +x start_chroma.sh
```

## Using Chroma in n8n Workflows

### Adding Embeddings to Chroma

1. Create a workflow with:
   - Trigger node (e.g., Telegram)
   - HTTP Request node to generate embeddings (e.g., using OpenAI API)
   - HTTP Request node to store in Chroma:
     - Method: POST
     - URL: `http://localhost:8001/add`
     - Headers:
       - Content-Type: application/json
     - Body:
       ```json
       {
         "text": "{{$json.text}}",
         "embedding": {{$json.embedding}},
         "metadata": {
           "source": "{{$json.source}}",
           "timestamp": "{{$now.toISOString()}}"
         }
       }
       ```

### Querying Chroma for Similar Vectors

1. Create a workflow with:
   - Trigger node
   - HTTP Request node to generate query embedding
   - HTTP Request node to query Chroma:
     - Method: POST
     - URL: `http://localhost:8001/query`
     - Headers:
       - Content-Type: application/json
     - Body:
       ```json
       {
         "embedding": {{$json.embedding}},
         "n_results": 5
       }
       ```

## Best Practices

1. **Persistence**: Ensure the `persist_directory` is on a reliable storage medium
2. **Backups**: Regularly backup your Chroma data directory
3. **Metadata**: Use metadata for filtering and organization
4. **Error Handling**: Implement proper error handling in your workflows
5. **Security**: If exposing the API externally, add authentication

## Troubleshooting

### Common Issues

1. **Connection Errors**:
   - Verify both servers are running
   - Check the ports are not blocked by a firewall

2. **Embedding Format**:
   - Ensure embeddings are properly formatted as arrays of floats

3. **Performance Issues**:
   - Consider using a more powerful machine for larger collections
   - Optimize query parameters

## Resources

- [Chroma Documentation](https://docs.trychroma.com/)
- [Chroma GitHub Repository](https://github.com/chroma-core/chroma)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [OpenAI Embeddings Documentation](https://platform.openai.com/docs/guides/embeddings) 