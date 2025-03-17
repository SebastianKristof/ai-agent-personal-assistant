# Context-Aware Idea Handler Design

This document outlines the design for a context-aware idea handler that uses AI to analyze ideas in the context of existing data and provide intelligent responses.

## Overview

The context-aware idea handler enhances the basic idea saving functionality by:

1. Gathering relevant context (similar ideas, calendar events)
2. Using AI to analyze the idea in relation to this context
3. Providing intelligent insights and suggestions
4. Saving the enhanced idea with additional metadata
5. Generating a rich, contextual response

## Workflow Architecture

```
┌─────────────┐     ┌─────────────────┐     ┌───────────────────┐
│   Webhook   │────▶│ Process Idea Data│────▶│ Query Similar Ideas│
└─────────────┘     └─────────────────┘     └───────────────────┘
                                                      │
                                                      ▼
┌─────────────────┐     ┌─────────────┐     ┌───────────────────┐
│ Respond to Webhook│◀───│Format Response│◀───│ Query Calendar    │
└─────────────────┘     └─────────────┘     └───────────────────┘
                                                      │
                                                      ▼
┌─────────────────┐     ┌─────────────┐     ┌───────────────────┐
│ Save to MongoDB  │◀───│ Enhance Idea │◀───│ AI Agent: Analysis │
└─────────────────┘     └─────────────┘     └───────────────────┘
```

## Key Components

### 1. Initial Processing

- **Webhook**: Receives the idea data from the task classifier
- **Process Idea Data**: Extracts and formats the basic idea information

### 2. Context Gathering

- **Query Similar Ideas**: Searches the vector database for semantically similar ideas
- **Query Calendar Events**: Retrieves upcoming calendar events
- **Merge Context**: Combines all context data into a structured format

### 3. AI Analysis

- **AI Agent Node**: Analyzes the idea in relation to the gathered context
- Uses GPT-4o to provide intelligent insights
- Generates suggestions, identifies duplicates, and recommends tags
- Outputs structured analysis in JSON format

### 4. Enhanced Storage

- **Enhance Idea**: Enriches the idea with AI analysis and additional metadata
- **Save to MongoDB**: Stores the enhanced idea in the database

### 5. Response Generation

- **Format Response**: Creates a rich, contextual response including insights and suggestions
- **Respond to Webhook**: Returns the response to the calling workflow

## AI Agent Configuration

### System Prompt

```
You are a context-aware personal assistant analyzing a new idea.
Analyze the new idea in relation to existing similar ideas and upcoming calendar events.
Provide insights on:
1. Whether this idea is novel or similar to existing ones
2. Potential connections to upcoming meetings or events
3. Suggestions for next steps or improvements
4. Recommended tags based on content and context

Format your response as JSON:
{
  "analysis": "Your detailed analysis here",
  "is_duplicate": boolean,
  "related_ideas": ["List of related idea IDs"],
  "relevant_events": ["List of relevant event IDs"],
  "suggested_tags": ["tag1", "tag2"],
  "next_steps": ["Suggested action 1", "Suggested action 2"],
  "enhanced_content": "Improved version of the idea with context"
}
```

### Input Data Structure

```json
{
  "new_idea": "The content of the new idea",
  "similar_ideas": [
    {
      "id": "idea_123456",
      "content": "Content of similar idea 1",
      "tags": ["tag1", "tag2"],
      "timestamp": "2023-06-15T10:30:00Z"
    }
  ],
  "upcoming_events": [
    {
      "id": "event_123456",
      "summary": "Meeting with Sarah",
      "start": {
        "dateTime": "2023-06-16T14:00:00Z"
      },
      "attendees": [
        {
          "email": "sarah@example.com",
          "displayName": "Sarah Johnson"
        }
      ]
    }
  ]
}
```

## Example Response

Instead of a simple confirmation, the assistant provides a rich, contextual response:

```
I've saved your idea: "Create a meal planning app"

This idea builds on your previous thoughts about food automation. It's related to your "Weekly grocery shopping automation" idea from May 15th, but focuses more on the planning aspect rather than shopping.

This might be relevant to your upcoming events:
- Meeting with Sarah (Food Tech Consultant) on June 16th at 2:00 PM

Suggested next steps:
- Discuss this idea with Sarah during your meeting tomorrow
- Research existing meal planning apps to identify gaps
- Consider integrating with your grocery shopping automation idea

I've tagged this with: app, productivity, food, automation
```

## Benefits

1. **Contextual Awareness**: Understands the idea in relation to existing knowledge
2. **Intelligent Insights**: Provides valuable analysis beyond simple storage
3. **Proactive Suggestions**: Recommends relevant next steps
4. **Enhanced Organization**: Adds intelligent tags and connections
5. **Time Efficiency**: Identifies duplicates and connections automatically

## Implementation Requirements

1. **API Integrations**:
   - Vector database for semantic search
   - Calendar service (Google Calendar, etc.)
   - MongoDB for storage

2. **Credentials**:
   - OpenAI API key
   - MongoDB connection
   - Calendar service credentials

3. **Error Handling**:
   - Fallbacks for unavailable services
   - Graceful degradation when context can't be gathered

## Future Enhancements

1. **Additional Context Sources**:
   - Contacts database
   - Task/project management systems
   - Email content
   - Notes and documents

2. **User Feedback Loop**:
   - Allow users to rate the quality of insights
   - Learn from user corrections and preferences

3. **Proactive Follow-ups**:
   - Schedule reminders about ideas
   - Suggest revisiting ideas after relevant events 