#!/usr/bin/env bats

setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"
  
  # Path to the script being tested
  export SCRIPT_PATH="src/scripts/deploy_workflows.sh"
  
  # Create a test workflow JSON with a name
  cat > "$TEMP_DIR/workflow-with-name.json" << EOF
{
  "name": "Test Workflow",
  "meta": {
    "instanceId": "test-instance"
  },
  "nodes": []
}
EOF

  # Create a test workflow JSON without a name
  cat > "$TEMP_DIR/workflow-without-name.json" << EOF
{
  "meta": {
    "instanceId": "test-instance"
  },
  "nodes": []
}
EOF

  # Mock the curl command
  function curl() {
    echo "Mocked curl called with: $@" >&3
    echo '{"id": "test-id", "name": "Test Workflow"}'
  }
  export -f curl
  
  # Mock the command to check if n8n is running
  function pgrep() {
    return 0  # Return success to indicate n8n is running
  }
  export -f pgrep
}

teardown() {
  # Clean up temp directory
  rm -rf "$TEMP_DIR"
}

# Helper to run the script with arguments and capture output
run_script() {
  run bash -c "source \"$SCRIPT_PATH\" && $1"
  echo "Output: $output" >&3
  echo "Status: $status" >&3
}

@test "Script shows usage when no arguments provided" {
  run bash "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "Script detects missing required arguments" {
  run bash "$SCRIPT_PATH" -f test.json
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: API key is required"* ]]
}

@test "Script extracts name from workflow JSON when available" {
  # Source the script to test internal functions
  source "$SCRIPT_PATH"
  
  # Run the format_workflow_json function with our test file
  local result=$(format_workflow_json "$TEMP_DIR/workflow-with-name.json")
  
  # Check if the name was preserved
  [[ "$result" == *"\"name\": \"Test Workflow\""* ]]
}

@test "Script infers name from filename when name is not in JSON" {
  # Source the script to test internal functions
  source "$SCRIPT_PATH"
  
  # Run the format_workflow_json function with our test file
  local result=$(format_workflow_json "$TEMP_DIR/workflow-without-name.json")
  
  # Check if the name was inferred from filename
  [[ "$result" == *"\"name\": \"workflow without name\""* ]]
}

@test "Script formats auth headers correctly" {
  source "$SCRIPT_PATH"
  
  local headers=$(get_auth_headers "test-api-key")
  
  [[ "$headers" == *"X-N8N-API-KEY: test-api-key"* ]]
} 