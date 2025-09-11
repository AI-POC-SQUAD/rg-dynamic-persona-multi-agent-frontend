import 'dart:convert';
import 'dart:js' as js;
import 'package:http/http.dart' as http;

class ApiClient {
  Map<String, dynamic>? _runtimeConfig;

  /// Get runtime configuration from window.__RUNTIME_CONFIG__
  Map<String, dynamic>? getRuntimeConfig() {
    if (_runtimeConfig != null) return _runtimeConfig;

    try {
      // Access runtime config from JavaScript using dart:js
      final jsConfig = js.context['__RUNTIME_CONFIG__'];
      if (jsConfig != null) {
        _runtimeConfig = {
          'APP_PUBLIC_PATH': jsConfig['APP_PUBLIC_PATH'] ?? '/',
          'BACKEND_BASE_URL': jsConfig['BACKEND_BASE_URL'] ?? '/api',
          'IAP_MODE': jsConfig['IAP_MODE'] ?? false,
          'IAP_AUDIENCE': jsConfig['IAP_AUDIENCE'] ?? '',
          'AUTH_MODE': jsConfig['AUTH_MODE'] ?? 'none', // none, bearer, iap
          'BEARER_TOKEN': jsConfig['BEARER_TOKEN'] ?? '', // For Cloud Run IAM auth
        };
      }
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

  /// Send a chat message to the backend
  Future<Map<String, dynamic>> sendChatMessage(String message, String userId) async {
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
      
      if (authMode == 'bearer' && bearerToken != null && bearerToken.isNotEmpty) {
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
      
      // Send the message as JSON object expected by the backend
      final requestBody = jsonEncode({
        'query': message,
        'user_id': userId,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please check your token or sign in.');
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden. Check your permissions.');
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest')) {
        // Network/CORS error
        throw Exception('Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.');
      }
      rethrow;
    }
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
