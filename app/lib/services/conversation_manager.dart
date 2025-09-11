import 'dart:convert';
import 'dart:html' as html;
import '../models/conversation.dart';

class ConversationManager {
  static const String _storageKey = 'rg_dynamic_persona_conversations';
  static const String _currentConversationKey = 'rg_dynamic_persona_current_conversation';
  
  List<Conversation> _conversations = [];
  String? _currentConversationId;

  ConversationManager() {
    _loadConversations();
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
  Conversation createConversation({String? title}) {
    final conversation = Conversation.create(
      title ?? 'New Conversation ${_conversations.length + 1}',
    );
    
    _conversations.add(conversation);
    _currentConversationId = conversation.id;
    _saveConversations();
    
    return conversation;
  }

  // Switch to a conversation
  void switchToConversation(String conversationId) {
    if (_conversations.any((c) => c.id == conversationId)) {
      _currentConversationId = conversationId;
      html.window.localStorage[_currentConversationKey] = conversationId;
    }
  }

  // Add a message to the current conversation
  void addMessageToCurrentConversation(ChatMessage message) {
    final conversation = currentConversation;
    if (conversation != null) {
      final updatedMessages = List<ChatMessage>.from(conversation.messages);
      updatedMessages.add(message);
      
      final updatedConversation = conversation.copyWith(
        messages: updatedMessages,
        lastMessageAt: message.timestamp,
      );
      
      _updateConversation(updatedConversation);
    }
  }

  // Update conversation title
  void updateConversationTitle(String conversationId, String newTitle) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(title: newTitle);
      _saveConversations();
    }
  }

  // Delete a conversation
  void deleteConversation(String conversationId) {
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
    
    _saveConversations();
  }

  // Get user ID for current conversation
  String? getCurrentUserId() {
    return currentConversation?.userId;
  }

  // Private methods
  void _updateConversation(Conversation updatedConversation) {
    final index = _conversations.indexWhere((c) => c.id == updatedConversation.id);
    if (index != -1) {
      _conversations[index] = updatedConversation;
      _saveConversations();
    }
  }

  void _loadConversations() {
    try {
      final stored = html.window.localStorage[_storageKey];
      if (stored != null) {
        final List<dynamic> jsonData = jsonDecode(stored);
        _conversations = jsonData.map((json) => Conversation.fromJson(json)).toList();
        
        // Sort by last message time, most recent first
        _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }
      
      // Load current conversation ID
      _currentConversationId = html.window.localStorage[_currentConversationKey];
      
      // If no current conversation but conversations exist, select the most recent
      if (_currentConversationId == null && _conversations.isNotEmpty) {
        _currentConversationId = _conversations.first.id;
      }
      
      // If current conversation doesn't exist in the list, reset it
      if (_currentConversationId != null && 
          !_conversations.any((c) => c.id == _currentConversationId)) {
        _currentConversationId = _conversations.isNotEmpty ? _conversations.first.id : null;
      }
    } catch (e) {
      print('Error loading conversations: $e');
      _conversations = [];
      _currentConversationId = null;
    }
  }

  void _saveConversations() {
    try {
      final jsonData = _conversations.map((c) => c.toJson()).toList();
      html.window.localStorage[_storageKey] = jsonEncode(jsonData);
      
      if (_currentConversationId != null) {
        html.window.localStorage[_currentConversationKey] = _currentConversationId!;
      } else {
        html.window.localStorage.remove(_currentConversationKey);
      }
    } catch (e) {
      print('Error saving conversations: $e');
    }
  }

  // Clear all conversations (for debugging/reset)
  void clearAllConversations() {
    _conversations.clear();
    _currentConversationId = null;
    html.window.localStorage.remove(_storageKey);
    html.window.localStorage.remove(_currentConversationKey);
  }
}
