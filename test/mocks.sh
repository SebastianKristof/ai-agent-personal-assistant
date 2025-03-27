#!/bin/bash
# Mock helper functions for testing shell scripts

# Mock for curl that can be configured to return different responses
mock_curl() {
  # Store arguments for inspection
  echo "$@" > "$MOCK_DIR/curl_args"
  
  # Check for specific endpoint patterns and return appropriate mock responses
  if [[ "$*" == *"/api/v1/workflows?filter="* ]]; then
    # For workflow query endpoint
    cat "$MOCK_DIR/workflow_query_response"
  elif [[ "$*" == *"/api/v1/workflows"* && "$*" == *"POST"* ]]; then
    # For workflow creation endpoint
    cat "$MOCK_DIR/workflow_create_response"
  elif [[ "$*" == *"/api/v1/workflows/"*"/activate"* ]]; then
    # For workflow activation endpoint
    cat "$MOCK_DIR/workflow_activate_response"
  else
    # Default response
    cat "$MOCK_DIR/default_response"
  fi
}

# Setup mock environment
setup_mocks() {
  # Create mock directory
  export MOCK_DIR="$(mktemp -d)/mocks"
  mkdir -p "$MOCK_DIR"
  
  # Create default responses
  echo '{"id": "mock-id", "name": "Mock Workflow"}' > "$MOCK_DIR/default_response"
  echo '[]' > "$MOCK_DIR/workflow_query_response" # Empty response for non-existent workflow
  echo '{"id": "new-workflow-id", "name": "New Workflow"}' > "$MOCK_DIR/workflow_create_response"
  echo '{"id": "activated-workflow-id", "name": "Activated Workflow", "active": true}' > "$MOCK_DIR/workflow_activate_response"
  
  # Export mock functions
  export -f mock_curl
}

# Clean up mock environment
cleanup_mocks() {
  rm -rf "$(dirname "$MOCK_DIR")"
} 