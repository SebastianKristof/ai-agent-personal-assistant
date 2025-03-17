# Context-Aware Idea Handler Design

## Overview

The Context-Aware Idea Handler is an enhanced version of the basic idea handler that adds contextual awareness to the processing of user ideas. It analyzes new ideas in relation to existing similar ideas and the user's personal context (such as calendar events) to provide more intelligent responses and suggestions.

The context-aware idea handler enhances the basic idea saving functionality by:

1. Gathering relevant context (similar ideas, calendar events)
2. Using AI to analyze the idea in relation to this context
3. Providing intelligent insights and suggestions
4. Saving the enhanced idea with additional metadata
5. Generating a rich, contextual response

## Goals

1. Enhance idea processing with contextual awareness
2. Identify connections between new ideas and existing ones
3. Relate ideas to upcoming events and meetings
4. Provide intelligent suggestions for next steps
5. Improve idea organization through context-based tagging

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

### 1. Data Ingestion
- **Webhook Node**: Receives idea data from the task classifier
- **Process Idea Data**: Extracts and formats the idea information

### 2. Context Gathering
- **Query Similar Ideas**: Retrieves similar ideas from the vector database
- **Query Calendar Events**: Fetches upcoming calendar events
- **Merge Context**: Combines all contextual information

### 3. Contextual Analysis
- **AI Agent: Context Analysis**: Analyzes the idea in relation to the gathered context
- **Enhance Idea**: Enriches the idea with the AI analysis results

### 4. Storage and Response
- **Save to MongoDB**: Persists the enhanced idea
- **Format Response**: Creates a user-friendly response with contextual insights
- **Respond to Webhook**: Returns the response to the caller

### 5. Additional Features
- **Post-Processing**: Performs additional processing after saving
- **Should Notify?**: Determines if a notification should be sent
- **Send Notification**: Sends a follow-up notification if needed
- **Log Similar Ideas**: Records similar ideas for debugging

## Implementation Details

### Context Sources

1. **Vector Database**
   - Stores embeddings of previous ideas
   - Enables semantic similarity search
   - Accessed via HTTP request to a local endpoint

2. **Calendar Integration**
   - Retrieves upcoming events from Google Calendar
   - Provides temporal context for ideas
   - Requires Google API credentials

### AI Analysis

The AI Agent node uses GPT-4o to analyze the idea in context with the following prompt structure:

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

### Response Format

The response to the user includes:
- Confirmation of the saved idea
- Analysis of the idea in context
- Warning if the idea is similar to existing ones
- Relevant upcoming events
- Suggested next steps
- Tags applied to the idea

### Example Response

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

## Integration Points

1. **Task Classifier Integration**
   - The task classifier workflow sends idea data to this workflow
   - Communication happens via webhook

2. **Vector Database Integration**
   - The workflow queries the vector database for similar ideas
   - Requires a running vector database service

3. **Google Calendar Integration**
   - The workflow fetches calendar events
   - Requires Google API credentials

4. **MongoDB Integration**
   - The workflow stores enhanced ideas in MongoDB
   - Requires MongoDB credentials

## Benefits

1. **Contextual Awareness**: Understands the idea in relation to existing knowledge
2. **Intelligent Insights**: Provides valuable analysis beyond simple storage
3. **Proactive Suggestions**: Recommends relevant next steps
4. **Enhanced Organization**: Adds intelligent tags and connections
5. **Time Efficiency**: Identifies duplicates and connections automatically

## Implementation Considerations

1. **Privacy and Security**
   - All personal data is processed locally
   - API keys and credentials are stored securely in n8n
   - No data is sent to external services except for AI processing

2. **Performance**
   - Vector database queries are limited to top 3 results
   - Calendar queries are limited to events in the next 7 days
   - AI processing may introduce latency

3. **Error Handling**
   - Fallbacks for missing context sources
   - Graceful handling of AI processing failures
   - Default values for missing fields

## Future Enhancements

1. **Additional Context Sources**
   - Integration with task management systems
   - Contact information for relevant people
   - Location-based context
   - Email content
   - Notes and documents

2. **Enhanced Analysis**
   - More sophisticated duplicate detection
   - Trend analysis across ideas
   - Priority scoring based on context

3. **User Feedback Loop**
   - Capture user feedback on suggestions
   - Improve analysis based on feedback
   - Learn from user corrections and preferences

4. **Proactive Notifications**
   - Send reminders about ideas before relevant events
   - Suggest revisiting ideas based on new context
   - Schedule reminders about ideas

## Conclusion

The Context-Aware Idea Handler represents a significant enhancement to the basic idea handling capability. By incorporating contextual awareness, it provides more intelligent and personalized responses to user ideas, helping to connect ideas to existing knowledge and upcoming events, and suggesting meaningful next steps. 