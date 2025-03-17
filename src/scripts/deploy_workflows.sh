#!/bin/bash
# deploy_workflows.sh
# Script to deploy all n8n workflows from JSON files using REST API
# This will overwrite existing workflows with the same IDs

# Set variables
N8N_URL="http://localhost:5678"
WORKFLOWS_DIR="$(dirname "$(dirname "$(realpath "$0")")")/workflows"
AUTO_CONFIRM=false
API_KEY=""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse command line arguments
parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -y|--yes) AUTO_CONFIRM=true ;;
      -h|--help) show_help; exit 0 ;;
      -k|--api-key) API_KEY="$2"; shift ;;
      *) echo "Unknown parameter: $1"; show_help; exit 1 ;;
    esac
    shift
  done
}

# Show help
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -y, --yes       Automatically confirm overwriting workflows"
  echo "  -k, --api-key   API key for n8n authentication (optional)"
  echo "  -h, --help      Show this help message"
}

# Function to check dependencies
check_dependencies() {
  echo -e "${YELLOW}Checking dependencies...${NC}"
  
  # Check for curl
  if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}Please install curl:${NC}"
    echo -e "  brew install curl (macOS) or apt-get install curl (Linux)"
    return 1
  fi
  
  # Check for jq
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}Please install jq:${NC}"
    echo -e "  brew install jq (macOS) or apt-get install jq (Linux)"
    return 1
  fi
  
  echo -e "${GREEN}All dependencies are installed.${NC}"
  return 0
}

# Function to check if n8n is running
check_n8n_running() {
  echo -e "${YELLOW}Checking if n8n is running...${NC}"
  if curl -s "$N8N_URL/healthz" > /dev/null; then
    echo -e "${GREEN}n8n is running.${NC}"
    return 0
  else
    echo -e "${RED}n8n is not running. Please start n8n first.${NC}"
    echo -e "${YELLOW}You can start n8n with: n8n start${NC}"
    return 1
  fi
}

# Function to get confirmation
get_confirmation() {
  if [ "$AUTO_CONFIRM" = true ]; then
    echo -e "${YELLOW}Auto-confirming deployment (--yes flag provided)${NC}"
    return 0
  fi
  
  echo -e "${YELLOW}WARNING: This will overwrite any existing workflows with the same IDs in n8n.${NC}"
  echo -e "${YELLOW}Do you want to continue? (y/N)${NC}"
  
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 0
  else
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    return 1
  fi
}

# Function to prepare auth headers
get_auth_headers() {
  local headers=""
  
  if [ -n "$API_KEY" ]; then
    headers="-H \"X-N8N-API-KEY: $API_KEY\""
  fi
  
  echo "$headers"
}

