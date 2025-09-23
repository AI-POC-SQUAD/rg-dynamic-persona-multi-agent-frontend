import 'package:flutter/material.dart';
import '../models/customer_segment.dart';
import '../models/persona_data.dart';
import '../services/api_client.dart';
import '../services/conversation_manager.dart';
import '../models/conversation.dart';

class OrizonChatBotPage extends StatefulWidget {
  final PersonaData? selectedPersona;

  const OrizonChatBotPage({super.key, this.selectedPersona});

  @override
  State<OrizonChatBotPage> createState() => _OrizonChatBotPageState();
}

class _OrizonChatBotPageState extends State<OrizonChatBotPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient();
  final ConversationManager _conversationManager = ConversationManager();

  List<CustomerSegment> _segments = CustomerSegment.getDefaultSegments();
  CustomerSegment? _selectedSegment;
  bool _isLoading = false;
  bool _showPersonPanel = false;
  String _selectedOptionMode = 'chat'; // 'chat', 'tree', 'chart'

  // Slider values for persona criteria
  double _ruralUrbanSliderValue = 0.6;
  double _poorRichSliderValue = 0.4;

  // Animation controllers
  late AnimationController _screenTransitionController;
  late AnimationController _iconTransitionController;
  late AnimationController _personPanelController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _screenTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconTransitionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _personPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadRuntimeConfig();
    _initializeConversation();

    // If a persona is pre-selected, automatically select the corresponding segment
    if (widget.selectedPersona != null) {
      _autoSelectSegmentFromPersona(widget.selectedPersona!);
    }
  }

  void _autoSelectSegmentFromPersona(PersonaData persona) {
    // Find matching segment based on persona name
    final matchingSegment = _segments.firstWhere(
      (segment) => segment.name.toLowerCase() == persona.name.toLowerCase(),
      orElse: () => _segments.first, // Fallback to first segment
    );

    // Automatically select the segment
    _selectSegment(matchingSegment);
  }

  void _loadRuntimeConfig() {
    final config = _apiClient.getRuntimeConfig();
    if (config != null) {
      print('Runtime config loaded: $config');
    } else {
      print('Warning: Runtime config not available');
    }
  }

  Future<void> _initializeConversation() async {
    if (_conversationManager.conversations.isEmpty) {
      await _conversationManager.createConversation(title: 'Orizon Chat');
    }
  }

  void _selectSegment(CustomerSegment segment) {
    setState(() {
      _segments = _segments
          .map((s) => s.copyWith(isSelected: s.id == segment.id))
          .toList();
      _selectedSegment = segment;
    });
  }

  void _selectOptionMode(String mode) {
    _iconTransitionController.forward().then((_) {
      setState(() {
        _selectedOptionMode = mode;
      });
      _iconTransitionController.reverse();
    });
    // You can add specific logic for each mode here
    print('Selected option mode: $mode');
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Container(
        width: 760,
        height: 200,
        child: _buildChatInputContainer(),
      ),
    );
  }

  Widget _buildChatWithMessages() {
    return Column(
      children: [
        // Chat messages area
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              reverse: true,
              itemCount:
                  _conversationManager.currentConversation?.messages.length ??
                      0,
              itemBuilder: (context, index) {
                final messages =
                    _conversationManager.currentConversation!.messages;
                final message = messages[messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ),

        // Input container at bottom
        Container(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 760,
            height: 200,
            child: _buildChatInputContainer(),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInputContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Ask Environment evangelist',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'NouvelR',
              fontWeight: FontWeight.w400,
              color: Color(0xFFC4C4C4),
            ),
          ),

          const SizedBox(height: 16),

          // Text input (hidden but functional)
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Type your message...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'NouvelR',
              color: Colors.transparent,
            ),
            maxLines: 3,
            onSubmitted: (_) => _sendMessage(),
          ),

          const Spacer(),

          // Bottom row with segment and button
          Row(
            children: [
              // Segment selector
              Container(
                height: 28,
                padding: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border:
                      Border.all(color: const Color(0xFFC4C4C4), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Persona indicator circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFC4C4C4), width: 0.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Segment name
                    const Text(
                      'EV Skeptic',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'NouvelR',
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Settings icon
                    const Icon(
                      Icons.settings,
                      size: 16,
                      color: Color(0xFF535450),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Go button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 32,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF535450),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Center(
                    child: Text(
                      'Go',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'NouvelR',
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Explorer link
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explorer les cas d\'utilisation',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'NouvelR',
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.format_list_bulleted,
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF4ECDC4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF535450) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    !isUser ? Border.all(color: Colors.grey.shade300) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && _selectedSegment != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_selectedSegment!.name} - Rural',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'NouvelR',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontFamily: 'NouvelR',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            // User Avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 12, top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF666666),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final currentConversation = _conversationManager.currentConversation;

    if (currentConversation == null) {
      await _conversationManager.createConversation(title: 'Orizon Chat');
    }

    final userId = _conversationManager.getCurrentUserId();
    if (userId == null) {
      await _addErrorMessage(
          'No active conversation. Please create a new conversation.');
      return;
    }

    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    await _conversationManager.addMessageToCurrentConversation(userChatMessage);

    setState(() {
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final currentConversation = _conversationManager.currentConversation;

      final conversationHistory = currentConversation != null
          ? ApiClient.formatConversationHistory(currentConversation.messages)
          : <Map<String, dynamic>>[];

      // Include selected segment context
      final contextualHistory = [
        if (_selectedSegment != null)
          {
            'role': 'system',
            'content':
                'Customer segment: ${_selectedSegment!.name} - ${_selectedSegment!.description}'
          },
        ...conversationHistory,
      ];

      final response = await _apiClient.sendChatMessage(
        userMessage,
        userId,
        conversationId: currentConversation?.id,
        conversationHistory: contextualHistory,
      );

      final answerText = response['answer'] ??
          response['response'] ??
          response['message'] ??
          'No response from server';
      final sessionId = response['session_id'];

      final botChatMessage = ChatMessage(
        text: answerText,
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );

      await _conversationManager
          .addMessageToCurrentConversation(botChatMessage);
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      await _conversationManager.addMessageToCurrentConversation(errorMessage);
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addErrorMessage(String message) async {
    final errorMessage = ChatMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
    await _conversationManager.addMessageToCurrentConversation(errorMessage);
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    final hasMessages =
        _conversationManager.currentConversation?.messages.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Dynamic Persona',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NouvelR',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: hasMessages ? _buildChatWithMessages() : _buildEmptyChat(),
    );
  }
}
