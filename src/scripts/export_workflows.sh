#!/bin/bash
# export_workflows.sh
# Script to export all n8n workflows to JSON files
# This helps keep your workflow files in sync with changes made in the UI

# Set variables
N8N_URL="http://localhost:5678"
WORKFLOWS_DIR="$(dirname "$(dirname "$(realpath "$0")")")/workflows"
API_KEY="${N8N_API_KEY:-your-api-key}" # Use environment variable or default
BACKUP_DIR="$WORKFLOWS_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
  
  # Check if n8n is running
  check_n8n_running || exit 1
  
  # Create workflows directory if it doesn't exist
  mkdir -p "$WORKFLOWS_DIR"
  
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

# Execute the main function
main 