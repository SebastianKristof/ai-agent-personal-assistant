# n8n Workflows

This document covers the n8n workflows used in the project, including how to manage, export, and deploy them.

## Workflow Management

The project includes tools to help manage n8n workflows across different environments (development, testing, production). This allows for version control and consistent deployment.

## Deploying Workflows

The project includes a script to deploy workflows from JSON files to an n8n instance using the REST API. This is useful for:

- Deploying workflow changes to production
- Setting up new environments
- Recovering workflows from backups
- Version controlling workflows

### Deploy Script Usage

The script is located at `src/scripts/deploy_workflows.sh`. Here's how to use it:

```bash
# Basic usage
./src/scripts/deploy_workflows.sh -f <path-to-workflow.json> -k <your-api-key> [-y]

# Example: Deploy a specific workflow with auto-confirmation
./src/scripts/deploy_workflows.sh -f ./src/n8n-workflow-templates/my-workflow.json -k "your-api-key" -y
```

#### Command-line Arguments

| Option | Description |
|--------|-------------|
| `-f, --file` | Path to a specific workflow file to deploy |
| `-k, --api-key` | API key for n8n authentication (required) |
| `-y, --yes` | Automatically confirm deployment (optional) |
| `-h, --help` | Show help message |

#### Notes

- The script requires an active n8n instance running on `http://localhost:5678` (default).
- Workflows will be automatically named:
  - If the JSON contains a `name` field, that value will be used
  - If no name exists, one will be inferred from the filename (e.g., `my-workflow.json` becomes "my workflow")
- The script requires `curl` and `jq` to be installed.

### Creating n8n API Keys

To deploy workflows, you'll need an API key:

1. Open your n8n instance in a browser (typically http://localhost:5678)
2. Go to Settings → API
3. Click "Create API Key"
4. Give it a descriptive name (e.g., "Workflow Deployment")
5. Copy the generated key for use with the deploy script

## Testing Workflow Deployment

The project includes automated tests for the deployment script using the Bats testing framework. To run these tests:

```bash
# Install Bats if not already installed
npm install -g bats

# Run all tests
make test

# Run only unit tests
make test-unit

# Run only integration tests
make test-integration
```

## Best Practices

1. **Version Control**: Store workflow JSON files in the `src/n8n-workflow-templates` directory and commit them to version control.
2. **Testing**: Test workflows in a development environment before deploying to production.
3. **Documentation**: Document the purpose and key nodes of each workflow.
4. **Naming**: Use consistent naming conventions for workflows and nodes.
5. **Error Handling**: Implement proper error handling in all workflows.

## Troubleshooting

If you encounter issues with the deployment script:

1. Ensure n8n is running and accessible at http://localhost:5678
2. Verify your API key is valid
3. Check that the workflow JSON file is properly formatted
4. Run the script with curl in verbose mode for more details:
   ```bash
   ./src/scripts/deploy_workflows.sh -f ./src/n8n-workflow-templates/my-workflow.json -k "your-api-key" -y
   ``` 