#!/bin/bash
# export_workflows.sh
# Script to export all n8n workflows to JSON files
# This helps keep your workflow files in sync with changes made in the UI

# Set variables
N8N_URL="http://localhost:5678"
WORKFLOWS_DIR="$(dirname "$(dirname "$(realpath "$0")")")/workflows"
API_KEY="${N8N_API_KEY:-your-api-key}" # Use environment variable or default
BACKUP_DIR="$WORKFLOWS_DIR/backups/$(date +%Y%m%d_%H%M%S)"
AUTO_CONFIRM=false

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
  echo "  -y, --yes    Automatically confirm overwriting workflow files"
  echo "  -h, --help   Show this help message"
  echo ""
  echo "Environment variables:"
  echo "  N8N_API_KEY  API key for n8n (optional)"
}

# Function to check dependencies
check_dependencies() {
  echo -e "${YELLOW}Checking dependencies...${NC}"
  
  # Check for jq
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    echo -e "${YELLOW}Please install jq:${NC}"
    echo -e "  - On macOS: brew install jq"
    echo -e "  - On Ubuntu/Debian: sudo apt-get install jq"
    echo -e "  - On CentOS/RHEL: sudo yum install jq"
    echo -e "  - On Windows with Chocolatey: choco install jq"
    return 1
  fi
  
  # Check for curl
  if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed.${NC}"
    echo -e "${YELLOW}Please install curl:${NC}"
    echo -e "  - On macOS: brew install curl"
    echo -e "  - On Ubuntu/Debian: sudo apt-get install curl"
    echo -e "  - On CentOS/RHEL: sudo yum install curl"
    echo -e "  - On Windows with Chocolatey: choco install curl"
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
    
    # Remind about task runners
    echo -e "${YELLOW}Note: n8n recommends enabling task runners with N8N_RUNNERS_ENABLED=true${NC}"
    echo -e "${YELLOW}Learn more: https://docs.n8n.io/hosting/configuration/task-runners/${NC}"
    
    return 0
  else
    echo -e "${RED}n8n is not running. Please start n8n first.${NC}"
    echo -e "${YELLOW}You can start n8n with: n8n start${NC}"
    echo -e "${YELLOW}Consider using: N8N_RUNNERS_ENABLED=true n8n start${NC}"
    return 1
  fi
}

# Function to get confirmation
get_confirmation() {
  if [ "$AUTO_CONFIRM" = true ]; then
    echo -e "${YELLOW}Auto-confirming export (--yes flag provided)${NC}"
    return 0
  fi
  
  if [ -d "$WORKFLOWS_DIR" ] && [ "$(ls -A "$WORKFLOWS_DIR"/*.json 2>/dev/null)" ]; then
    echo -e "${YELLOW}WARNING: This will overwrite existing workflow files in $WORKFLOWS_DIR${NC}"
    echo -e "${YELLOW}A backup will be created in $BACKUP_DIR${NC}"
    echo -e "${YELLOW}Do you want to continue? (y/N)${NC}"
    
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      return 0
    else
      echo -e "${YELLOW}Export cancelled.${NC}"
      return 1
    fi
  fi
  
  # No existing files, no need for confirmation
  return 0
}

# Function to get all workflows from n8n
get_all_workflows() {
  echo -e "${YELLOW}Fetching all workflows from n8n...${NC}"
  
  local response=$(curl -s -X GET "$N8N_URL/rest/workflows" \
    -H "X-N8N-API-KEY: $API_KEY")
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to fetch workflows from n8n.${NC}"
    return 1
  fi
  
  # Check if the response contains workflows
  local workflow_count=$(echo "$response" | jq '.data | length')
  if [ "$workflow_count" -eq 0 ]; then
    echo -e "${YELLOW}No workflows found in n8n.${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Found $workflow_count workflows in n8n.${NC}"
  echo "$response" | jq '.data'
  return 0
}

