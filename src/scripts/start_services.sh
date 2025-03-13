#!/bin/bash

# Start Services Script for AI Personal Assistant
# This script starts all the necessary services for the AI Personal Assistant

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
START_N8N=true
START_VECTOR_DB=true
START_HANDLERS=true
VECTOR_DB_PORT=8001
HANDLERS_PORT=8080

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-n8n)
      START_N8N=false
      shift
      ;;
    --no-vector-db)
      START_VECTOR_DB=false
      shift
      ;;
    --no-handlers)
      START_HANDLERS=false
      shift
      ;;
    --vector-db-port)
      VECTOR_DB_PORT="$2"
      shift 2
      ;;
    --handlers-port)
      HANDLERS_PORT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --no-n8n             Don't start n8n"
      echo "  --no-vector-db       Don't start the vector database API"
      echo "  --no-handlers        Don't start the task handlers"
      echo "  --vector-db-port     Port for the vector database API (default: 8001)"
      echo "  --handlers-port      Port for the task handlers (default: 8080)"
      echo "  --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file not found. Some services may not work correctly.${NC}"
    echo "Creating empty .env file..."
    touch .env
fi

# Function to start a service in the background
start_service() {
    local name=$1
    local command=$2
    local log_file=$3
    
    echo -e "${GREEN}Starting $name...${NC}"
    echo "Command: $command"
    echo "Logs: $log_file"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Start the service in the background
    eval "$command" > "$log_file" 2>&1 &
    
    # Save the PID
    local pid=$!
    echo "$pid" > "logs/$name.pid"
    
    echo -e "${GREEN}$name started with PID $pid${NC}"
    echo ""
}

# Create logs directory
mkdir -p logs

# Start n8n
if [ "$START_N8N" = true ]; then
    if command -v n8n &> /dev/null; then
        start_service "n8n" "n8n start" "logs/n8n.log"
    else
        echo -e "${RED}Error: n8n not found. Please install n8n first.${NC}"
        echo "You can install n8n with: npm install -g n8n"
        exit 1
    fi
fi

# Start vector database API
if [ "$START_VECTOR_DB" = true ]; then
    if [ -f "src/api/vector_db_api.py" ]; then
        start_service "vector_db_api" "python src/api/vector_db_api.py --port $VECTOR_DB_PORT" "logs/vector_db_api.log"
    else
        echo -e "${RED}Error: Vector database API not found.${NC}"
        echo "Please make sure src/api/vector_db_api.py exists."
        exit 1
    fi
fi

# Start task handlers
if [ "$START_HANDLERS" = true ]; then
    # Check if idea handler exists
    if [ -f "src/handlers/idea_handler.py" ]; then
        start_service "idea_handler" "python src/handlers/idea_handler.py --port $HANDLERS_PORT" "logs/idea_handler.log"
    else
        echo -e "${YELLOW}Warning: Idea handler not found. Skipping.${NC}"
    fi
    
    # Add more handlers here as they are implemented
    # Example:
    # if [ -f "src/handlers/todo_handler.py" ]; then
    #     start_service "todo_handler" "python src/handlers/todo_handler.py --port $((HANDLERS_PORT + 1))" "logs/todo_handler.log"
    # fi
fi

echo -e "${GREEN}All services started!${NC}"
echo ""
echo "To view logs:"
echo "  n8n: tail -f logs/n8n.log"
echo "  Vector DB API: tail -f logs/vector_db_api.log"
echo "  Idea Handler: tail -f logs/idea_handler.log"
echo ""
echo "To stop services:"
echo "  Kill n8n: kill \$(cat logs/n8n.pid)"
echo "  Kill Vector DB API: kill \$(cat logs/vector_db_api.pid)"
echo "  Kill Idea Handler: kill \$(cat logs/idea_handler.pid)"
echo ""
echo "Or use: ./src/scripts/stop_services.sh" 