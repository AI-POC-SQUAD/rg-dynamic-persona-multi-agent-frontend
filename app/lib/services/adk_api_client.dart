import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import '../models/sse_event.dart';

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
}

/// Client for the Google ADK API with SSE support
class ADKApiClient {
  final String baseUrl;
  final String appName;
  final String userId;

  ADKSession? _session;

  ADKApiClient({
    this.baseUrl = 'http://127.0.0.1:8000',
    this.appName = 'corpus_explorer',
    this.userId = 'flutter_user',
  });

  /// Get the current session
  ADKSession? get session => _session;

  /// Check if a session is active
  bool get hasSession => _session != null;

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
  Future<ADKSession> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/apps/$appName/users/$userId/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _session = ADKSession.fromJson(data);
      return _session!;
    }
    throw Exception('Failed to create session: ${response.statusCode}');
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
  }
}
