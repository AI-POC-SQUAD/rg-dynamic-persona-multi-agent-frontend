/// Represents a full conversation with an ADK agent
/// Stored in localStorage (dev) or cloud storage (prod)
class Conversation {
  final String sessionId;
  final String appName;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.sessionId,
    required this.appName,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.metadata,
  });

  /// Create a new conversation for a fresh session
  factory Conversation.create({
    required String sessionId,
    required String appName,
    required String userId,
    required String initialTopic,
  }) {
    final now = DateTime.now();
    return Conversation(
      sessionId: sessionId,
      appName: appName,
      userId: userId,
      title: _generateTitle(initialTopic),
      createdAt: now,
      updatedAt: now,
      messages: [],
      metadata: {},
    );
  }

  /// Generate a title from the initial topic (first 50 chars)
  static String _generateTitle(String topic) {
    final cleaned = topic.trim();
    if (cleaned.length <= 50) return cleaned;
    return '${cleaned.substring(0, 47)}...';
  }

  /// Create a copy with updated messages
  Conversation copyWith({
    String? sessionId,
    String? appName,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      sessionId: sessionId ?? this.sessionId,
      appName: appName ?? this.appName,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Add a new message to the conversation
  Conversation addMessage(ConversationMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Add multiple messages at once
  Conversation addMessages(List<ConversationMessage> newMessages) {
    return copyWith(
      messages: [...messages, ...newMessages],
      updatedAt: DateTime.now(),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      sessionId: json['sessionId'] as String,
      appName: json['appName'] as String? ?? 'corpus_explorer',
      userId: json['userId'] as String? ?? 'flutter_user',
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) =>
                  ConversationMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'appName': appName,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Represents a single message in a conversation
class ConversationMessage {
  final String id;
  final ConversationRole role;
  final String content;
  final DateTime timestamp;
  final bool hasMindmap;
  final Map<String, dynamic>? mindmapData;
  final List<ConversationEvent>? events;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.hasMindmap = false,
    this.mindmapData,
    this.events,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      role: ConversationRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ConversationRole.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hasMindmap: json['hasMindmap'] as bool? ?? false,
      mindmapData: json['mindmapData'] as Map<String, dynamic>?,
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => ConversationEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'hasMindmap': hasMindmap,
      if (mindmapData != null) 'mindmapData': mindmapData,
      if (events != null) 'events': events!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Role in the conversation
enum ConversationRole {
  user,
  assistant,
  system,
}

/// Represents an event during message processing (thinking, tool calls, etc.)
class ConversationEvent {
  final String type;
  final String? name;
  final String? content;
  final DateTime timestamp;

  const ConversationEvent({
    required this.type,
    this.name,
    this.content,
    required this.timestamp,
  });

  factory ConversationEvent.fromJson(Map<String, dynamic> json) {
    return ConversationEvent(
      type: json['type'] as String,
      name: json['name'] as String?,
      content: json['content'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (name != null) 'name': name,
      if (content != null) 'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Summary of a conversation for listing purposes
class ConversationSummary {
  final String sessionId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool hasMindmap;

  const ConversationSummary({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.hasMindmap,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messageCount: json['messageCount'] as int? ?? 0,
      hasMindmap: json['hasMindmap'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messageCount': messageCount,
      'hasMindmap': hasMindmap,
    };
  }

  /// Format the time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    }
  }
}
