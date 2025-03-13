# Vector Database Data Ingestion

This directory contains scripts for managing data in the vector database used by the AI Personal Assistant.

## Data Ingestion Script

The `ingest_data.py` script helps you ingest data into the vector database (Chroma or Pinecone) through the vector database abstraction layer API.

### Prerequisites

Before using the script, make sure:

1. The Vector Database API is running (see `src/api/vector_db_api.py`)
2. You have set the `OPENAI_API_KEY` environment variable
3. Python dependencies are installed:
   ```
   pip install requests python-dotenv
   ```

### Usage

Basic usage:

```bash
python src/scripts/vector_db/ingest_data.py --input <input_file_or_directory>
```

#### Options

- `--input`: Input file or directory to ingest (JSON, TXT, or directory of TXT files) [required]
- `--api-url`: URL of the Vector Database API (default: http://localhost:8001)
- `--batch-size`: Batch size for processing items (default: 10)
- `--chunk-size`: Size of text chunks in characters (default: 1000)
- `--chunk-overlap`: Overlap between chunks in characters (default: 200)
- `--embedding-model`: OpenAI embedding model to use (default: text-embedding-3-small)
- `--dry-run`: Process data but don't store in the database

### Examples

Ingest a single JSON file:

```bash
python src/scripts/vector_db/ingest_data.py --input src/data/sample_knowledge.json
```

Ingest a directory of text files:

```bash
python src/scripts/vector_db/ingest_data.py --input src/data/documents/
```

Dry run to test processing without storing:

```bash
python src/scripts/vector_db/ingest_data.py --input src/data/sample_knowledge.json --dry-run
```

Use custom chunk size and overlap:

```bash
python src/scripts/vector_db/ingest_data.py --input src/data/sample_knowledge.json --chunk-size 500 --chunk-overlap 100
```

### Supported File Formats

#### JSON

The script supports several JSON formats:

1. Array of objects with `text` and optional `metadata` fields:
   ```json
   [
     {
       "text": "Content to embed",
       "metadata": { "source": "example", "category": "documentation" }
     }
   ]
   ```

2. Object with `items` array:
   ```json
   {
     "items": [
       {
         "text": "Content to embed",
         "metadata": { "source": "example" }
       }
     ]
   }
   ```

3. Single object with `text` field:
   ```json
   {
     "text": "Content to embed",
     "metadata": { "source": "example" }
   }
   ```

#### Text Files

Plain text files (`.txt`) are supported and will be chunked according to the specified chunk size and overlap.

### Metadata

The script automatically adds the following metadata to each chunk:

- `source`: The file path
- `chunk`: The chunk number (1-indexed)
- `total_chunks`: Total number of chunks for the original text
- Any additional metadata from the JSON file (if available)

This metadata can be used for filtering when querying the vector database. 