# Function to import a workflow using REST API
import_workflow() {
  local file=$1
  local filename=$(basename "$file")
  local workflow_name=$(jq -r '.name' "$file")
  local workflow_id=$(jq -r '.id' "$file")
  local auth_headers=$(get_auth_headers)
  
  echo -e "${YELLOW}Importing workflow: ${workflow_name}${NC}"
  echo -e "${YELLOW}File: ${filename}${NC}"
  
  # Check if workflow exists
  local check_cmd="curl -s $auth_headers \"$N8N_URL/rest/workflows?filter=$workflow_id\""
  local check_result=$(eval "$check_cmd")
  
  # Check for authentication error
  if [[ "$check_result" == *"\"status\":\"error\""* ]] && [[ "$check_result" == *"\"message\":\"Unauthorized\""* ]]; then
    echo -e "${RED}Authentication error: Unauthorized access to n8n API${NC}"
    echo -e "${YELLOW}Please create an API key in n8n:${NC}"
    echo -e "  1. Open n8n interface (${N8N_URL})"
    echo -e "  2. Go to Settings → API"
    echo -e "  3. Create a new API key"
    echo -e "  4. Run this script with: $0 -k \"your-api-key\""
    return 1
  fi
  
  local workflow_exists=$(echo "$check_result" | jq -r '.data[] | select(.id == "'"$workflow_id"'") | .id' 2>/dev/null)
  
  local api_cmd=""
  local success_msg=""
  
  if [ -n "$workflow_exists" ]; then
    # Update existing workflow
    echo -e "${YELLOW}Workflow with ID $workflow_id exists. Updating...${NC}"
    api_cmd="curl -s -X PUT $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/rest/workflows/$workflow_id\" -d @\"$file\""
    success_msg="Updated"
  else
    # Create new workflow
    echo -e "${YELLOW}Creating new workflow...${NC}"
    api_cmd="curl -s -X POST $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/rest/workflows\" -d @\"$file\""
    success_msg="Created"
  fi
  
  # Execute the API call
  echo -e "${YELLOW}Sending API request...${NC}"
  local api_result=$(eval "$api_cmd")
  
  # Check for authentication error in the API result
  if [[ "$api_result" == *"\"status\":\"error\""* ]] && [[ "$api_result" == *"\"message\":\"Unauthorized\""* ]]; then
    echo -e "${RED}Authentication error: Unauthorized access to n8n API${NC}"
    echo -e "${YELLOW}Please create an API key in n8n:${NC}"
    echo -e "  1. Open n8n interface (${N8N_URL})"
    echo -e "  2. Go to Settings → API"
    echo -e "  3. Create a new API key"
    echo -e "  4. Run this script with: $0 -k \"your-api-key\""
    return 1
  fi
  
  # Debug output
  echo -e "${YELLOW}API Response:${NC}"
  echo "$api_result" | jq '.' 2>/dev/null || echo "$api_result"
  
  # Check if the response contains an ID and it's not null
  local api_status=$(echo "$api_result" | jq -r '.id' 2>/dev/null)
  local error_msg=$(echo "$api_result" | jq -r '.message' 2>/dev/null)
  
  if [ -n "$api_status" ] && [ "$api_status" != "null" ]; then
    echo -e "${GREEN}Successfully ${success_msg} workflow: ${workflow_name} (ID: ${api_status})${NC}"
    
    # Activate the workflow if it's marked as active in the JSON
    local is_active=$(jq -r '.active' "$file")
    if [ "$is_active" = "true" ]; then
      echo -e "${YELLOW}Activating workflow...${NC}"
      local activate_cmd="curl -s -X PUT $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/rest/workflows/$api_status/activate\""
      eval "$activate_cmd" > /dev/null
      echo -e "${GREEN}Workflow activated.${NC}"
    fi
    
    return 0
  else
    echo -e "${RED}Failed to import workflow: ${workflow_name}${NC}"
    if [ -n "$error_msg" ]; then
      echo -e "${RED}Error message: ${error_msg}${NC}"
    fi
    echo -e "${RED}Full API response: ${api_result}${NC}"
    return 1
  fi
}

# Main script execution
main() {
  echo -e "${GREEN}=== n8n Workflow Deployment Script (REST API) ===${NC}"
  
  # Parse command line arguments
  parse_args "$@"
  
  # Check dependencies
  check_dependencies || exit 1
  
  # Check if n8n is running
  check_n8n_running || exit 1
  
  # Check if workflows directory exists
  if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo -e "${RED}Workflows directory not found: $WORKFLOWS_DIR${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Found workflows directory: $WORKFLOWS_DIR${NC}"
  
  # Count the number of workflow files
  workflow_files=$(find "$WORKFLOWS_DIR" -name "*.json" -type f)
  workflow_count=$(echo "$workflow_files" | wc -l)
  
  echo -e "${GREEN}Found $workflow_count workflow files to import.${NC}"
  
  # Get confirmation before proceeding
  get_confirmation || exit 0
  
  # Import each workflow
  success_count=0
  for file in $workflow_files; do
    import_workflow "$file"
    if [ $? -eq 0 ]; then
      ((success_count++))
    fi
  done
  
  # Summary
  echo -e "${GREEN}=== Deployment Summary ===${NC}"
  echo -e "${GREEN}Successfully imported $success_count out of $workflow_count workflows.${NC}"
  
  if [ $success_count -eq $workflow_count ]; then
    echo -e "${GREEN}All workflows were imported successfully!${NC}"
    echo -e "${YELLOW}Please check the n8n interface to verify all workflows are present.${NC}"
  else
    echo -e "${YELLOW}Some workflows failed to import. Please check the logs above.${NC}"
  fi
}

# Execute the main function with all arguments
main "$@" 