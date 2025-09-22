import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  Map<String, dynamic>? _runtimeConfig;

  /// Get runtime configuration from .env file using flutter_dotenv
  Map<String, dynamic>? getRuntimeConfig() {
    if (_runtimeConfig != null) return _runtimeConfig;

    try {
      // Load configuration from .env file instead of JavaScript
      _runtimeConfig = {
        'APP_PUBLIC_PATH': dotenv.env['APP_PUBLIC_PATH'] ?? '/',
        'BACKEND_BASE_URL': dotenv.env['BACKEND_BASE_URL'] ?? '/api',
        'IAP_MODE': dotenv.env['IAP_MODE']?.toLowerCase() == 'true',
        'IAP_AUDIENCE': dotenv.env['IAP_AUDIENCE'] ?? '',
        'AUTH_MODE': dotenv.env['AUTH_MODE'] ?? 'none', // none, bearer, iap
        'BEARER_TOKEN':
            dotenv.env['BEARER_TOKEN'] ?? '', // For Cloud Run IAM auth
      };
    } catch (e) {
      print('Error loading runtime config: $e');
    }

    return _runtimeConfig;
  }

  /// Get the backend base URL from runtime config
  String get backendBaseUrl {
    final config = getRuntimeConfig();
    return config?['BACKEND_BASE_URL'] ?? '/api';
  }

  /// Check if IAP mode is enabled
  bool get isIapMode {
    final config = getRuntimeConfig();
    return config?['IAP_MODE'] == true;
  }

  /// Send a chat message to the backend with conversation context
  Future<Map<String, dynamic>> sendChatMessage(
    String message,
    String userId, {
    String? conversationId,
    List<Map<String, dynamic>>? conversationHistory,
    int maxHistoryMessages = 10,
  }) async {
    try {
      final url = '$backendBaseUrl/chat';

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add authentication based on configuration
      final config = getRuntimeConfig();
      final authMode = config?['AUTH_MODE'] ?? 'none';
      final bearerToken = config?['BEARER_TOKEN'];
      final authToken = config?['AUTH_TOKEN']; // Legacy support
      final iapMode = config?['IAP_MODE'] == true;

      if (authMode == 'bearer' &&
          bearerToken != null &&
          bearerToken.isNotEmpty) {
        // Use bearer token authentication (preferred for Cloud Run IAM)
        headers['Authorization'] = 'Bearer $bearerToken';
      } else if (authToken != null && authToken.isNotEmpty) {
        // Legacy AUTH_TOKEN support
        headers['Authorization'] = 'Bearer $authToken';
      } else if (iapMode) {
        // For IAP mode, we rely on cookies and don't add Authorization header
        // The browser will automatically include IAP session cookies
      } else {
        // No authentication configured
        print('Warning: No authentication configured for API calls');
      }

      // Prepare conversation history for backend context (recent messages only)
      final limitedHistory =
          conversationHistory != null && conversationHistory.isNotEmpty
              ? conversationHistory.take(maxHistoryMessages).toList()
              : <Map<String, dynamic>>[];

      // Build request payload with conversation context
      final requestPayload = <String, dynamic>{
        'query': message,
        'user_id': userId,
      };

      // Add conversation context if available
      if (conversationId != null) {
        requestPayload['conversation_id'] = conversationId;
      }

      if (limitedHistory.isNotEmpty) {
        requestPayload['context'] = limitedHistory;
      }

      final requestBody = jsonEncode(requestPayload);

      // Debug logging to verify the payload
      print('🚀 Sending chat request to: $url');
      print('📝 Query: $message');
      print('👤 User ID: $userId');
      print(
          '💬 Conversation ID: ${requestPayload['conversation_id'] ?? 'None'}');
      print('📚 Context messages: ${limitedHistory.length}');
      if (limitedHistory.isNotEmpty) {
        final lastContent = limitedHistory.last['content']?.toString() ?? '';
        final preview = lastContent.length > 50
            ? '${lastContent.substring(0, 50)}...'
            : lastContent;
        print('📖 Latest context: $preview');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception(
            'Authentication failed. Please check your token or sign in.');
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden. Check your permissions.');
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest')) {
        // Network/CORS error
        throw Exception(
            'Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.');
      }
      rethrow;
    }
  }

  /// Convert conversation messages to backend-compatible format
  static List<Map<String, dynamic>> formatConversationHistory(
      List<dynamic> messages) {
    return messages
        .map((msg) {
          // Ensure we have the required fields with safe type casting
          final text = msg.text?.toString() ?? '';
          final isUser = msg.isUser == true;
          final timestamp = msg.timestamp?.toIso8601String() ??
              DateTime.now().toIso8601String();

          return {
            'role': isUser ? 'user' : 'assistant',
            'content': text,
            'timestamp': timestamp,
          };
        })
        .where((msg) => (msg['content'] as String).isNotEmpty)
        .toList();
  }

  /// Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile (when using IAP)
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isIapMode) return null;

    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
