#!/bin/bash
# deploy_workflows.sh
# Script to deploy n8n workflows from JSON files using REST API
# This will overwrite existing workflows with the same IDs

# Set variables
N8N_URL="http://localhost:5678"
WORKFLOWS_DIR="$(dirname "$(dirname "$(realpath "$0")")")/workflows"
AUTO_CONFIRM=false
API_KEY=""
SPECIFIC_FILE=""

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
      -f|--file) SPECIFIC_FILE="$2"; shift ;;
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
  echo "  -f, --file      Specific workflow file to deploy (optional)"
  echo "  -h, --help      Show this help message"
  echo ""
  echo "If no file is specified, all workflows in the workflows directory will be deployed."
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
  if [ -n "$API_KEY" ]; then
    # Debug output
    echo -e "${YELLOW}Debug: Using API key: ${API_KEY:0:4}...${API_KEY: -4}${NC}" >&2
    # Return only the header without any debug output - with proper quoting
    printf "%s '%s'" "-H" "X-N8N-API-KEY: $API_KEY"
  else
    # Debug output
    echo -e "${YELLOW}Debug: No API key provided${NC}" >&2
    # Return empty string
    echo ""
  fi
}

# Function to import a workflow using REST API
import_workflow() {
  local file=$1
  local filename=$(basename "$file")
  local workflow_name=$(jq -r '.name // "null"' "$file")
  local workflow_id=$(jq -r '.id // ""' "$file")
  
  # If name is missing or null, infer it from the filename
  if [ "$workflow_name" = "null" ]; then
    # Remove extension and replace hyphens/underscores with spaces
    workflow_name=$(echo "$filename" | sed 's/\.[^.]*$//' | sed 's/[-_]/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo -e "${YELLOW}No name found in workflow, inferring name: ${workflow_name}${NC}"
  fi
  
  echo -e "${YELLOW}Importing workflow: ${workflow_name}${NC}"
  echo -e "${YELLOW}File: ${filename}${NC}"
  
  # Format the workflow payload for the API
  echo -e "${YELLOW}Formatting workflow JSON for API...${NC}"
  local temp_file=$(mktemp)
  
  # Add the inferred name if necessary
  if jq -e '.name' "$file" > /dev/null 2>&1; then
    # Name exists, use the original JSON
    jq '{
      name: .name,
      nodes: .nodes,
      connections: .connections,
      settings: (.settings // {executionOrder: "v1"})
    }' "$file" > "$temp_file"
  else
    # Name doesn't exist, add the inferred name
    jq --arg name "$workflow_name" '{
      name: $name,
      nodes: .nodes,
      connections: .connections,
      settings: (.settings // {executionOrder: "v1"})
    }' "$file" > "$temp_file"
  fi
  
  # For debugging - show first few lines of the formatted JSON
  echo -e "${YELLOW}Debug: Formatted payload (first few lines):${NC}"
  head -n 20 "$temp_file"
  
  # Get auth headers without debug output
  local auth_headers
  auth_headers=$(get_auth_headers)
  
  # Debug output for auth headers
  echo -e "${YELLOW}Debug: Auth headers:${NC}" >&2
  echo "$auth_headers" >&2
  
  # Simple curl command for checking workflow
  local check_cmd="curl -v $auth_headers \"$N8N_URL/api/v1/workflows?filter=$workflow_id\""
  echo -e "${YELLOW}Debug: Executing check command:${NC}" >&2
  echo -e "${YELLOW}$check_cmd${NC}" >&2
  
  # Execute command and capture output
  local check_result
  check_result=$(eval "$check_cmd" 2>&1)
  local check_http_code
  check_http_code=$(echo "$check_result" | grep -o "HTTP/[0-9.]* [0-9]*" | tail -n1 | awk '{print $2}')
  
  echo -e "${YELLOW}Debug: HTTP Status Code: $check_http_code${NC}" >&2
  
  # Note: It's normal to get a 400 error on the check command if the workflow doesn't exist yet (empty filter)
  if [[ "$check_http_code" = "400" && "$workflow_id" = "" ]]; then
    echo -e "${YELLOW}Info: No existing workflow ID provided, creating new workflow${NC}"
  fi
  
  # Check for authentication error
  if [[ "$check_result" == *"\"status\":\"error\""* ]] && [[ "$check_result" == *"\"message\":\"Unauthorized\""* ]]; then
    echo -e "${RED}Authentication error: Unauthorized access to n8n API${NC}"
    echo -e "${YELLOW}Debug: Full API Response:${NC}"
    echo "$check_result" | grep -A 10 "Unauthorized" || echo "$check_result"
    echo -e "${YELLOW}Please verify:${NC}"
    echo -e "  1. The API key is correct and active"
    echo -e "  2. The API key has the necessary permissions"
    echo -e "  3. The n8n instance is running and accessible"
    echo -e "  4. The API key is properly formatted (no extra spaces or newlines)"
    echo -e "  5. The API key was created in n8n web interface under Settings → API"
    echo -e "  6. The API key has the necessary permissions for workflow access"
    # Clean up temp file
    rm -f "$temp_file"
    return 1
  fi
  
  local workflow_exists
  workflow_exists=$(echo "$check_result" | jq -r '.data[] | select(.id == "'"$workflow_id"'") | .id' 2>/dev/null)
  
  # Prepare the appropriate curl command
  local api_cmd=""
  local success_msg=""
  
  if [ -n "$workflow_exists" ]; then
    # Update existing workflow
    echo -e "${YELLOW}Workflow with ID $workflow_id exists. Updating...${NC}"
    api_cmd="curl -v -X PUT $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/api/v1/workflows/$workflow_id\" -d @\"$temp_file\""
    success_msg="Updated"
  else
    # Create new workflow
    echo -e "${YELLOW}Creating new workflow...${NC}"
    api_cmd="curl -v -X POST $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/api/v1/workflows\" -d @\"$temp_file\""
    success_msg="Created"
  fi
  
  # Debug output
  echo -e "${YELLOW}Debug: Executing API command:${NC}" >&2
  echo -e "${YELLOW}$api_cmd${NC}" >&2
  
  # Execute command and capture output
  local api_result
  api_result=$(eval "$api_cmd" 2>&1)
  local api_http_code
  api_http_code=$(echo "$api_result" | grep -o "HTTP/[0-9.]* [0-9]*" | tail -n1 | awk '{print $2}')
  
  echo -e "${YELLOW}Debug: HTTP Status Code: $api_http_code${NC}" >&2
  
  # Debug output
  echo -e "${YELLOW}API Response:${NC}"
  # Extract the JSON part of the response - needed because curl verbose output comes before the actual response
  local json_response
  json_response=$(echo "$api_result" | grep -o '{"name".*}' | head -n1)
  echo "$json_response" | jq '.' 2>/dev/null || echo "$api_result"
  
  # Clean up temporary file
  rm -f "$temp_file"
  
  # Check if the HTTP status code indicates success (2xx)
  if [[ "$api_http_code" =~ ^2[0-9][0-9]$ ]]; then
    echo -e "${GREEN}Successfully ${success_msg} workflow: ${workflow_name}${NC}"
    
    # Try to extract workflow ID from response if available
    local workflow_id
    workflow_id=$(echo "$json_response" | jq -r '.id' 2>/dev/null)
    if [ -n "$workflow_id" ] && [ "$workflow_id" != "null" ]; then
      echo -e "${GREEN}Workflow ID: ${workflow_id}${NC}"
      
      # Activate the workflow if it's marked as active in the JSON
      local is_active
      is_active=$(jq -r '.active // false' "$file")
      if [ "$is_active" = "true" ]; then
        echo -e "${YELLOW}Activating workflow...${NC}"
        local activate_cmd="curl -v -X PUT $auth_headers -H \"Content-Type: application/json\" \"$N8N_URL/api/v1/workflows/$workflow_id/activate\""
        echo -e "${YELLOW}Debug: Executing activate command:${NC}" >&2
        echo -e "${YELLOW}$activate_cmd${NC}" >&2
        eval "$activate_cmd" 2>&1 | grep -A 10 "HTTP" || true
        echo -e "${GREEN}Workflow activated.${NC}"
      fi
    fi
    
    return 0
  fi
  
  # If we get here, there was an error
  echo -e "${RED}Failed to import workflow: ${workflow_name}${NC}"
  local error_msg
  error_msg=$(echo "$json_response" | jq -r '.message' 2>/dev/null)
  if [ -n "$error_msg" ] && [ "$error_msg" != "null" ]; then
    echo -e "${RED}Error message: ${error_msg}${NC}"
  fi
  return 1
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
  
  # Handle specific file deployment
  if [ -n "$SPECIFIC_FILE" ]; then
    if [ ! -f "$SPECIFIC_FILE" ]; then
      echo -e "${RED}Specified file not found: $SPECIFIC_FILE${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}Deploying specific workflow file: $SPECIFIC_FILE${NC}"
    get_confirmation || exit 0
    
    import_workflow "$SPECIFIC_FILE"
    local import_result=$?
    echo -e "${YELLOW}Debug: import_workflow returned: $import_result${NC}"
    
    if [ $import_result -eq 0 ]; then
      echo -e "${GREEN}Workflow deployment completed successfully!${NC}"
    else
      echo -e "${RED}Workflow deployment failed.${NC}"
      exit 1
    fi
    return
  fi
  
  # Handle directory deployment (existing functionality)
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