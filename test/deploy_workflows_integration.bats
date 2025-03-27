#!/usr/bin/env bats

# Load common mocks
load "mocks"

setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"
  
  # Path to the script being tested
  export SCRIPT_PATH="src/scripts/deploy_workflows.sh"
  
  # Create a test workflow JSON
  cat > "$TEMP_DIR/test-workflow.json" << EOF
{
  "name": "Integration Test Workflow",
  "meta": {
    "instanceId": "test-instance"
  },
  "nodes": []
}
EOF

  # Setup mocks
  setup_mocks
  
  # Override curl with our mock
  function curl() {
    mock_curl "$@"
  }
  export -f curl
  
  # Mock n8n check - always return running
  function pgrep() {
    return 0
  }
  export -f pgrep
  
  # Mock jq for JSON processing
  function jq() {
    # Simple mock that just passes through input
    cat
  }
  export -f jq
}

teardown() {
  # Clean up temp directory
  rm -rf "$TEMP_DIR"
  
  # Clean up mocks
  cleanup_mocks
}

@test "Script creates new workflow when workflow does not exist" {
  # Prepare mock response for workflow query (empty response)
  echo '[]' > "$MOCK_DIR/workflow_query_response"
  
  # Prepare mock response for workflow creation
  echo '{"id": "new-workflow-id", "name": "Integration Test Workflow"}' > "$MOCK_DIR/workflow_create_response"
  
  # Run script with test workflow
  run bash "$SCRIPT_PATH" -f "$TEMP_DIR/test-workflow.json" -k "test-api-key" -y
  
  # Check exit code
  [ "$status" -eq 0 ]
  
  # Verify output contains success message
  [[ "$output" == *"Successfully Created workflow"* ]]
  
  # Check that curl was called with the right arguments
  grep -q "POST" "$MOCK_DIR/curl_args"
  grep -q "/api/v1/workflows" "$MOCK_DIR/curl_args"
}

@test "Script handles the -y flag correctly for auto-confirmation" {
  # Run script with -y flag
  run bash "$SCRIPT_PATH" -f "$TEMP_DIR/test-workflow.json" -k "test-api-key" -y
  
  # Check exit code
  [ "$status" -eq 0 ]
  
  # Verify output contains auto-confirm message
  [[ "$output" == *"Auto-confirming deployment"* ]]
}

@test "Script properly extracts workflow ID from API response" {
  # Prepare mock response for workflow creation with specific ID
  echo '{"id": "specific-workflow-id", "name": "Test Workflow"}' > "$MOCK_DIR/workflow_create_response"
  
  # Run script
  run bash "$SCRIPT_PATH" -f "$TEMP_DIR/test-workflow.json" -k "test-api-key" -y
  
  # Check exit code
  [ "$status" -eq 0 ]
  
  # Verify that the specific workflow ID is in the output
  [[ "$output" == *"specific-workflow-id"* ]]
} 