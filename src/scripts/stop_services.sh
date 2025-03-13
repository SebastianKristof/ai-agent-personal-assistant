#!/bin/bash

# Stop Services Script for AI Personal Assistant
# This script stops all the services started by start_services.sh

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to stop a service
stop_service() {
    local name=$1
    local pid_file="logs/$name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        
        echo -e "${YELLOW}Stopping $name (PID: $pid)...${NC}"
        
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo -e "${GREEN}$name stopped.${NC}"
        else
            echo -e "${YELLOW}$name is not running.${NC}"
        fi
        
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}$name is not running (no PID file found).${NC}"
    fi
}

# Check if logs directory exists
if [ ! -d "logs" ]; then
    echo -e "${YELLOW}No logs directory found. No services to stop.${NC}"
    exit 0
fi

# Stop all services
echo -e "${GREEN}Stopping all services...${NC}"
echo ""

# Stop n8n
stop_service "n8n"

# Stop vector database API
stop_service "vector_db_api"

# Stop idea handler
stop_service "idea_handler"

# Add more handlers here as they are implemented
# Example:
# stop_service "todo_handler"

echo ""
echo -e "${GREEN}All services stopped.${NC}" 