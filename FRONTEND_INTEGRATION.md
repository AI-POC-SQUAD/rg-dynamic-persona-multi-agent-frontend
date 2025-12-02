# Frontend Integration Guide

## API Endpoint

```
https://rg-dynamic-persona-auth-proxy-1036279278510.europe-west4.run.app
```

This proxy handles CORS and IAM authentication automatically. No authentication headers required from the frontend.

---

## Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/list-apps` | GET | List available agents |
| `/run` | POST | Run agent (single response) |
| `/run_sse` | POST | Run agent (streaming SSE) |
| `/apps/{app}/users/{user}/sessions/{session}` | GET/POST/PATCH/DELETE | Session management |
| `/health` | GET | Health check |

---

## Quick Start (Flutter/Dart)

### 1. Configuration

```dart
const String baseUrl = 'https://rg-dynamic-persona-auth-proxy-1036279278510.europe-west4.run.app';
```

### 2. Run Agent (Single Response)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> runAgent(String userMessage) async {
  final response = await http.post(
    Uri.parse('$baseUrl/run'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'app_name': 'corpus_explorer',
      'user_id': 'flutter_user',
      'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
      'new_message': {
        'role': 'user',
        'parts': [{'text': userMessage}]
      }
    }),
  );
  
  return jsonDecode(response.body);
}
```

### 3. Run Agent (Streaming SSE)

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Stream<String> runAgentStream(String userMessage) async* {
  final request = http.Request('POST', Uri.parse('$baseUrl/run_sse'));
  request.headers['Content-Type'] = 'application/json';
  request.body = jsonEncode({
    'app_name': 'corpus_explorer',
    'user_id': 'flutter_user',
    'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
    'new_message': {
      'role': 'user',
      'parts': [{'text': userMessage}]
    }
  });

  final client = http.Client();
  final response = await client.send(request);
  
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    // Parse SSE events
    for (final line in chunk.split('\n')) {
      if (line.startsWith('data: ')) {
        yield line.substring(6);
      }
    }
  }
  
  client.close();
}
```

---

## Request Format

```json
{
  "app_name": "corpus_explorer",
  "user_id": "your_user_id",
  "session_id": "unique_session_id",
  "new_message": {
    "role": "user",
    "parts": [{"text": "Your message here"}]
  }
}
```

---

## Example Queries

| Query | Description |
|-------|-------------|
| `"List all available namespaces"` | Get corpus namespaces |
| `"Search for electric vehicle trends in autoplus namespace"` | Semantic search |
| `"Compare frustrations across autoplus and octane"` | Multi-namespace analysis |
| `"Generate a mindmap of ADAS topics"` | Visual mindmap |

---

## Response Format

### Single Response (`/run`)

```json
{
  "response": {
    "content": {
      "parts": [{"text": "Agent response text"}]
    }
  }
}
```

### Streaming (`/run_sse`)

Server-Sent Events format:
```
data: {"content": {"parts": [{"text": "Chunk 1..."}]}}
data: {"content": {"parts": [{"text": "Chunk 2..."}]}}
```

---

## Session Management

Sessions persist conversation history. Use consistent `user_id` + `session_id` for multi-turn conversations.

```dart
// Create/get session
final session = await http.get(
  Uri.parse('$baseUrl/apps/corpus_explorer/users/user123/sessions/chat_001'),
);

// Delete session (clear history)
await http.delete(
  Uri.parse('$baseUrl/apps/corpus_explorer/users/user123/sessions/chat_001'),
);
```

---

## Architecture

```
Flutter App  →  Auth Proxy (CORS)  →  Corpus Explorer Agent
                europe-west4           europe-west4
```

The auth-proxy:
- Adds CORS headers for browser/Flutter web requests
- Handles GCP IAM authentication to the backend
- Proxies all requests transparently
