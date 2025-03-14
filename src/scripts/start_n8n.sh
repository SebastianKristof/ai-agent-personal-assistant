#!/bin/bash
# start_n8n.sh
# Script to start n8n with recommended settings

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if n8n is installed
if ! command -v n8n &> /dev/null; then
  echo -e "${RED}Error: n8n is not installed.${NC}"
  echo -e "${YELLOW}Please install n8n:${NC}"
  echo -e "  npm install n8n -g"
  exit 1
fi

# Check if n8n is already running
if curl -s http://localhost:5678/healthz &> /dev/null; then
  echo -e "${YELLOW}n8n is already running.${NC}"
  exit 0
fi

# Start n8n with task runners enabled
echo -e "${GREEN}Starting n8n with task runners enabled...${NC}"
N8N_RUNNERS_ENABLED=true n8n start

# Check if n8n started successfully
if [ $? -eq 0 ]; then
  echo -e "${GREEN}n8n started successfully.${NC}"
else
  echo -e "${RED}Failed to start n8n.${NC}"
  exit 1
fi 