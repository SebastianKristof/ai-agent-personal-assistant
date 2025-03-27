.PHONY: test test-unit test-integration

# Run all tests
test: test-unit test-integration

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	bats test/deploy_workflows.bats

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	bats test/deploy_workflows_integration.bats

# Install dependencies for testing
setup-test:
	@echo "Installing test dependencies..."
	npm install -g bats

# Run a specific test file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=<path-to-test-file>"; \
		exit 1; \
	fi
	bats $(FILE) 