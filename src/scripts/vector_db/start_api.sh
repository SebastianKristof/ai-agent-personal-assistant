#!/bin/bash
# Start the Vector Database API

# Default values
DB_TYPE=${VECTOR_DB_TYPE:-chroma}
API_HOST=${API_HOST:-0.0.0.0}
API_PORT=${API_PORT:-8001}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-type)
      DB_TYPE="$2"
      shift 2
      ;;
    --host)
      API_HOST="$2"
      shift 2
      ;;
    --port)
      API_PORT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --db-type TYPE   Set the database type (chroma or pinecone, default: $DB_TYPE)"
      echo "  --host HOST      Set the API host (default: $API_HOST)"
      echo "  --port PORT      Set the API port (default: $API_PORT)"
      echo "  --help           Show this help message"
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
  echo "Error: Invalid database type '$DB_TYPE'. Must be 'chroma' or 'pinecone'."
  exit 1
fi

# Export environment variables
export VECTOR_DB_TYPE=$DB_TYPE
export API_HOST=$API_HOST
export API_PORT=$API_PORT

echo "Starting Vector Database API with $DB_TYPE backend on $API_HOST:$API_PORT"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
  echo "Error: Python 3 is not installed or not in PATH"
  exit 1
fi

# Check for required Python packages
REQUIRED_PACKAGES="fastapi uvicorn python-dotenv"
if [[ "$DB_TYPE" == "chroma" ]]; then
  REQUIRED_PACKAGES="$REQUIRED_PACKAGES chromadb"
elif [[ "$DB_TYPE" == "pinecone" ]]; then
  REQUIRED_PACKAGES="$REQUIRED_PACKAGES pinecone-client"
fi

for package in $REQUIRED_PACKAGES; do
  if ! python3 -c "import $package" &> /dev/null; then
    echo "Warning: Python package '$package' is not installed"
    echo "You may need to install it with: pip install $package"
  fi
done

# Start the API
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/vector_db_api.py" 