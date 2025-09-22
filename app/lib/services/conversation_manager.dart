import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

class ConversationManager {
  static const String _storageKey = 'rg_dynamic_persona_conversations';
  static const String _currentConversationKey =
      'rg_dynamic_persona_current_conversation';

  List<Conversation> _conversations = [];
  String? _currentConversationId;
  SharedPreferences? _prefs;

  ConversationManager() {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConversations();
  }

  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  String? get currentConversationId => _currentConversationId;

  Conversation? get currentConversation {
    if (_currentConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _currentConversationId);
    } catch (e) {
      return null;
    }
  }

  // Create a new conversation
  Future<Conversation> createConversation({String? title}) async {
    final conversation = Conversation.create(
      title ?? 'New Conversation ${_conversations.length + 1}',
    );

    _conversations.add(conversation);
    _currentConversationId = conversation.id;
    await _saveConversations();

    return conversation;
  }

  // Switch to a conversation
  Future<void> switchToConversation(String conversationId) async {
    if (_conversations.any((c) => c.id == conversationId)) {
      _currentConversationId = conversationId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentConversationKey, conversationId);
    }
  }

  // Add a message to the current conversation
  Future<void> addMessageToCurrentConversation(ChatMessage message) async {
    final conversation = currentConversation;
    if (conversation != null) {
      final updatedMessages = List<ChatMessage>.from(conversation.messages);
      updatedMessages.add(message);

      final updatedConversation = conversation.copyWith(
        messages: updatedMessages,
        lastMessageAt: message.timestamp,
      );

      await _updateConversation(updatedConversation);
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle(
      String conversationId, String newTitle) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(title: newTitle);
      await _saveConversations();
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);

    // If we deleted the current conversation, switch to the most recent one
    if (_currentConversationId == conversationId) {
      if (_conversations.isNotEmpty) {
        _currentConversationId = _conversations
            .reduce((a, b) => a.lastMessageAt.isAfter(b.lastMessageAt) ? a : b)
            .id;
      } else {
        _currentConversationId = null;
      }
    }

    await _saveConversations();
  }

  // Get user ID for current conversation
  String? getCurrentUserId() {
    return currentConversation?.userId;
  }

  // Private methods
  Future<void> _updateConversation(Conversation updatedConversation) async {
    final index =
        _conversations.indexWhere((c) => c.id == updatedConversation.id);
    if (index != -1) {
      _conversations[index] = updatedConversation;
      await _saveConversations();
    }
  }

  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null) {
        final List<dynamic> jsonData = jsonDecode(stored);
        _conversations =
            jsonData.map((json) => Conversation.fromJson(json)).toList();

        // Sort by last message time, most recent first
        _conversations
            .sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }

      // Load current conversation ID
      _currentConversationId = prefs.getString(_currentConversationKey);

      // If no current conversation but conversations exist, select the most recent
      if (_currentConversationId == null && _conversations.isNotEmpty) {
        _currentConversationId = _conversations.first.id;
      }

      // If current conversation doesn't exist in the list, reset it
      if (_currentConversationId != null &&
          !_conversations.any((c) => c.id == _currentConversationId)) {
        _currentConversationId =
            _conversations.isNotEmpty ? _conversations.first.id : null;
      }
    } catch (e) {
      print('Error loading conversations: $e');
      _conversations = [];
      _currentConversationId = null;
    }
  }

  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonData));

      if (_currentConversationId != null) {
        await prefs.setString(_currentConversationKey, _currentConversationId!);
      } else {
        await prefs.remove(_currentConversationKey);
      }
    } catch (e) {
      print('Error saving conversations: $e');
    }
  }

  // Clear all conversations (for debugging/reset)
  Future<void> clearAllConversations() async {
    _conversations.clear();
    _currentConversationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_currentConversationKey);
  }
}
