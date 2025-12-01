import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import '../models/conversation.dart';
import '../models/sse_event.dart';
import 'storage_client.dart';

/// Session information from ADK API
class ADKSession {
  final String id;
  final String appName;
  final String userId;

  const ADKSession({
    required this.id,
    required this.appName,
    required this.userId,
  });

  factory ADKSession.fromJson(Map<String, dynamic> json) {
    return ADKSession(
      id: json['id'] as String,
      appName: json['appName'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'userId': userId,
    };
  }
}

/// Client for the Google ADK API with SSE support and localStorage persistence
class ADKApiClient {
  final String baseUrl;
  final String appName;
  final String userId;
  final StorageClient _storageClient = StorageClient();

  ADKSession? _session;
  Conversation? _conversation;

  ADKApiClient({
    this.baseUrl = 'http://127.0.0.1:8000',
    this.appName = 'corpus_explorer',
    this.userId = 'flutter_user',
  });

  /// Get the current session
  ADKSession? get session => _session;

  /// Check if a session is active
  bool get hasSession => _session != null;

  /// Get the current conversation
  Conversation? get conversation => _conversation;

  /// Get the storage client
  StorageClient get storageClient => _storageClient;

  /// List available apps
  Future<List<String>> listApps() async {
    final response = await http.get(
      Uri.parse('$baseUrl/list-apps'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('Failed to list apps: ${response.statusCode}');
  }

  /// Create a new session for the specified app
  Future<ADKSession> createSession({String? initialTopic}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/apps/$appName/users/$userId/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _session = ADKSession.fromJson(data);

      // Create a new conversation for this session
      _conversation = Conversation.create(
        sessionId: _session!.id,
        appName: appName,
        userId: userId,
        initialTopic: initialTopic ?? 'New conversation',
      );

      // Save the conversation to localStorage
      await _storageClient.saveConversation(_conversation!);
      print('💾 New conversation saved: ${_session!.id}');

      return _session!;
    }
    throw Exception('Failed to create session: ${response.statusCode}');
  }

  /// Restore a session from a previous conversation stored in GCS
  /// Returns true if the conversation was found and restored
  Future<bool> restoreSession(String sessionId) async {
    print('🔄 Attempting to restore session: $sessionId');

    // Try to load the conversation from localStorage
    final conversation = await _storageClient.loadConversation(sessionId);

    if (conversation != null) {
      _conversation = conversation;

      // Create a mock session object (the actual ADK session may not exist anymore)
      _session = ADKSession(
        id: sessionId,
        appName: conversation.appName,
        userId: conversation.userId,
      );

      print('✅ Session restored: $sessionId');
      print('   - Title: ${conversation.title}');
      print('   - Messages: ${conversation.messages.length}');
      return true;
    }

    print('❌ Could not find conversation: $sessionId');
    return false;
  }

  /// Try to reconnect to the ADK backend with an existing session
  /// This is useful when restoring a session and wanting to continue the conversation
  Future<bool> reconnectSession() async {
    if (_session == null) {
      return false;
    }

    try {
      // Try to create a new session with the same app/user
      // (ADK doesn't support session restoration, so we create a new one)
      final response = await http.post(
        Uri.parse('$baseUrl/apps/$appName/users/$userId/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newSession = ADKSession.fromJson(data);

        // Update conversation with new session ID but keep history
        if (_conversation != null) {
          _conversation = _conversation!.copyWith(
            sessionId: newSession.id,
          );
          await _storageClient.saveConversation(_conversation!);
        }

        _session = newSession;
        print('✅ Reconnected to ADK with new session: ${newSession.id}');
        return true;
      }
    } catch (e) {
      print('❌ Failed to reconnect to ADK: $e');
    }
    return false;
  }

  /// Send a message and receive SSE events as a stream (real-time for web)
  Stream<SSEEvent> sendMessageSSE(String message) {
    if (_session == null) {
      throw Exception('No active session. Call createSession() first.');
    }

    final controller = StreamController<SSEEvent>();

    _fetchSSEWithXHR(message, controller);

    return controller.stream;
  }

  /// Use XMLHttpRequest with streaming for real-time SSE on web
  void _fetchSSEWithXHR(
    String message,
    StreamController<SSEEvent> controller,
  ) {
    final body = jsonEncode({
      'app_name': appName,
      'user_id': userId,
      'session_id': _session!.id,
      'new_message': {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    });

    final xhr = html.HttpRequest();
    xhr.open('POST', '$baseUrl/run_sse');
    xhr.setRequestHeader('Content-Type', 'application/json');

    int lastProcessedIndex = 0;
    String buffer = '';

    // Listen for progress events to get streaming data
    xhr.onProgress.listen((event) {
      final responseText = xhr.responseText ?? '';

      // Get only the new data since last progress
      final newData = responseText.substring(lastProcessedIndex);
      lastProcessedIndex = responseText.length;

      buffer += newData;

      // Process complete lines
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex);
        buffer = buffer.substring(newlineIndex + 1);

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              // Debug: print content parts to see thought structure
              final content = json['content'] as Map<String, dynamic>?;
              if (content != null) {
                final parts = content['parts'] as List<dynamic>?;
                if (parts != null && parts.isNotEmpty) {
                  for (var part in parts) {
                    if (part is Map && part['thought'] == true) {
                      print('🧠 RAW THOUGHT: ${(part['text'] as String?)?.substring(0, ((part['text'] as String?)?.length ?? 0).clamp(0, 80))}...');
                    }
                  }
                }
              }
              controller.add(SSEEvent.fromJson(json));
            } catch (e) {
              print('Warning: Could not parse SSE event: $e');
            }
          }
        }
      }
    });

