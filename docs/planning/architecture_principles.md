# Architecture Principles for AI Personal Assistant

This document outlines the key architectural principles and design decisions for the AI Personal Assistant project.

## Hybrid n8n Approach

We've chosen a hybrid approach that leverages n8n's visual workflow capabilities while maintaining code-based management and version control.

### Core Principles

1. **Use n8n as the Primary Orchestration Layer**
   - Leverage n8n's visual workflow editor for process orchestration
   - Take advantage of built-in integrations with external services
   - Enable non-developers to understand and potentially maintain workflows

2. **Develop n8n Workflows as Code**
   - Store workflows as JSON files in version control
   - Enable code review, versioning, and programmatic generation
   - Import/export workflows programmatically for deployment

3. **Prefer Built-in n8n Capabilities**
   - Use native n8n nodes whenever possible (Telegram, HTTP, database operations)
   - Leverage Function nodes for custom logic within n8n
   - Use Code nodes for complex transformations

4. **Use External Services Only When Necessary**
   - Develop external APIs (Python, etc.) only when n8n has limitations
   - Keep external services focused and minimal
   - Maintain clear interfaces between n8n and external services

5. **Data Storage Strategy**
   - Use n8n's database nodes for persistent storage (MongoDB, PostgreSQL, etc.)
   - Avoid file-based storage for production data
   - Implement proper data modeling within the chosen database

## Implementation Guidelines

### Task Classification

- Use n8n's HTTP Request node to call OpenAI for classification
- Process classification results using Function nodes
- Route tasks to appropriate handlers based on classification

### Data Storage

- Store structured data (ideas, todos, etc.) using n8n's database nodes
- Implement proper indexing and querying through n8n
- Use appropriate database types for different data needs:
  - Document databases (MongoDB) for unstructured data like ideas
  - Relational databases for structured data with relationships

### External Service Integration

- Use n8n's built-in nodes for calendar, email, social media, etc.
- Create custom nodes or external APIs only when necessary

### Workflow Management

- Export workflows as JSON for version control
- Import workflows programmatically when deploying
- Document workflow dependencies and configuration requirements

## Benefits of This Approach

- **Visual Management**: Enables non-technical users to understand and maintain workflows
- **Version Control**: Provides proper tracking of changes and rollback capabilities
- **Flexibility**: Allows for both visual and code-based development
- **Maintainability**: Reduces the number of external dependencies and services
- **Scalability**: Enables independent scaling of components when needed

## When to Deviate from These Principles

- When n8n has performance limitations for specific tasks
- When complex business logic is difficult to implement in n8n
- When specialized services provide significant advantages (e.g., vector databases)
- When security requirements necessitate custom implementations 