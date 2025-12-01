import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';
import '../models/conversation.dart';
import '../models/sse_event.dart';
import '../services/adk_api_client.dart';

class FocusAnswersPage extends StatefulWidget {
  final String topic;
  final ADKApiClient adkClient;
  final bool isRestoredSession;

  const FocusAnswersPage({
    super.key,
    required this.topic,
    required this.adkClient,
    this.isRestoredSession = false,
  });

  @override
  State<FocusAnswersPage> createState() => _FocusAnswersPageState();
}

class _FocusAnswersPageState extends State<FocusAnswersPage>
    with TickerProviderStateMixin {
  int _currentTab = 0; // 0: Response, 1: Mindmap
  bool _isLoading = true;
  String? _error;

  // SSE events
  final List<SSEEvent> _events = [];
  StreamSubscription<SSEEvent>? _sseSubscription;

  // Extracted data
  String _finalResponse = '';
  Map<String, dynamic>? _mindmapData;

  // Chat input controller
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();

  // Conversation history for display
  final List<ChatMessage> _chatHistory = [];

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();

  // Breathing animation controller
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize breathing animation
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFBF046B),
          end: const Color(0xFFF26716),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFF26716),
          end: const Color(0xFFBF046B),
        ),
        weight: 50,
      ),
    ]).animate(_breathingController);

    // If this is a restored session, load the conversation history
    if (widget.isRestoredSession) {
      _loadRestoredConversation();
    } else {
      _startExploration();
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _breathingController.dispose();
    _scrollController.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  /// Load conversation history from a restored session
  Future<void> _loadRestoredConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversation = widget.adkClient.conversation;
      if (conversation != null) {
        // Restore chat history from saved messages
        for (final message in conversation.messages) {
          _chatHistory.add(ChatMessage(
            role: message.role == ConversationRole.user
                ? MessageRole.user
                : MessageRole.assistant,
            content: message.content,
            timestamp: message.timestamp,
            hasMindmap: message.hasMindmap,
          ));

          // If the last assistant message has a mindmap, set it
          if (message.role == ConversationRole.assistant &&
              message.hasMindmap &&
              message.mindmapData != null) {
            _mindmapData = message.mindmapData;
          }
        }

        // Also try to load the latest mindmap from storage if not already set
        if (_mindmapData == null) {
          final storedMindmap = await widget.adkClient.loadMindmap();
          if (storedMindmap != null) {
            _mindmapData = storedMindmap;
            print('🗺️ Mindmap loaded from storage');
          }
        }

        print(
            '✅ Restored ${_chatHistory.length} messages from conversation');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversation: $e';
        _isLoading = false;
      });
    }
  }

  /// Start the SSE exploration with initial topic
  Future<void> _startExploration() async {
    // Add initial query to chat history
    _chatHistory.add(ChatMessage(
      role: MessageRole.user,
      content: widget.topic,
      timestamp: DateTime.now(),
    ));

    // Save user message to storage
    await widget.adkClient.addUserMessage(widget.topic);

    await _sendMessage(widget.topic);
  }

  /// Send a new message to continue the conversation
  Future<void> _sendMessage(String message) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _events.clear();
      _finalResponse = '';
      // Don't clear mindmap data - we want to keep the previous one until a new one arrives
    });

    // Start breathing animation
    _breathingController.repeat();

    // Collect events for saving
    final collectedEvents = <ConversationEvent>[];

    try {
      final stream = widget.adkClient.sendMessageSSE(message);

      _sseSubscription = stream.listen(
        (event) {
          if (!mounted) return;

          setState(() {
            _events.add(event);
          });

          // Collect events for persistence
          _collectEventForPersistence(event, collectedEvents);

          // Extract final response and mindmap
          _processEvent(event);

          // Auto-scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
          _breathingController.stop();
        },
        onDone: () async {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          _breathingController.stop();

          // Add assistant response to chat history
          if (_finalResponse.isNotEmpty) {
            _chatHistory.add(ChatMessage(
              role: MessageRole.assistant,
              content: _finalResponse,
              timestamp: DateTime.now(),
              hasMindmap: _mindmapData != null,
            ));

            // Save assistant message to storage with mindmap if present
            await widget.adkClient.addAssistantMessage(
              _finalResponse,
              hasMindmap: _mindmapData != null,
              mindmapData: _mindmapData,
              events: collectedEvents,
            );

            // If there's a mindmap, save it separately to storage
            if (_mindmapData != null) {
              await widget.adkClient.saveMindmap(_mindmapData!);
              print('🗺️ Mindmap saved to storage');
            }
          }
          print('✅ SSE stream completed and conversation saved');
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _breathingController.stop();
    }
  }

  /// Collect SSE events for persistence
  void _collectEventForPersistence(
    SSEEvent event,
    List<ConversationEvent> events,
  ) {
    final eventType = event.eventType;
    String type;
    String? name;
    String? content;

    switch (eventType) {
      case SSEEventType.thinking:
        type = 'thinking';
        content = event.content.thoughtText;
        break;
      case SSEEventType.functionCall:
        type = 'function_call';
        final funcCall = event.content.parts
            .firstWhere((p) => p.functionCall != null)
            .functionCall;
        name = funcCall?.name;
        content = jsonEncode(funcCall?.args ?? {});
        break;
      case SSEEventType.functionResponse:
        type = 'function_response';
        final funcResp = event.content.parts
            .firstWhere((p) => p.functionResponse != null)
            .functionResponse;
        name = funcResp?.name;
        content = funcResp?.response;
        break;
      default:
        return; // Don't save unknown or final response events
    }

    events.add(ConversationEvent(
      type: type,
      name: name,
      content: content,
      timestamp: event.timestamp,
    ));
  }

  /// Handle sending a follow-up message
  void _handleSendMessage() {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message to history
    _chatHistory.add(ChatMessage(
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now(),
    ));

    // Save user message to storage
    widget.adkClient.addUserMessage(message);

    // Clear input
    _chatController.clear();

    // Send message
    _sendMessage(message);
  }

  /// Process an SSE event to extract response and mindmap
  void _processEvent(SSEEvent event) {
    // Debug: Log all events to understand what's coming
    print('📨 SSE Event: type=${event.eventType}, role=${event.content.role}');
    print('   hasThought=${event.content.hasThought}, hasFunctionCall=${event.content.hasFunctionCall}');
    if (event.content.hasThought) {
      print('   💭 Thought: ${event.content.thoughtText.substring(0, event.content.thoughtText.length.clamp(0, 100))}...');
    }
    
    // Check for final response (non-thinking text from model)
    if (event.content.role == 'model' && event.content.mainText.isNotEmpty) {
      _finalResponse = event.content.mainText;

      // Try to extract mindmap from the response
      _extractMindmap(_finalResponse);
    }
  }

  /// Extract mindmap JSON from the response
  void _extractMindmap(String text) {
    print('🔍 Searching for mindmap in response (${text.length} chars)...');

    // Look for JSON block in the response
    final jsonPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = jsonPattern.firstMatch(text);

    if (match != null) {
      try {
        final jsonStr = match.group(1)!;
        print('📦 Found JSON block (${jsonStr.length} chars)');
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Check if it has mindmap structure directly or nested
        if (parsed.containsKey('mindmap')) {
          final mindmapObj = parsed['mindmap'] as Map<String, dynamic>;
          setState(() {
            // Store the full mindmap object with nodes and edges
            _mindmapData = mindmapObj;
          });
          print(
              '✅ Mindmap extracted successfully (nodes: ${mindmapObj['nodes']?.length}, edges: ${mindmapObj['edges']?.length})');
        } else if (parsed.containsKey('nodes') && parsed.containsKey('edges')) {
          // Direct mindmap format without wrapper
          setState(() {
            _mindmapData = parsed;
          });
          print(
              '✅ Direct mindmap format extracted (nodes: ${parsed['nodes']?.length}, edges: ${parsed['edges']?.length})');
        } else {
          print(
              '⚠️ JSON found but no mindmap structure (keys: ${parsed.keys.join(", ")})');
        }
      } catch (e) {
        print('⚠️ Failed to parse mindmap JSON: $e');
      }
    } else {
      // Try to find raw JSON without markdown code block
      try {
        final startIdx = text.indexOf('{');
        final endIdx = text.lastIndexOf('}');
        if (startIdx != -1 && endIdx > startIdx) {
          final jsonCandidate = text.substring(startIdx, endIdx + 1);
          final parsed = jsonDecode(jsonCandidate) as Map<String, dynamic>;
          if (parsed.containsKey('mindmap') ||
              (parsed.containsKey('nodes') && parsed.containsKey('edges'))) {
            final mindmapObj = parsed.containsKey('mindmap')
                ? parsed['mindmap'] as Map<String, dynamic>
                : parsed;
            setState(() {
              _mindmapData = mindmapObj;
            });
            print('✅ Raw JSON mindmap extracted');
          }
        }
      } catch (_) {
        print('ℹ️ No mindmap JSON found in response');
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Container(
          width: 60 + (_breathingAnimation.value * 10),
          height: 60 + (_breathingAnimation.value * 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _colorAnimation.value?.withOpacity(0.3),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFBF046B),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not complete exploration',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w600,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w300,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startExploration,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF046B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a chat bubble for SSE events (integrated in conversation style)
  /// Note: finalResponse events are skipped here - they are displayed separately at the end
  Widget _buildEventBubble(SSEEvent event, int index) {
    final eventType = event.eventType;

    switch (eventType) {
      case SSEEventType.thinking:
        // Thinking bubble - show thought and optionally the associated tool call
        final widgets = <Widget>[];
        
        // Add the thought bubble
        widgets.add(_buildThinkingBubble(event.content.thoughtText, index));
        
        // If there's also a function call with this thought, show it too
        if (event.hasAssociatedFunctionCall) {
          final funcCallPart = event.content.parts.where((p) => p.functionCall != null).firstOrNull;
          if (funcCallPart != null) {
            widgets.add(_buildToolBubble(
              icon: Icons.build_outlined,
              title: 'Tool Call',
              subtitle: funcCallPart.functionCall!.name,
              color: const Color(0xFF2196F3),
            ));
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );

      case SSEEventType.functionCall:
        // Tool call - just show the title
        final funcCall = event.content.parts
            .firstWhere((p) => p.functionCall != null)
            .functionCall!;
        return _buildToolBubble(
          icon: Icons.build_outlined,
          title: 'Tool Call',
          subtitle: funcCall.name,
          color: const Color(0xFF2196F3),
        );

      case SSEEventType.functionResponse:
        // Tool response - just show the title
        final funcResp = event.content.parts
            .firstWhere((p) => p.functionResponse != null)
            .functionResponse!;
        return _buildToolBubble(
          icon: Icons.check_circle_outline,
          title: 'Tool Response',
          subtitle: funcResp.name,
          color: const Color(0xFF4CAF50),
        );

      case SSEEventType.finalResponse:
        // Skip - final response is displayed separately at the end of conversation
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildThinkingBubble(String content, int index) {
    // Create a preview (first ~100 chars, up to first newline)
    String preview = content.trim();
    final newlineIndex = preview.indexOf('\n');
    if (newlineIndex > 0 && newlineIndex < 120) {
      preview = preview.substring(0, newlineIndex);
    } else if (preview.length > 120) {
      preview = '${preview.substring(0, 120)}...';
    }
    
    final isLongContent = content.length > 120 || content.contains('\n');
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10, right: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thought icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Color(0xFF9C27B0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Thought content
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF9C27B0).withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview text - always visible
                      Text(
                        preview,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'NouvelR',
                          color: Colors.grey.shade700,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      // "See more" link if content is long
                      if (isLongContent)
                        GestureDetector(
                          onTap: () => _showFullThought(context, content),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See full thought',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'NouvelR',
                                    color: const Color(0xFF9C27B0).withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: const Color(0xFF9C27B0).withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show full thought content in a centered dialog
  void _showFullThought(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Color(0xFF9C27B0),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Agent Thought',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NouvelR',
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 22,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'NouvelR',
                      color: Colors.grey.shade800,
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolBubble({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'NouvelR',
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalResponseBubble(String content) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFBF046B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFBF046B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 17,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                    height: 1.6,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                  ),
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                  ),
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  h2: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  h3: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFFBF046B),
                  ),
                  code: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFFBF046B),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessageBubble(String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFBF046B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: 'NouvelR',
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF535450).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF535450),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a bubble for previous assistant answers (more compact)
  Widget _buildPreviousAnswerBubble(String content) {
    final cleanedContent = _cleanFinalResponse(content);
    if (cleanedContent.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFBF046B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFBF046B),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: MarkdownBody(
                data: cleanedContent,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFFBF046B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Send a suggestion message programmatically
  void _sendSuggestion(String message) {
    if (_isLoading) return;
    
    // Add to chat history
    _chatHistory.add(ChatMessage(
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now(),
    ));
    
    // Save and send
    widget.adkClient.addUserMessage(message);
    _sendMessage(message);
    
    // Force scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatInputBar() {
    final hasMindmap = _mindmapData != null;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Discreet suggestion chips
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Generate/Update Mindmap button - always available
                  _buildSuggestionChip(
                    icon: Icons.account_tree_outlined,
                    label: hasMindmap ? 'Update Mindmap' : 'Generate Mindmap',
                    onTap: () => _sendSuggestion('Generate Mindmap'),
                  ),
                  const SizedBox(width: 12),
                  // Search Deeper button
                  _buildSuggestionChip(
                    icon: Icons.manage_search,
                    label: 'Search deeper',
                    onTap: () => _sendSuggestion('Continue to search into another source of data.'),
                  ),
                ],
              ),
            ),
          // Chat input row
          Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              focusNode: _chatFocusNode,
              enabled: !_isLoading,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: InputDecoration(
                hintText: _isLoading
                    ? 'Waiting for response...'
                    : 'Continue the conversation...',
                hintStyle: const TextStyle(
                  fontFamily: 'NouvelR',
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFFBF046B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'NouvelR',
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _handleSendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    _isLoading ? Colors.grey.shade300 : const Color(0xFFBF046B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  /// Build a discreet suggestion chip
  Widget _buildSuggestionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final color = isDisabled ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDisabled 
                ? Colors.grey.shade100 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled ? Colors.grey.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'NouvelR',
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _getConversationItemCount(),
        itemBuilder: (context, index) {
          return _buildConversationItem(index);
        },
      ),
    );
  }

  /// Get completed previous exchanges (question + answer pairs, excluding current in-progress)
  List<_ConversationExchange> _getPreviousExchanges() {
    final exchanges = <_ConversationExchange>[];

    // Find pairs of user -> assistant messages (completed exchanges)
    int i = 0;
    while (i < _chatHistory.length) {
      if (_chatHistory[i].role == MessageRole.user) {
        // Check if there's a following assistant response
        if (i + 1 < _chatHistory.length &&
            _chatHistory[i + 1].role == MessageRole.assistant) {
          // This is a completed exchange, but skip if it's the current one being processed
          // Current one = last user message when we're still loading or just finished
          final isCurrentExchange =
              (i == _chatHistory.length - 2) || (i == _chatHistory.length - 1);
          if (!isCurrentExchange) {
            exchanges.add(_ConversationExchange(
              question: _chatHistory[i].content,
              answer: _chatHistory[i + 1].content,
            ));
          }
          i += 2;
        } else {
          // User message without response yet - this is current
          i++;
        }
      } else {
        i++;
      }
    }
    return exchanges;
  }

  /// Get the current user question (the one being processed or just finished)
  String _getCurrentQuestion() {
    // Find the last user message
    for (int i = _chatHistory.length - 1; i >= 0; i--) {
      if (_chatHistory[i].role == MessageRole.user) {
        return _chatHistory[i].content;
      }
    }
    return widget.topic;
  }

  /// Calculate total items in conversation
  int _getConversationItemCount() {
    final previousExchanges = _getPreviousExchanges();
    final nonFinalEvents =
        _events.where((e) => e.eventType != SSEEventType.finalResponse).length;
    final hasFinalResponse = _finalResponse.isNotEmpty && !_isLoading;

    // Previous exchanges (each = 2 items) + current question + events + final response/loading
    return (previousExchanges.length * 2) +
        1 +
        nonFinalEvents +
        (hasFinalResponse ? 1 : 0) +
        (_isLoading ? 1 : 0);
  }

  /// Build a conversation item based on index
  Widget _buildConversationItem(int index) {
    final previousExchanges = _getPreviousExchanges();
    final previousItemsCount = previousExchanges.length * 2;

    // Previous exchanges first
    if (index < previousItemsCount) {
      final exchangeIndex = index ~/ 2;
      final isQuestion = index % 2 == 0;
      final exchange = previousExchanges[exchangeIndex];

      if (isQuestion) {
        return _buildUserMessageBubble(exchange.question);
      } else {
        return _buildPreviousAnswerBubble(exchange.answer);
      }
    }

    // Current question
    final currentIndex = index - previousItemsCount;
    if (currentIndex == 0) {
      return _buildUserMessageBubble(_getCurrentQuestion());
    }

    // Events and final response
    final eventsIndex = currentIndex - 1;
    final nonFinalEvents = _events
        .where((e) => e.eventType != SSEEventType.finalResponse)
        .toList();

    // Show events
    if (eventsIndex < nonFinalEvents.length) {
      return _buildEventBubble(nonFinalEvents[eventsIndex], eventsIndex);
    }

    // After events
    final positionAfterEvents = eventsIndex - nonFinalEvents.length;

    // Loading indicator
    if (_isLoading && positionAfterEvents == 0) {
      return Container(
        margin: const EdgeInsets.only(left: 42, top: 8, bottom: 8),
        child: Row(
          children: [
            _buildLoadingIndicator(),
            const SizedBox(width: 12),
            const Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Final response (only once, at the end)
    if (!_isLoading && _finalResponse.isNotEmpty && positionAfterEvents == 0) {
      return _buildFinalResponseBubble(_cleanFinalResponse(_finalResponse));
    }

    return const SizedBox.shrink();
  }

  /// Clean the final response by removing mindmap JSON data
  String _cleanFinalResponse(String text) {
    String cleaned = text;

    // Remove ```json ... ``` blocks
    cleaned =
        cleaned.replaceAll(RegExp(r'```json[\s\S]*?```', multiLine: true), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');

    // Remove everything after "MINDMAP:" or "📊 MINDMAP:" if followed by JSON
    final mindmapIndex = cleaned.toLowerCase().indexOf('mindmap:');
    if (mindmapIndex != -1) {
      // Check if there's a JSON object after mindmap
      final afterMindmap = cleaned.substring(mindmapIndex);
      final jsonStart = afterMindmap.indexOf('{');
      if (jsonStart != -1 && jsonStart < 50) {
        // There's JSON shortly after "MINDMAP:", remove from there
        cleaned = cleaned.substring(0, mindmapIndex);
      }
    }

    // Remove standalone large JSON objects (more than 100 chars with "nodes" or "edges")
    final jsonPattern =
        RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', multiLine: true);
    cleaned = cleaned.replaceAllMapped(jsonPattern, (match) {
      final json = match.group(0) ?? '';
      if (json.length > 100 &&
          (json.contains('"nodes"') ||
              json.contains('"edges"') ||
              json.contains('"from"') ||
              json.contains('"to"'))) {
        return '';
      }
      return json;
    });

    // Remove lines that look like JSON array items
    cleaned = cleaned.replaceAll(
        RegExp(r'^\s*\{[^}]*"from"[^}]*"to"[^}]*\},?\s*$', multiLine: true),
        '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^\s*\{[^}]*"id"[^}]*"label"[^}]*\},?\s*$', multiLine: true),
        '');

    // Remove orphan JSON brackets and content
    cleaned =
        cleaned.replaceAll(RegExp(r'^\s*[\[\]{}]\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^\s*"[^"]+"\s*:\s*[\[\{]', multiLine: true), '');

    // Remove "MINDMAP:" labels (with or without emoji)
    cleaned = cleaned.replaceAll(
        RegExp(r'🗺️\s*MINDMAP:?', caseSensitive: false), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'📊\s*MINDMAP:?', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\*\*\s*MINDMAP:?\s*\*\*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'MINDMAP:', caseSensitive: false), '');

    // Clean up excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'^\s+', multiLine: true), '');

    return cleaned.trim();
  }

  Widget _buildMindmapTab() {
    if (_mindmapData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLoading ? Icons.hourglass_empty : Icons.account_tree_outlined,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              _isLoading
                  ? 'Waiting for mindmap data...'
                  : 'No mindmap available for this response',
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              _buildLoadingIndicator(),
            ],
          ],
        ),
      );
    }

    // Convert mindmap data to JSON string for flutter_mindmap
    final jsonString = jsonEncode(_mindmapData);
    print(
        '🗺️ Rendering mindmap with JSON: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');

    // Calculate nodes to expand up to depth 2 (root + 2 levels of children)
    final initiallyExpandedIds = _getNodesUpToDepth(_mindmapData!, 2);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mindmap info header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree,
                    color: Color(0xFF4CAF50), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Mindmap: ${_mindmapData!['nodes']?.length ?? 0} nodes, ${_mindmapData!['edges']?.length ?? 0} edges',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Mindmap widget
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MindMapWidget(
                  jsonData: jsonString,
                  layoutType: MindMapLayoutType.bidirectional,
                  backgroundColor: Colors.white,
                  edgeColor: const Color(0xFF535450),
                  animationDuration: const Duration(seconds: 2),
                  allowNodeOverlap: false,
                  expandAllNodesByDefault: false,
                  initiallyExpandedNodeIds: initiallyExpandedIds,
                  tooltipBackgroundColor:
                      const Color(0xFF535450).withOpacity(0.9),
                  tooltipTextColor: Colors.white,
                  tooltipTextSize: 14.0,
                  tooltipBorderRadius: 10.0,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  tooltipMaxWidth: 280.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate nodes that should be initially expanded up to a given depth.
  /// Depth 0 = root only, depth 1 = root + children, depth 2 = root + children + grandchildren
  Set<String> _getNodesUpToDepth(Map<String, dynamic> mindmapData, int maxDepth) {
    final expandedIds = <String>{};
    final nodes = mindmapData['nodes'] as List<dynamic>?;
    final edges = mindmapData['edges'] as List<dynamic>?;

    if (nodes == null || nodes.isEmpty) return expandedIds;

    // Build a map of node ID -> children IDs
    final childrenMap = <String, List<String>>{};
    if (edges != null) {
      for (final edge in edges) {
        final fromId = edge['from']?.toString() ?? '';
        final toId = edge['to']?.toString() ?? '';
        if (fromId.isNotEmpty && toId.isNotEmpty) {
          childrenMap.putIfAbsent(fromId, () => []).add(toId);
        }
      }
    }

    // Find root nodes (nodes with no incoming edges)
    final hasIncoming = <String>{};
    if (edges != null) {
      for (final edge in edges) {
        final toId = edge['to']?.toString() ?? '';
        if (toId.isNotEmpty) hasIncoming.add(toId);
      }
    }

    final allNodeIds = nodes.map((n) => n['id']?.toString() ?? '').toSet();
    final rootIds = allNodeIds.difference(hasIncoming);

    // BFS to collect nodes up to maxDepth
    final queue = <MapEntry<String, int>>[]; // (nodeId, depth)
    for (final rootId in rootIds) {
      if (rootId.isNotEmpty) {
        queue.add(MapEntry(rootId, 0));
      }
    }

    while (queue.isNotEmpty) {
      final entry = queue.removeAt(0);
      final nodeId = entry.key;
      final depth = entry.value;

      if (depth <= maxDepth) {
        expandedIds.add(nodeId);
        final children = childrenMap[nodeId] ?? [];
        for (final childId in children) {
          queue.add(MapEntry(childId, depth + 1));
        }
      }
    }

    return expandedIds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: SafeArea(
        child: Column(
          children: [
            // Compact header - single row with all controls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and session info
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'CORPUS EXPLORER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Session indicator
                        if (widget.adkClient.session != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.adkClient.session!.id.substring(0, 8),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'NouvelR',
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.isRestoredSession)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Restored',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'NouvelR',
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tab toggles - compact
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Response tab
                        GestureDetector(
                          onTap: () => setState(() => _currentTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _currentTab == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _currentTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_outlined,
                                  size: 16,
                                  color: _currentTab == 0
                                      ? const Color(0xFFBF046B)
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'NouvelR',
                                    fontWeight: _currentTab == 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _currentTab == 0
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                if (_events.isNotEmpty && _currentTab != 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBF046B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_events.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'NouvelR',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Mindmap tab
                        GestureDetector(
                          onTap: () => setState(() => _currentTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _currentTab == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _currentTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_tree_outlined,
                                  size: 16,
                                  color: _currentTab == 1
                                      ? const Color(0xFFBF046B)
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mindmap',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'NouvelR',
                                    fontWeight: _currentTab == 1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _currentTab == 1
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                if (_mindmapData != null)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: _currentTab == 1
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Close button
                  GestureDetector(
                    onTap: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content - maximized space
            Expanded(
              child: _error != null
                  ? _buildErrorState()
                  : _currentTab == 0
                      ? _buildResponseTab()
                      : _buildMindmapTab(),
            ),

            // Chat input bar (only on Response tab)
            if (_currentTab == 0) _buildChatInputBar(),
          ],
        ),
      ),
    );
  }
}

/// Represents a chat message in the conversation
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool hasMindmap;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.hasMindmap = false,
  });
}

/// Represents a previous conversation exchange (question + answer)
class _ConversationExchange {
  final String question;
  final String answer;

  const _ConversationExchange({
    required this.question,
    required this.answer,
  });
}
