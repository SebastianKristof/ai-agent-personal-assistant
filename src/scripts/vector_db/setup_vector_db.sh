#!/bin/bash

# Vector Database Setup Script
# This script helps set up the vector database API for the AI Personal Assistant

set -e

# Default values
DB_TYPE="chroma"
PORT=8001
ENV_FILE=".env"
INSTALL_DEPS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-type)
      DB_TYPE="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --install-deps)
      INSTALL_DEPS=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --db-type <type>    Database type (chroma or pinecone, default: chroma)"
      echo "  --port <port>       Port to run the API on (default: 8001)"
      echo "  --env-file <file>   Path to .env file (default: .env)"
      echo "  --install-deps      Install Python dependencies"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate database type
if [[ "$DB_TYPE" != "chroma" && "$DB_TYPE" != "pinecone" ]]; then
  echo "Error: Database type must be 'chroma' or 'pinecone'"
  exit 1
fi

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Creating $ENV_FILE file..."
  touch "$ENV_FILE"
fi

# Install dependencies if requested
if [[ "$INSTALL_DEPS" == true ]]; then
  echo "Installing Python dependencies..."
  pip install fastapi uvicorn python-dotenv openai
  
  if [[ "$DB_TYPE" == "chroma" ]]; then
    pip install chromadb
  elif [[ "$DB_TYPE" == "pinecone" ]]; then
    pip install pinecone-client
  fi
fi

# Update .env file with vector database settings
echo "Updating $ENV_FILE with vector database settings..."

# Check if VECTOR_DB_TYPE already exists in .env
if grep -q "^VECTOR_DB_TYPE=" "$ENV_FILE"; then
  # Update existing value
  sed -i.bak "s/^VECTOR_DB_TYPE=.*/VECTOR_DB_TYPE=$DB_TYPE/" "$ENV_FILE" && rm -f "$ENV_FILE.bak"
else
  # Add new value
  echo "VECTOR_DB_TYPE=$DB_TYPE" >> "$ENV_FILE"
fi

# Check if VECTOR_DB_API_PORT already exists in .env
if grep -q "^VECTOR_DB_API_PORT=" "$ENV_FILE"; then
  # Update existing value
  sed -i.bak "s/^VECTOR_DB_API_PORT=.*/VECTOR_DB_API_PORT=$PORT/" "$ENV_FILE" && rm -f "$ENV_FILE.bak"
else
  # Add new value
  echo "VECTOR_DB_API_PORT=$PORT" >> "$ENV_FILE"
fi

# Add database-specific settings
if [[ "$DB_TYPE" == "chroma" ]]; then
  # Check if CHROMA_DB_DIRECTORY already exists in .env
  if ! grep -q "^CHROMA_DB_DIRECTORY=" "$ENV_FILE"; then
    echo "CHROMA_DB_DIRECTORY=./data/chroma_db" >> "$ENV_FILE"
  fi
  
  # Create the directory for Chroma DB
  mkdir -p ./data/chroma_db
  
  echo "Chroma database settings added to $ENV_FILE"
  
elif [[ "$DB_TYPE" == "pinecone" ]]; then
  # Check if Pinecone API key is set
  if ! grep -q "^PINECONE_API_KEY=" "$ENV_FILE"; then
    read -p "Enter your Pinecone API key: " PINECONE_API_KEY
    echo "PINECONE_API_KEY=$PINECONE_API_KEY" >> "$ENV_FILE"
  fi
  
  # Check if Pinecone environment is set
  if ! grep -q "^PINECONE_ENVIRONMENT=" "$ENV_FILE"; then
    read -p "Enter your Pinecone environment (e.g., gcp-starter): " PINECONE_ENV
    echo "PINECONE_ENVIRONMENT=$PINECONE_ENV" >> "$ENV_FILE"
  fi
  
  # Check if Pinecone index name is set
  if ! grep -q "^PINECONE_INDEX_NAME=" "$ENV_FILE"; then
    read -p "Enter your Pinecone index name: " PINECONE_INDEX
    echo "PINECONE_INDEX_NAME=$PINECONE_INDEX" >> "$ENV_FILE"
  fi
  
  echo "Pinecone database settings added to $ENV_FILE"
fi

# Check if OpenAI API key is set
if ! grep -q "^OPENAI_API_KEY=" "$ENV_FILE"; then
  read -p "Enter your OpenAI API key: " OPENAI_API_KEY
  echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$ENV_FILE"
fi

echo ""
echo "Vector database setup complete!"
echo "Database type: $DB_TYPE"
echo "API port: $PORT"
echo ""
echo "To start the Vector Database API, run:"
echo "python src/api/vector_db_api.py"
echo ""
echo "To ingest data into the vector database, run:"
echo "python src/scripts/vector_db/ingest_data.py --input <input_file_or_directory>"
echo "" 