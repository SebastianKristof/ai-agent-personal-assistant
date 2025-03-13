# Helper Scripts

This directory contains utility scripts used in the AI Personal Assistant project.

## Purpose

These scripts help with:
- Setting up and configuring the environment
- Managing the vector database
- Processing data for ingestion
- Testing and debugging workflows
- Automating deployment tasks

## Available Scripts

*No scripts available yet. This section will be updated as scripts are developed.*

# n8n Workflow Deployment Scripts

This directory contains scripts for managing and deploying n8n workflows.

## deploy_workflows.sh

This script automates the deployment of all workflow JSON files to your n8n instance. It will:

1. Check if n8n is running
2. Find all workflow JSON files in the `src/workflows` directory
3. Import each workflow, overwriting any existing workflows with the same ID
4. Activate workflows that are marked as active in their JSON definition
5. Provide a summary of the deployment

### Prerequisites

- n8n CLI installed and accessible in your PATH
- jq installed (for JSON parsing)
- curl installed (for API calls)
- n8n instance running on http://localhost:5678 (configurable in the script)

### Usage

```bash
# Set your n8n API key (optional, can also be hardcoded in the script)
export N8N_API_KEY="your-api-key"

# Run the deployment script
./src/scripts/deploy_workflows.sh
```

### Configuration

You can modify the following variables at the top of the script:

- `N8N_URL`: The URL of your n8n instance (default: http://localhost:5678)
- `WORKFLOWS_DIR`: The directory containing your workflow JSON files (default: src/workflows)
- `API_KEY`: Your n8n API key (default: value of N8N_API_KEY environment variable or "your-api-key")

### Workflow Requirements

For the script to work properly, each workflow JSON file should:

1. Have a unique `id` field
2. Have a `name` field
3. Have an `active` field set to `true` or `false`

### Troubleshooting

If you encounter issues:

1. Make sure n8n is running before executing the script
2. Verify that your workflow JSON files are valid
3. Check that you have the correct API key set
4. Ensure you have the necessary permissions to import and activate workflows

## export_workflows.sh

This script exports all workflows from your n8n instance to JSON files. It's useful for:

1. Keeping your workflow files in sync with changes made in the n8n UI
2. Backing up your workflows
3. Migrating workflows between environments
4. Maintaining version control of your workflows

The script will:

1. Check if n8n is running
2. Backup existing workflow files to a timestamped directory
3. Fetch all workflows from your n8n instance
4. Export each workflow to a JSON file in the `src/workflows` directory
5. Provide a summary of the export

### Prerequisites

- jq installed (for JSON parsing)
- curl installed (for API calls)
- n8n instance running on http://localhost:5678 (configurable in the script)

### Usage

```bash
# Set your n8n API key (optional, can also be hardcoded in the script)
export N8N_API_KEY="your-api-key"

# Run the export script
./src/scripts/export_workflows.sh
```

### Configuration

You can modify the following variables at the top of the script:

- `N8N_URL`: The URL of your n8n instance (default: http://localhost:5678)
- `WORKFLOWS_DIR`: The directory to export workflow files to (default: src/workflows)
- `API_KEY`: Your n8n API key (default: value of N8N_API_KEY environment variable or "your-api-key")
- `BACKUP_DIR`: The directory to backup existing workflow files to (default: src/workflows/backups/TIMESTAMP)

### Troubleshooting

If you encounter issues:

1. Make sure n8n is running before executing the script
2. Verify that you have the correct API key set
3. Ensure you have write permissions to the workflows directory
4. Check that jq is installed and working properly

## Typical Workflow

A typical development workflow using these scripts:

1. Make changes to workflows in the n8n UI
2. Run `export_workflows.sh` to export the changes to JSON files
3. Commit the changes to version control
4. On other environments, run `deploy_workflows.sh` to deploy the changes

## Other Scripts

- `start_services.sh`: Start all required services for the AI personal assistant
- `stop_services.sh`: Stop all running services 