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

# n8n Workflow Management Scripts

This directory contains scripts for managing and deploying n8n workflows.

## Dependencies

These scripts require the following dependencies:

- **jq**: A lightweight and flexible command-line JSON processor
  - Install on macOS: `brew install jq`
  - Install on Ubuntu/Debian: `sudo apt-get install jq`
  - Install on CentOS/RHEL: `sudo yum install jq`
  - Install on Windows with Chocolatey: `choco install jq`

- **curl**: A command-line tool for transferring data with URLs
  - Install on macOS: `brew install curl`
  - Install on Ubuntu/Debian: `sudo apt-get install curl`
  - Install on CentOS/RHEL: `sudo yum install curl`
  - Install on Windows with Chocolatey: `choco install curl`

- **n8n**: The workflow automation tool
  - Install globally: `npm install n8n -g`

## n8n Task Runners

n8n recommends enabling task runners for better performance and reliability. When starting n8n, use:

```bash
N8N_RUNNERS_ENABLED=true n8n start
```

Learn more about task runners in the [n8n documentation](https://docs.n8n.io/hosting/configuration/task-runners/).

## start_n8n.sh

This script starts n8n with the recommended settings, including task runners enabled. It will:

1. Check if n8n is installed
2. Check if n8n is already running
3. Start n8n with task runners enabled
4. Verify that n8n started successfully

### Usage

```bash
# Start n8n with recommended settings
./src/scripts/start_n8n.sh
```

## deploy_workflows.sh

This script automates the deployment of all workflow JSON files to your n8n instance. It will:

1. Check if required dependencies are installed
2. Check if n8n is running
3. Find all workflow JSON files in the `src/workflows` directory
4. Ask for confirmation before overwriting existing workflows (unless `-y` flag is used)
5. Import each workflow using the n8n REST API
6. Activate workflows that are marked as active in their JSON definition
7. Provide a summary of the deployment

### Prerequisites

- jq installed (for JSON parsing)
- curl installed (for API calls)
- n8n instance running on http://localhost:5678 (configurable in the script)

### Usage

```bash
# Set your n8n API key (optional)
export N8N_API_KEY="your-api-key"

# Run the deployment script with confirmation prompt
./src/scripts/deploy_workflows.sh

# Run the deployment script with automatic confirmation (useful for CI/CD)
./src/scripts/deploy_workflows.sh -y

# Run the deployment script with API key specified in command line
./src/scripts/deploy_workflows.sh -k "your-api-key"
```

### Command Line Options

- `-y, --yes`: Automatically confirm overwriting workflows without prompting
- `-k, --api-key`: Specify the n8n API key for authentication
- `-h, --help`: Show help message

### Configuration

You can modify the following variables at the top of the script:

- `N8N_URL`: The URL of your n8n instance (default: http://localhost:5678)
- `WORKFLOWS_DIR`: The directory containing your workflow JSON files (default: src/workflows)
- `API_KEY`: Your n8n API key (can be set via command line or environment variable)

### Workflow Requirements

For the script to work properly, each workflow JSON file should:

1. Have a unique `id` field
2. Have a `name` field
3. Have an `active` field set to `true` or `false`

### REST API vs CLI

This script uses the n8n REST API instead of the CLI commands. Benefits include:

1. Works with remote n8n instances (not just local)
2. No need to install n8n CLI globally
3. More reliable across different n8n versions
4. Better error handling and feedback
5. Can be used with authentication for secure environments

### Troubleshooting

If you encounter issues:

1. Make sure n8n is running before executing the script
2. Verify that your workflow JSON files are valid
3. Check that you have the correct API key set
4. Ensure you have the necessary permissions to import and activate workflows
5. Check the API response for detailed error messages

## export_workflows.sh

This script exports all workflows from your n8n instance to JSON files. It's useful for:

1. Keeping your workflow files in sync with changes made in the n8n UI
2. Backing up your workflows
3. Migrating workflows between environments
4. Maintaining version control of your workflows

The script will:

1. Check if required dependencies are installed
2. Check if n8n is running
3. Ask for confirmation before overwriting existing workflow files (unless `-y` flag is used)
4. Backup existing workflow files to a timestamped directory
5. Fetch all workflows from your n8n instance
6. Export each workflow to a JSON file in the `src/workflows` directory
7. Provide a summary of the export

### Prerequisites

- jq installed (for JSON parsing)
- curl installed (for API calls)
- n8n instance running on http://localhost:5678 (configurable in the script)

### Usage

```bash
# Set your n8n API key (optional, can also be hardcoded in the script)
export N8N_API_KEY="your-api-key"

# Run the export script with confirmation prompt
./src/scripts/export_workflows.sh

# Run the export script with automatic confirmation (useful for CI/CD)
./src/scripts/export_workflows.sh -y
```

### Command Line Options

- `-y, --yes`: Automatically confirm overwriting workflow files without prompting
- `-h, --help`: Show help message

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

1. Start n8n with `start_n8n.sh`
2. Make changes to workflows in the n8n UI
3. Run `export_workflows.sh` to export the changes to JSON files
4. Commit the changes to version control
5. On other environments, run `deploy_workflows.sh` to deploy the changes

## Automation

For CI/CD pipelines or automated deployments, use the `-y` flag to skip confirmation prompts:

```bash
# In a CI/CD pipeline
./src/scripts/deploy_workflows.sh -y
```

## Other Scripts

- `start_services.sh`: Start all required services for the AI personal assistant
- `stop_services.sh`: Stop all running services 