    xhr.onLoad.listen((event) {
      // Process any remaining data in buffer
      if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
        final jsonStr = buffer.substring(6).trim();
        if (jsonStr.isNotEmpty) {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            controller.add(SSEEvent.fromJson(json));
          } catch (e) {
            print('Warning: Could not parse final SSE event: $e');
          }
        }
      }
      controller.close();
    });

    xhr.onError.listen((event) {
      controller.addError(Exception('XHR error: ${xhr.statusText}'));
      controller.close();
    });

    xhr.send(body);
  }

  /// Reset the session
  void resetSession() {
    _session = null;
    _conversation = null;
  }

  // ============================================================
  // CONVERSATION PERSISTENCE METHODS
  // ============================================================

  /// Add a user message to the conversation and save to GCS
  Future<void> addUserMessage(String content) async {
    if (_conversation == null) return;

    final message = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ConversationRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    _conversation = _conversation!.addMessage(message);
    await _storageClient.saveConversation(_conversation!);
    print('💾 User message saved to conversation');
  }

  /// Add an assistant response to the conversation and save to GCS
  Future<void> addAssistantMessage(
    String content, {
    bool hasMindmap = false,
    Map<String, dynamic>? mindmapData,
    List<ConversationEvent>? events,
  }) async {
    if (_conversation == null) return;

    final message = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ConversationRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      hasMindmap: hasMindmap,
      mindmapData: mindmapData,
      events: events,
    );

    _conversation = _conversation!.addMessage(message);
    await _storageClient.saveConversation(_conversation!);
    print('💾 Assistant message saved to conversation');

    // If there's a mindmap, save it separately
    if (hasMindmap && mindmapData != null) {
      await saveMindmap(mindmapData);
    }
  }

  /// Save/update the mindmap for the current conversation
  Future<bool> saveMindmap(Map<String, dynamic> mindmapData) async {
    if (_session == null) return false;

    final success = await _storageClient.saveMindmap(_session!.id, mindmapData);
    if (success) {
      print('🗺️ Mindmap saved for session: ${_session!.id}');
    }
    return success;
  }

  /// Load the mindmap for the current conversation
  Future<Map<String, dynamic>?> loadMindmap() async {
    if (_session == null) return null;
    return await _storageClient.loadMindmap(_session!.id);
  }

  /// Check if a mindmap exists for the current conversation
  Future<bool> hasMindmap() async {
    if (_session == null) return false;
    return await _storageClient.hasMindmap(_session!.id);
  }

  /// List all saved conversations
  Future<List<ConversationSummary>> listConversations() async {
    return await _storageClient.listConversations();
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String sessionId) async {
    return await _storageClient.deleteConversation(sessionId);
  }

  /// Update the conversation title
  Future<void> updateConversationTitle(String newTitle) async {
    if (_conversation == null) return;

    _conversation = _conversation!.copyWith(title: newTitle);
    await _storageClient.saveConversation(_conversation!);
  }
}
