# Vector Database Migration Guide

This guide provides detailed instructions for migrating from Chroma to Pinecone (or vice versa) in the AI Personal Assistant project.

## Overview

The project includes an abstraction layer that allows you to switch between Chroma and Pinecone with minimal changes to your n8n workflows. This guide explains how to:

1. Use the abstraction layer during development
2. Migrate your data when you're ready to switch databases
3. Update your configuration to use the new database

## Prerequisites

- Python 3.7+
- Required Python packages:
  - `fastapi`
  - `uvicorn`
  - `python-dotenv`
  - `requests`
  - `chromadb` (for Chroma)
  - `pinecone-client` (for Pinecone)
- n8n installed and configured
- Pinecone account (if migrating to Pinecone)

## Step 1: Understanding the Abstraction Layer

The abstraction layer consists of:

- **Vector Database API** (`src/scripts/vector_db/vector_db_api.py`): A FastAPI service that provides a consistent interface for both Chroma and Pinecone
- **Migration Script** (`src/scripts/vector_db/migrate.py`): A tool to export data from one database and import it to another
- **Startup Script** (`src/scripts/vector_db/start_api.sh`): A helper script to start the API with the desired database backend

The API provides these endpoints:

- `/embeddings/add`: Add embeddings to the database
- `/embeddings/query`: Query for similar embeddings
- `/embeddings/delete`: Delete embeddings
- `/embeddings/count`: Count embeddings in the database
- `/migration/export`: Export all data from the database
- `/migration/import`: Import data into the database
- `/health`: Check API health

## Step 2: Initial Setup with Chroma

### 2.1 Install Required Packages

```bash
pip install fastapi uvicorn python-dotenv requests chromadb
```

### 2.2 Configure Environment Variables

Create a `.env` file in your project root:

```
# Vector Database Configuration
VECTOR_DB_TYPE=chroma
CHROMA_HOST=localhost
CHROMA_PORT=8000
CHROMA_COLLECTION=assistant_collection
API_HOST=0.0.0.0
API_PORT=8001
```

### 2.3 Start the Vector Database API

```bash
./src/scripts/vector_db/start_api.sh
```

### 2.4 Configure n8n Workflows

In your n8n workflows, use HTTP Request nodes to interact with the API:

- To add embeddings:
  - Method: POST
  - URL: `http://localhost:8001/embeddings/add`
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

- To query embeddings:
  - Method: POST
  - URL: `http://localhost:8001/embeddings/query`
  - Body:
    ```json
    {
      "embedding": {{$json.embedding}},
      "n_results": 5
    }
    ```

## Step 3: Migrating to Pinecone

When you're ready to migrate from Chroma to Pinecone, follow these steps:

### 3.1 Set Up Pinecone

1. Sign up for a Pinecone account at [https://www.pinecone.io/](https://www.pinecone.io/)
2. Create a new project and index (see [Pinecone Setup Guide](pinecone_setup.md))
3. Install the Pinecone client:
   ```bash
   pip install pinecone-client
   ```

### 3.2 Update Environment Variables

Add Pinecone configuration to your `.env` file:

```
# Pinecone Configuration
PINECONE_API_KEY=your-api-key
PINECONE_ENVIRONMENT=your-environment
PINECONE_INDEX=your-index-name
```

### 3.3 Export Data from Chroma

You can export data from Chroma in two ways:

**Option 1: Using the Migration Script**

```bash
python src/scripts/vector_db/migrate.py --source chroma --target pinecone --output-file data_backup.json --dry-run
```

This will export data from Chroma and save it to `data_backup.json` without importing it to Pinecone yet.

**Option 2: Using the API Directly**

```bash
curl -X POST http://localhost:8001/migration/export > data_backup.json
```

### 3.4 Import Data to Pinecone

**Option 1: Using the Migration Script**

```bash
python src/scripts/vector_db/migrate.py --source chroma --target pinecone --input-file data_backup.json
```

**Option 2: Using the API**

First, update the environment variable to use Pinecone:

```bash
export VECTOR_DB_TYPE=pinecone
```

Then restart the API:

```bash
./src/scripts/vector_db/start_api.sh
```

Finally, import the data:

```bash
curl -X POST -H "Content-Type: application/json" -d @data_backup.json http://localhost:8001/migration/import
```

### 3.5 Verify the Migration

Check that the data was imported correctly:

```bash
# With Pinecone as the active database
curl http://localhost:8001/embeddings/count
```

### 3.6 Switch to Pinecone Permanently

Update your `.env` file to use Pinecone by default:

```
VECTOR_DB_TYPE=pinecone
```

Restart the API:

```bash
./src/scripts/vector_db/start_api.sh
```

## Step 4: Using the New Database

Your n8n workflows don't need to change! Since they interact with the abstraction layer API, they will continue to work with the new database.

## Troubleshooting

### API Connection Issues

If you can't connect to the API:

1. Check that the API is running:
   ```bash
   curl http://localhost:8001/health
   ```

2. Verify environment variables are set correctly:
   ```bash
   cat .env
   ```

### Migration Issues

If migration fails:

1. Check the error message for details
2. Verify Pinecone credentials are correct
3. Ensure the Pinecone index has the correct dimension for your embeddings
4. For large datasets, try migrating in smaller batches

### Database-Specific Issues

**Chroma:**
- Ensure Chroma server is running if using HTTP client
- Check persistence directory permissions

**Pinecone:**
- Verify API key and environment
- Check index name is correct
- Ensure vector dimensions match the index configuration

## Reverting to Chroma

If you need to revert to Chroma:

1. Update your `.env` file:
   ```
   VECTOR_DB_TYPE=chroma
   ```

2. Restart the API:
   ```bash
   ./src/scripts/vector_db/start_api.sh
   ```

3. If needed, migrate data back from Pinecone to Chroma:
   ```bash
   python src/scripts/vector_db/migrate.py --source pinecone --target chroma
   ```

## Best Practices

1. **Always Backup Data**: Before migration, always export data to a file
2. **Test in Development**: Test the migration in a development environment first
3. **Monitor Performance**: After migration, monitor query performance
4. **Update Documentation**: Document which database you're using
5. **Version Control**: Keep your abstraction layer and migration scripts under version control 