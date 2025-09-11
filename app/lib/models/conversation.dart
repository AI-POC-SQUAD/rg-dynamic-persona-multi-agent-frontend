import 'package:uuid/uuid.dart';

class Conversation {
  final String id;
  final String title;
  final String userId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
  });

  factory Conversation.create(String title) {
    final uuid = const Uuid();
    final id = uuid.v4();
    final userId = 'user_${id.substring(0, 8)}';
    final now = DateTime.now();
    
    return Conversation(
      id: id,
      title: title,
      userId: userId,
      createdAt: now,
      lastMessageAt: now,
      messages: [],
    );
  }

  Conversation copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      userId: userId,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? sessionId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'sessionId': sessionId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      isError: json['isError'] ?? false,
      sessionId: json['sessionId'],
    );
  }
}
