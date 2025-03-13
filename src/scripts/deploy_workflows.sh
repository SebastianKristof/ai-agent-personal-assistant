#!/bin/bash
# deploy_workflows.sh
# Script to deploy all n8n workflows from JSON files
# This will overwrite existing workflows with the same IDs

# Set variables
N8N_URL="http://localhost:5678"
WORKFLOWS_DIR="$(dirname "$(dirname "$(realpath "$0")")")/workflows"
API_KEY="${N8N_API_KEY:-your-api-key}" # Use environment variable or default

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

# Function to import a workflow
import_workflow() {
  local file=$1
  local filename=$(basename "$file")
  local workflow_name=$(jq -r '.name' "$file")
  local workflow_id=$(jq -r '.id' "$file")
  
  echo -e "${YELLOW}Importing workflow: ${workflow_name} (ID: ${workflow_id})${NC}"
  
  # Use the n8n CLI to import the workflow
  n8n import:workflow --file="$file" --id="$workflow_id" --skipOwnershipCheck
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully imported workflow: ${workflow_name}${NC}"
    return 0
  else
    echo -e "${RED}Failed to import workflow: ${workflow_name}${NC}"
    return 1
  fi
}

# Function to activate a workflow
activate_workflow() {
  local workflow_id=$1
  local workflow_name=$2
  
  echo -e "${YELLOW}Activating workflow: ${workflow_name} (ID: ${workflow_id})${NC}"
  
  # Use the n8n API to activate the workflow
  curl -s -X PATCH "$N8N_URL/rest/workflows/$workflow_id/activate" \
    -H "X-N8N-API-KEY: $API_KEY" > /dev/null
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully activated workflow: ${workflow_name}${NC}"
    return 0
  else
    echo -e "${RED}Failed to activate workflow: ${workflow_name}${NC}"
    return 1
  fi
}

# Main script execution
main() {
  echo -e "${GREEN}=== n8n Workflow Deployment Script ===${NC}"
  
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
  
  # Import each workflow
  success_count=0
  for file in $workflow_files; do
    workflow_name=$(jq -r '.name' "$file")
    workflow_id=$(jq -r '.id' "$file")
    
    import_workflow "$file"
    if [ $? -eq 0 ]; then
      # Check if workflow should be active
      is_active=$(jq -r '.active' "$file")
      if [ "$is_active" == "true" ]; then
        activate_workflow "$workflow_id" "$workflow_name"
      fi
      ((success_count++))
    fi
  done
  
  # Summary
  echo -e "${GREEN}=== Deployment Summary ===${NC}"
  echo -e "${GREEN}Successfully imported $success_count out of $workflow_count workflows.${NC}"
  
  if [ $success_count -eq $workflow_count ]; then
    echo -e "${GREEN}All workflows were imported successfully!${NC}"
  else
    echo -e "${YELLOW}Some workflows failed to import. Please check the logs above.${NC}"
  fi
}

# Execute the main function
main 