# Conversation Management & Memory

## Overview

This frontend now supports **conversation memory** by sending conversation context to the backend with each request. This allows the AI agent to remember previous messages in the same conversation session.

## Architecture

### Lightweight Serverless Design
- **Frontend**: Stores conversations in browser localStorage
- **Backend**: Receives conversation context with each request (stateless)
- **Memory**: Hybrid approach - frontend manages persistence, backend gets context

### Data Flow
1. User sends a message
2. Frontend retrieves conversation history from localStorage
3. Frontend sends current message + recent conversation context to backend
4. Backend processes with full conversation memory
5. Frontend stores the response and updates localStorage

## API Format

### Request Payload
```json
{
  "query": "What persona was that?",
  "user_id": "joffr02", 
  "conversation_id": "conv_123",
  "context": [
    {"role": "user", "content": "List available personas"},
    {"role": "assistant", "content": "I found ev_skeptic_traditionalists_base persona"}
  ]
}
```

### Context Format
- **role**: `"user"` or `"assistant"`
- **content**: The message text
- **timestamp**: ISO 8601 timestamp (for frontend use)

## Configuration

### Context Window
- **Default**: Last 10 messages (5 exchanges)
- **Configurable**: Can be adjusted in `api_client.dart`
- **Optimization**: Only sends recent messages to keep payload lightweight

### Memory Features
- ✅ **Persistent Conversations**: Stored in browser localStorage
- ✅ **Cross-Session Memory**: Conversations persist across browser sessions
- ✅ **Agent Context**: Backend receives full conversation history
- ✅ **Lightweight**: Only recent messages sent to backend
- ✅ **Serverless Compatible**: No backend storage required

## Testing

### Manual Test Script
Run `test-conversation-memory.ps1` to verify the conversation memory:

```powershell
.\test-conversation-memory.ps1
```

### Integration Test
1. Start backend on port 8000
2. Start frontend: `docker run -p 8080:8080 --env-file .env dynamic-persona-frontend`
3. Open http://localhost:8080
4. Have a multi-message conversation
5. Check browser console for debug logs showing context being sent

## Debug Information

The frontend logs conversation context details to the browser console:
- 🚀 Request URL and query
- 👤 User ID and conversation ID  
- 📚 Number of context messages being sent
- 📖 Preview of latest context message

## Benefits

### For Users
- **Coherent Conversations**: Agent remembers previous messages
- **Natural Interaction**: Can reference earlier parts of conversation
- **Persistent History**: Conversations saved locally

### For Developers  
- **Stateless Backend**: No session storage required
- **Scalable**: Works with serverless Cloud Run
- **Simple**: Minimal complexity added
- **Debuggable**: Clear logging and payload structure

## Limitations

- **Device-Specific**: Conversations only persist on the same browser/device
- **Storage Limits**: Subject to browser localStorage limits (~5-10MB)
- **Network Overhead**: Conversation context sent with each request
- **Context Window**: Only recent messages sent (configurable limit)

## Future Enhancements

- **Cloud Sync**: Store conversations in cloud storage for cross-device access
- **Conversation Summarization**: Compress old conversations for larger context windows
- **Selective Context**: Send only relevant previous messages based on current query
- **Conversation Search**: Search through conversation history