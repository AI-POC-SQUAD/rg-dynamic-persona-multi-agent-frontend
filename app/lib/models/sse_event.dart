/// Represents a parsed SSE event from the ADK API
class SSEEvent {
  final String id;
  final String author;
  final String invocationId;
  final DateTime timestamp;
  final SSEContent content;
  final String? finishReason;
  final List<String> longRunningToolIds;

  const SSEEvent({
    required this.id,
    required this.author,
    required this.invocationId,
    required this.timestamp,
    required this.content,
    this.finishReason,
    this.longRunningToolIds = const [],
  });

  factory SSEEvent.fromJson(Map<String, dynamic> json) {
    return SSEEvent(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      invocationId: json['invocationId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((json['timestamp'] as num) * 1000).toInt())
          : DateTime.now(),
      content: SSEContent.fromJson(json['content'] as Map<String, dynamic>),
      finishReason: json['finishReason'] as String?,
      longRunningToolIds: (json['longRunningToolIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Represents the content of an SSE event
class SSEContent {
  final String role;
  final List<SSEPart> parts;

  const SSEContent({
    required this.role,
    required this.parts,
  });

  factory SSEContent.fromJson(Map<String, dynamic> json) {
    return SSEContent(
      role: json['role'] as String? ?? '',
      parts: (json['parts'] as List<dynamic>?)
              ?.map((part) => SSEPart.fromJson(part as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Check if this content contains thinking/COT
  bool get hasThought => parts.any((part) => part.isThought);

  /// Check if this content contains a function call
  bool get hasFunctionCall => parts.any((part) => part.functionCall != null);

  /// Check if this content contains a function response
  bool get hasFunctionResponse =>
      parts.any((part) => part.functionResponse != null);

  /// Get the main text (non-thinking)
  String get mainText => parts
      .where((part) => !part.isThought && part.text != null)
      .map((part) => part.text!)
      .join('\n');

  /// Get thinking text
  String get thoughtText => parts
      .where((part) => part.isThought && part.text != null)
      .map((part) => part.text!)
      .join('\n');
}

/// Represents a part of the SSE content
class SSEPart {
  final String? text;
  final bool isThought;
  final String? thoughtSignature;
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;

  const SSEPart({
    this.text,
    this.isThought = false,
    this.thoughtSignature,
    this.functionCall,
    this.functionResponse,
  });

  factory SSEPart.fromJson(Map<String, dynamic> json) {
    return SSEPart(
      text: json['text'] as String?,
      isThought: json['thought'] as bool? ?? false,
      thoughtSignature: json['thoughtSignature'] as String?,
      functionCall: json['functionCall'] != null
          ? FunctionCall.fromJson(json['functionCall'] as Map<String, dynamic>)
          : null,
      functionResponse: json['functionResponse'] != null
          ? FunctionResponse.fromJson(
              json['functionResponse'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Represents a function call in the SSE event
class FunctionCall {
  final String id;
  final String name;
  final Map<String, dynamic> args;

  const FunctionCall({
    required this.id,
    required this.name,
    required this.args,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      args: json['args'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Represents a function response in the SSE event
class FunctionResponse {
  final String id;
  final String name;
  final String response;

  const FunctionResponse({
    required this.id,
    required this.name,
    required this.response,
  });

  factory FunctionResponse.fromJson(Map<String, dynamic> json) {
    return FunctionResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      response: json['response']?['result'] as String? ?? '',
    );
  }
}

/// Enum to categorize the type of SSE event for display purposes
enum SSEEventType {
  thinking,
  functionCall,
  functionResponse,
  finalResponse,
  unknown,
}

/// Extension to get the event type
extension SSEEventTypeExtension on SSEEvent {
  SSEEventType get eventType {
    if (content.hasThought && !content.hasFunctionCall) {
      return SSEEventType.thinking;
    } else if (content.hasFunctionCall) {
      return SSEEventType.functionCall;
    } else if (content.hasFunctionResponse) {
      return SSEEventType.functionResponse;
    } else if (content.mainText.isNotEmpty) {
      return SSEEventType.finalResponse;
    }
    return SSEEventType.unknown;
  }
}
