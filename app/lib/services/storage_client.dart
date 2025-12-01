import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/conversation.dart';

/// Storage client that uses browser localStorage for persistence
/// This works for local development without any authentication
/// Data persists across browser sessions
class StorageClient {
  static const String _conversationsKey = 'corpus_explorer_conversations';
  static const String _mindmapsKey = 'corpus_explorer_mindmaps';

  html.Storage get _localStorage => html.window.localStorage;

  // ============================================================
  // CONVERSATION OPERATIONS
  // ============================================================

  /// Save a conversation to localStorage
  Future<bool> saveConversation(Conversation conversation) async {
    try {
      final conversations = _getAllConversationsMap();
      conversations[conversation.sessionId] = conversation.toJson();
      _localStorage[_conversationsKey] = jsonEncode(conversations);
      print('💾 Conversation saved to localStorage: ${conversation.sessionId}');
      return true;
    } catch (e) {
      print('❌ Error saving conversation: $e');
      return false;
    }
  }

  /// Load a conversation from localStorage by session ID
  Future<Conversation?> loadConversation(String sessionId) async {
    try {
      final conversations = _getAllConversationsMap();
      final data = conversations[sessionId];
      if (data != null) {
        print('📂 Conversation loaded from localStorage: $sessionId');
        return Conversation.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error loading conversation: $e');
      return null;
    }
  }

  /// List all available conversations from localStorage
  Future<List<ConversationSummary>> listConversations() async {
    try {
      final conversations = _getAllConversationsMap();
      final summaries = <ConversationSummary>[];

      for (final entry in conversations.entries) {
        try {
          final data = entry.value as Map<String, dynamic>;
          final conversation = Conversation.fromJson(data);
          final hasMindmapFlag = await hasMindmap(conversation.sessionId);

          summaries.add(ConversationSummary(
            sessionId: conversation.sessionId,
            title: conversation.title,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            messageCount: conversation.messages.length,
            hasMindmap: hasMindmapFlag,
          ));
        } catch (e) {
          print('⚠️ Error parsing conversation ${entry.key}: $e');
        }
      }

      // Sort by updated date, most recent first
      summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      print('📚 Listed ${summaries.length} conversations from localStorage');
      return summaries;
    } catch (e) {
      print('❌ Error listing conversations: $e');
      return [];
    }
  }

  /// Delete a conversation and its associated mindmap
  Future<bool> deleteConversation(String sessionId) async {
    try {
      // Delete conversation
      final conversations = _getAllConversationsMap();
      conversations.remove(sessionId);
      _localStorage[_conversationsKey] = jsonEncode(conversations);

      // Delete mindmap
      final mindmaps = _getAllMindmapsMap();
      mindmaps.remove(sessionId);
      _localStorage[_mindmapsKey] = jsonEncode(mindmaps);

      print('🗑️ Conversation deleted: $sessionId');
      return true;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }

  // ============================================================
  // MINDMAP OPERATIONS
  // ============================================================

  /// Save a mindmap to localStorage for a specific conversation
  Future<bool> saveMindmap(
    String sessionId,
    Map<String, dynamic> mindmapData,
  ) async {
    try {
      final mindmaps = _getAllMindmapsMap();
      mindmaps[sessionId] = {
        'sessionId': sessionId,
        'mindmap': mindmapData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _localStorage[_mindmapsKey] = jsonEncode(mindmaps);
      print('🗺️ Mindmap saved to localStorage: $sessionId');
      return true;
    } catch (e) {
      print('❌ Error saving mindmap: $e');
      return false;
    }
  }

  /// Load a mindmap from localStorage for a specific conversation
  Future<Map<String, dynamic>?> loadMindmap(String sessionId) async {
    try {
      final mindmaps = _getAllMindmapsMap();
      final data = mindmaps[sessionId] as Map<String, dynamic>?;
      if (data != null) {
        print('🗺️ Mindmap loaded from localStorage: $sessionId');
        return data['mindmap'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ Error loading mindmap: $e');
      return null;
    }
  }

  /// Check if a mindmap exists for a conversation
  Future<bool> hasMindmap(String sessionId) async {
    try {
      final mindmaps = _getAllMindmapsMap();
      return mindmaps.containsKey(sessionId);
    } catch (e) {
      return false;
    }
  }

  /// Get mindmap metadata (last updated time)
  Future<DateTime?> getMindmapLastUpdated(String sessionId) async {
    try {
      final mindmaps = _getAllMindmapsMap();
      final data = mindmaps[sessionId] as Map<String, dynamic>?;
      if (data != null) {
        final updatedAt = data['updatedAt'] as String?;
        if (updatedAt != null) {
          return DateTime.parse(updatedAt);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get all conversations as a map
  Map<String, dynamic> _getAllConversationsMap() {
    final stored = _localStorage[_conversationsKey];
    if (stored == null || stored.isEmpty) {
      return {};
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(stored));
    } catch (e) {
      print('⚠️ Error parsing stored conversations, resetting...');
      return {};
    }
  }

  /// Get all mindmaps as a map
  Map<String, dynamic> _getAllMindmapsMap() {
    final stored = _localStorage[_mindmapsKey];
    if (stored == null || stored.isEmpty) {
      return {};
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(stored));
    } catch (e) {
      print('⚠️ Error parsing stored mindmaps, resetting...');
      return {};
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Clear all stored data (for debugging)
  void clearAll() {
    _localStorage.remove(_conversationsKey);
    _localStorage.remove(_mindmapsKey);
    print('🧹 All storage cleared');
  }

  /// Export all data as JSON (for backup)
  String exportData() {
    return jsonEncode({
      'conversations': _getAllConversationsMap(),
      'mindmaps': _getAllMindmapsMap(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Import data from JSON (for restore)
  bool importData(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      if (data.containsKey('conversations')) {
        _localStorage[_conversationsKey] = jsonEncode(data['conversations']);
      }
      if (data.containsKey('mindmaps')) {
        _localStorage[_mindmapsKey] = jsonEncode(data['mindmaps']);
      }
      print('📥 Data imported successfully');
      return true;
    } catch (e) {
      print('❌ Error importing data: $e');
      return false;
    }
  }

  /// Get storage usage info
  Map<String, int> getStorageInfo() {
    final convSize = (_localStorage[_conversationsKey] ?? '').length;
    final mindmapSize = (_localStorage[_mindmapsKey] ?? '').length;
    return {
      'conversationsBytes': convSize,
      'mindmapsBytes': mindmapSize,
      'totalBytes': convSize + mindmapSize,
    };
  }
}
