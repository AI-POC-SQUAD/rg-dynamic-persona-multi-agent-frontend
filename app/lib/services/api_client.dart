import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/discussion.dart';

class ApiClient {
  static const Duration _httpTimeout = Duration(seconds: 300);
  Map<String, dynamic>? _runtimeConfig;

  /// Get runtime configuration from .env file using flutter_dotenv
  Map<String, dynamic>? getRuntimeConfig() {
    if (_runtimeConfig != null) return _runtimeConfig;

    try {
      // Load configuration from .env file instead of JavaScript
      _runtimeConfig = {
        'APP_PUBLIC_PATH': dotenv.env['APP_PUBLIC_PATH'] ?? '/',
        'BACKEND_BASE_URL': dotenv.env['BACKEND_BASE_URL'] ??
            'https://rg-dynamic-persona-auth-proxy-1036279278510.europe-west9.run.app',
        'IAP_MODE': dotenv.env['IAP_MODE']?.toLowerCase() == 'true',
        'IAP_AUDIENCE': dotenv.env['IAP_AUDIENCE'] ?? '',
        'AUTH_MODE': dotenv.env['AUTH_MODE'] ?? 'none', // none, bearer, iap
        'BEARER_TOKEN':
            dotenv.env['BEARER_TOKEN'] ?? '', // For Cloud Run IAM auth
        'USE_CORS_PROXY': dotenv.env['USE_CORS_PROXY'] ?? 'false',
        'CORS_PROXY_URL':
            dotenv.env['CORS_PROXY_URL'] ?? 'https://cors-anywhere.com',
      };
    } catch (e) {
      print('Error loading runtime config: $e');
    }

    return _runtimeConfig;
  }

  /// Get the backend base URL from runtime config
  String get backendBaseUrl {
    final config = getRuntimeConfig();
    return config?['BACKEND_BASE_URL'] ??
        'https://rg-dynamic-persona-auth-proxy-1036279278510.europe-west9.run.app';
  }

  /// Check if IAP mode is enabled
  bool get isIapMode {
    final config = getRuntimeConfig();
    return config?['IAP_MODE'] == true;
  }

  /// Fetch list of discussions from backend
  Future<List<Discussion>> fetchDiscussions() async {
    try {
      final url = '$backendBaseUrl/discussions';
      final headers = <String, String>{'Content-Type': 'application/json'};

      final config = getRuntimeConfig();
      final authMode = config?['AUTH_MODE'] ?? 'none';
      final bearerToken = config?['BEARER_TOKEN'];
      final authToken = config?['AUTH_TOKEN'];
      final iapMode = config?['IAP_MODE'] == true;

      if (authMode == 'bearer' &&
          bearerToken != null &&
          bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      } else if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      } else if (iapMode) {
        // For IAP mode we let browser cookies handle auth, so no header needed
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Discussion.fromJson)
              .toList();
        }
        throw Exception('Unexpected discussions payload');
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your token or sign in.',
        );
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden. Check your permissions.');
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('Network error')) {
        throw Exception(
          'Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.',
        );
      }
      rethrow;
    }
  }

  /// Get discussion details by ID
  Future<DiscussionDetail> getDiscussion(String discussionId) async {
    try {
      final url = '$backendBaseUrl/get_discussion';
      final headers = <String, String>{'Content-Type': 'application/json'};

      final config = getRuntimeConfig();
      final authMode = config?['AUTH_MODE'] ?? 'none';
      final bearerToken = config?['BEARER_TOKEN'];
      final authToken = config?['AUTH_TOKEN'];
      final iapMode = config?['IAP_MODE'] == true;

      if (authMode == 'bearer' &&
          bearerToken != null &&
          bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      } else if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      } else if (iapMode) {
        // For IAP mode we let browser cookies handle auth, so no header needed
      }

      final requestBody = jsonEncode({'id': discussionId});

      final response = await http
          .post(Uri.parse(url), headers: headers, body: requestBody)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiscussionDetail.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your token or sign in.',
        );
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden. Check your permissions.');
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('Network error')) {
        throw Exception(
          'Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.',
        );
      }
      rethrow;
    }
  }
}
