# Pinecone Setup Guide

This document provides detailed instructions for setting up Pinecone as the vector database for the AI Personal Assistant project.

## Overview

Pinecone is a managed vector database service that provides:
- Fast vector similarity search
- Scalable storage for embeddings
- Simple API for integration
- Metadata filtering capabilities

## Prerequisites

- Pinecone account (sign up at [https://www.pinecone.io/](https://www.pinecone.io/))
- API key with appropriate permissions
- n8n installed and configured

## Setup Steps

### 1. Create a Pinecone Account

1. Go to [https://www.pinecone.io/](https://www.pinecone.io/)
2. Click "Sign Up" or "Start Free"
3. Complete the registration process
4. Verify your email address

### 2. Create a Project

1. Log in to your Pinecone account
2. Click "Create Project"
3. Enter a project name (e.g., "ai-personal-assistant")
4. Select a cloud provider and region (choose one closest to your location)
5. Click "Create Project"

### 3. Create an Index

1. In your project, click "Create Index"
2. Enter an index name (e.g., "assistant-index")
3. Choose the dimensions for your vectors:
   - For OpenAI embeddings: 1536 dimensions
   - For other models: Check the output dimension of your embedding model
4. Select the metric type (usually "cosine" for text embeddings)
5. Choose the appropriate pod type (p1.x1 is sufficient for starting)
6. Click "Create Index"

### 4. Get Your API Key

1. Go to "API Keys" in your Pinecone dashboard
2. Copy your API key
3. Note your environment (e.g., "us-west1-gcp")

### 5. Configure Environment Variables

Add the following to your n8n environment file (`~/.n8n/.env`):

```
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENVIRONMENT=your-pinecone-environment
PINECONE_INDEX=your-index-name
```

### 6. Test the Connection

You can test the connection to Pinecone using a simple script or through n8n:

#### Using n8n:

1. Create a new workflow in n8n
2. Add an "HTTP Request" node
3. Configure it with:
   - Method: GET
   - URL: `https://{your-index-name}-{your-project-id}.svc.{your-environment}.pinecone.io/collections`
   - Headers:
     - Api-Key: `{{$env.PINECONE_API_KEY}}`
     - Accept: application/json
4. Run the node to test the connection

## Using Pinecone in n8n Workflows

### Creating Embeddings and Storing in Pinecone

1. Create a workflow with:
   - Trigger node (e.g., Telegram)
   - HTTP Request node to generate embeddings (e.g., using OpenAI API)
   - HTTP Request node to store in Pinecone:
     - Method: POST
     - URL: `https://{your-index-name}-{your-project-id}.svc.{your-environment}.pinecone.io/vectors/upsert`
     - Headers:
       - Api-Key: `{{$env.PINECONE_API_KEY}}`
       - Content-Type: application/json
     - Body:
       ```json
       {
         "vectors": [
           {
             "id": "{{$json.id}}",
             "values": {{$json.embedding}},
             "metadata": {
               "text": "{{$json.text}}",
               "source": "{{$json.source}}",
               "timestamp": "{{$now.toISOString()}}"
             }
           }
         ]
       }
       ```

### Querying Pinecone for Similar Vectors

1. Create a workflow with:
   - Trigger node
   - HTTP Request node to generate query embedding
   - HTTP Request node to query Pinecone:
     - Method: POST
     - URL: `https://{your-index-name}-{your-project-id}.svc.{your-environment}.pinecone.io/query`
     - Headers:
       - Api-Key: `{{$env.PINECONE_API_KEY}}`
       - Content-Type: application/json
     - Body:
       ```json
       {
         "vector": {{$json.embedding}},
         "topK": 5,
         "includeMetadata": true
       }
       ```

## Best Practices

1. **Batching**: When inserting multiple vectors, batch them in groups of 100-1000 for better performance
2. **Namespaces**: Use namespaces to organize different types of data
3. **Metadata**: Include useful metadata with your vectors for filtering and retrieval
4. **Index Size**: Monitor your index size to stay within your plan limits
5. **Error Handling**: Implement proper error handling in your workflows

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Verify your API key is correct
   - Check that you're using the correct environment

2. **Dimension Mismatch**:
   - Ensure your vectors match the dimension of your index

3. **Rate Limiting**:
   - Implement backoff strategies if you hit rate limits

4. **Index Not Ready**:
   - New indexes take a few minutes to initialize

## Resources

- [Pinecone Documentation](https://docs.pinecone.io/)
- [Pinecone API Reference](https://docs.pinecone.io/reference)
- [Pinecone Python Client](https://github.com/pinecone-io/pinecone-python-client)
- [OpenAI Embeddings Documentation](https://platform.openai.com/docs/guides/embeddings) 