# Function to export a single workflow
export_workflow() {
  local workflow_id=$1
  local workflow_name=$2
  local target_file=$3
  
  echo -e "${YELLOW}Exporting workflow: ${workflow_name} (ID: ${workflow_id})${NC}"
  
  # Get the workflow data
  local workflow_data=$(curl -s -X GET "$N8N_URL/rest/workflows/$workflow_id" \
    -H "X-N8N-API-KEY: $API_KEY")
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to fetch workflow data for: ${workflow_name}${NC}"
    return 1
  fi
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Save the workflow data to file
  echo "$workflow_data" | jq '.' > "$target_file"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully exported workflow to: ${target_file}${NC}"
    return 0
  else
    echo -e "${RED}Failed to save workflow to: ${target_file}${NC}"
    return 1
  fi
}

# Function to backup existing workflow files
backup_existing_workflows() {
  if [ -d "$WORKFLOWS_DIR" ] && [ "$(ls -A "$WORKFLOWS_DIR"/*.json 2>/dev/null)" ]; then
    echo -e "${YELLOW}Backing up existing workflow files...${NC}"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Copy all JSON files to backup directory
    cp "$WORKFLOWS_DIR"/*.json "$BACKUP_DIR"
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Successfully backed up workflows to: ${BACKUP_DIR}${NC}"
      return 0
    else
      echo -e "${RED}Failed to backup workflows.${NC}"
      return 1
    fi
  else
    echo -e "${YELLOW}No existing workflow files to backup.${NC}"
    return 0
  fi
}

# Function to sanitize workflow name for filename
sanitize_filename() {
  local name=$1
  # Replace spaces and special characters with underscores
  echo "$name" | tr -s ' ' | tr ' ' '_' | tr -cd '[:alnum:]_-.' | tr '[:upper:]' '[:lower:]'
}

# Main script execution
main() {
  echo -e "${GREEN}=== n8n Workflow Export Script ===${NC}"
  
  # Parse command line arguments
  parse_args "$@"
  
  # Check dependencies
  check_dependencies || exit 1
  
  # Check if n8n is running
  check_n8n_running || exit 1
  
  # Create workflows directory if it doesn't exist
  mkdir -p "$WORKFLOWS_DIR"
  
  # Get confirmation before proceeding
  get_confirmation || exit 0
  
  # Backup existing workflows
  backup_existing_workflows
  
  # Get all workflows from n8n
  workflows_json=$(get_all_workflows)
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to get workflows from n8n. Exiting.${NC}"
    exit 1
  fi
  
  # Export each workflow
  success_count=0
  workflow_count=$(echo "$workflows_json" | jq '. | length')
  
  echo -e "${GREEN}Exporting $workflow_count workflows...${NC}"
  
  echo "$workflows_json" | jq -c '.[]' | while read -r workflow; do
    workflow_id=$(echo "$workflow" | jq -r '.id')
    workflow_name=$(echo "$workflow" | jq -r '.name')
    sanitized_name=$(sanitize_filename "$workflow_name")
    target_file="$WORKFLOWS_DIR/${sanitized_name}.json"
    
    export_workflow "$workflow_id" "$workflow_name" "$target_file"
    if [ $? -eq 0 ]; then
      ((success_count++))
    fi
  done
  
  # Summary
  echo -e "${GREEN}=== Export Summary ===${NC}"
  echo -e "${GREEN}Successfully exported $success_count out of $workflow_count workflows.${NC}"
  
  if [ $success_count -eq $workflow_count ]; then
    echo -e "${GREEN}All workflows were exported successfully!${NC}"
    echo -e "${GREEN}Workflow files are located in: $WORKFLOWS_DIR${NC}"
    echo -e "${YELLOW}Backup of previous workflow files: $BACKUP_DIR${NC}"
  else
    echo -e "${YELLOW}Some workflows failed to export. Please check the logs above.${NC}"
  fi
}

# Execute the main function with all arguments
main "$@" 