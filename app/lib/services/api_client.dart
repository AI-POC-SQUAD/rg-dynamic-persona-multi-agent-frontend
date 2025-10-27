import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/persona_data.dart';

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

  /// Get the backend URL with CORS proxy if enabled (for development)
  String get _getApiUrl {
    final config = getRuntimeConfig();
    final useCorsProxy =
        config?['USE_CORS_PROXY']?.toString().toLowerCase() == 'true';
    final corsProxyUrl =
        config?['CORS_PROXY_URL'] ?? 'https://cors-anywhere.com';
    final backendUrl = backendBaseUrl;

    if (useCorsProxy) {
      print('🔄 Using CORS proxy: $corsProxyUrl$backendUrl');
      return '$corsProxyUrl$backendUrl';
    }

    return backendUrl;
  }

  /// Check if IAP mode is enabled
  bool get isIapMode {
    final config = getRuntimeConfig();
    return config?['IAP_MODE'] == true;
  }

  /// Fetch personas from backend
  Future<List<PersonaData>> fetchPersonas() async {
    try {
      final url = '${_getApiUrl}/personas';
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

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
              .map(PersonaData.fromJson)
              .toList();
        }
        throw Exception('Unexpected personas payload');
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
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('Network error')) {
        throw Exception(
            'Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.');
      }
      rethrow;
    }
  }

  /// Start a focus group discussion with multiple personas
  Future<Map<String, dynamic>> startFocusGroup(
    String userId,
    String topic,
    List<Map<String, dynamic>> profiles,
    int maxRounds, {
    String domain = "Electric Vehicles",
    bool enableIterativeDiscussion = true,
    int timeoutSeconds = 300,
  }) async {
    try {
      final url = '${_getApiUrl}/panel-discussion';

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
        headers['Authorization'] = 'Bearer $bearerToken';
      } else if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      } else if (iapMode) {
        print('Using IAP mode for authentication');
      }

      // Ensure profiles have the correct threshold value (25.0 by default)
      final profilesWithThreshold = profiles.map((profile) {
        final updatedProfile = Map<String, dynamic>.from(profile);
        if (!updatedProfile.containsKey('threshold')) {
          updatedProfile['threshold'] = 20.0;
        }
        return updatedProfile;
      }).toList();

      // Build request payload following the specified format
      final requestPayload = <String, dynamic>{
        'user_id': userId,
        'idea': topic,
        'domain': domain,
        'profiles': profilesWithThreshold,
        'max_discussion_rounds': maxRounds,
        'enable_iterative_discussion': enableIterativeDiscussion,
        'timeout_seconds': timeoutSeconds,
      };

      final requestBody = jsonEncode(requestPayload);

      // Debug logging
      print('🚀 Starting focus group');
      print('🎯 Topic: $topic');
      print('👥 Profiles: ${profilesWithThreshold.length}');
      print('🔄 Max rounds: $maxRounds');
      print('📡 URL: $url');
      for (int i = 0; i < profilesWithThreshold.length; i++) {
        final profile = profilesWithThreshold[i];
        print(
            '👤 Profile ${i + 1}: ${profile['name']} (housing: ${profile['housing_condition']}, income: ${profile['income']}, age: ${profile['age']}, population: ${profile['population']}, threshold: ${profile['threshold']})');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Focus group started successfully');
        print('📊 Request ID: ${responseData['request_id']}');
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
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('Network error')) {
        throw Exception(
            'Network error. Check your connection and backend URL.\nCORS might need to be configured on the backend.');
      }
      print('❌ Error starting focus group: $e');
      rethrow;
    }
  }

  /// Build a profile object from persona instance data for focus group API
  static Map<String, dynamic> buildFocusGroupProfile(
    String personaName,
    int housingCondition,
    int income,
    int age,
    int population, {
    String gender = 'male',
    double threshold = 20.0,
  }) {
    return {
      'name': personaName,
      'housing_condition': housingCondition,
      'income': income,
      'age': age,
      'population': population,
      'gender': gender,
      'threshold': threshold,
    };
  }
}
