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
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          // Main content - always show chat view
          _buildChatView(),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    final currentConversation = _conversationManager.currentConversation;
    final messages = currentConversation?.messages ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with centered ORIZON title and action buttons
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, left: 80, right: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button and ORIZON title

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DYNAMIC',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700, // Bold
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'PERSONA',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Book weight
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Messages with centered layout
              Expanded(
                child: Container(
                  width: double.infinity,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildChatMessage(messages[index]);
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF535450),
                  ),
                ),

              // Chat Input with centered layout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Chat Input Area
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildChatInput(),
                    ),

                    const SizedBox(height: 20),

                    // Explorer text
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Explorer les cas d\'utilisation',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8F9893),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.menu,
                          size: 24,
                          color: Color(0xFF8F9893),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Right sidebar
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // CTA buttons
                  Column(
                    children: [
                      // Message button
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 24,
                          color: Color(0xFF535450),
                        ),
                      ),
                      // Menu button
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: const Icon(
                          Icons.menu,
                          size: 24,
                          color: Color(0xFF535450),
                        ),
                      ),
                      // Folder button
                      Container(
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.folder_outlined,
                          size: 24,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E3E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text input field
          TextField(
            controller: _messageController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Ask ORIZON',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Color(0xFF8F9893),
                fontFamily: 'NouvelR',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NouvelR',
              color: Colors.black,
            ),
            onSubmitted: (_) {
              _sendMessage();
            },
          ),

          const SizedBox(height: 16),

          // Bottom row with icons and segment selector
          Row(
            children: [
              // Attachment Icon
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1E1E3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_file,
                  size: 15,
                  color: Color(0xFF535450),
                ),
              ),

              const SizedBox(width: 12),

              const Spacer(),

              // Grouped option icons in pill container (when no conversation started)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFE2E3E8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chat bubble icon
                    GestureDetector(
                      onTap: () => _selectOptionMode('chat'),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _selectedOptionMode == 'chat'
                              ? Colors.white
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: _selectedOptionMode == 'chat'
                              ? [
                                  const BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Tree icon
                    GestureDetector(
                      onTap: () => _selectOptionMode('tree'),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _selectedOptionMode == 'tree'
                              ? Colors.white
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: _selectedOptionMode == 'tree'
                              ? [
                                  const BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.account_tree_outlined,
                          size: 14,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Bar chart icon
                    GestureDetector(
                      onTap: () => _selectOptionMode('chart'),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(
                            right: 4, top: 2, bottom: 2, left: 2),
                        decoration: BoxDecoration(
                          color: _selectedOptionMode == 'chart'
                              ? Colors.white
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: _selectedOptionMode == 'chart'
                              ? [
                                  const BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          size: 14,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Send Button - Arrow before first message, "Go" text after
              GestureDetector(
                onTap: () {
                  _sendMessage();
                },
                child: Container(
                  height: 32,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF535450),
                    borderRadius: BorderRadius.circular(32),
                    border:
                        Border.all(color: const Color(0xFFC4C4C4), width: 0.5),
                  ),
                  child: Center(
                    child: const Text(
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
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message bubble with avatar and connecting line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // Bot avatar with connecting line
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1E1E3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 12,
                        color: Color(0xFF535450),
                      ),
                    ),
                    // Connecting line
                    Container(
                      width: 1,
                      height: 74,
                      margin: const EdgeInsets.only(right: 12),
                      color: const Color(0xFFE1DFE2),
                    ),
                  ],
                ),
              ],

              // Message content with gradient background
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                    minWidth: 200,
                  ),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Customer segment label for bot messages
                      if (!isUser && _selectedSegment != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 20),
                          child: Text(
                            '${_selectedSegment!.name} - Rural',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6D6F72),
                              fontFamily: 'NouvelR',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                      // Message bubble with gradient background
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          // Gradient background for message bubbles matching Figma
                          gradient: isError
                              ? null
                              : isUser
                                  ? null
                                  : const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFF8F8F8),
                                        Color(0xFFFFFFFF),
                                      ],
                                    ),
                          color: isError
                              ? Colors.red.shade100
                              : isUser
                                  ? Colors.transparent
                                  : null,
                          borderRadius: BorderRadius.circular(24),
                          border: !isUser && !isError
                              ? Border.all(
                                  color: const Color(0xFFE2E3E8), width: 1)
                              : null,
                          boxShadow: [
                            if (!isUser && !isError)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Message text with proper formatting
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'NouvelR',
                                  fontWeight: FontWeight.w400,
                                  color: isError
                                      ? Colors.red.shade700
                                      : isUser
                                          ? Colors.black
                                          : Colors.black,
                                  height: 1.5,
                                ),
                                children: _parseMessageText(
                                    message.text, isUser, isError),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons for bot messages
                      if (!isUser && !isError)
                        Container(
                          margin: const EdgeInsets.only(top: 12, left: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildActionButton(
                                icon: Icons.exit_to_app,
                                label: 'Sources',
                                onTap: () => _showSources(message),
                              ),
                              const SizedBox(width: 20),
                              _buildActionButton(
                                icon: Icons.content_copy,
                                label: 'Copy',
                                onTap: () => _copyMessage(message.text),
                              ),
                              const SizedBox(width: 20),
                              _buildActionButton(
                                icon: Icons.refresh,
                                label: 'Try again',
                                onTap: () => _retryLastMessage(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (isUser) ...[
                // User avatar with connecting line
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1E1E3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 12,
                        color: Color(0xFF535450),
                      ),
                    ),
                    // Connecting line for user
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.only(left: 12),
                      color: const Color(0xFFE1DFE2),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to parse text with bold formatting
  List<TextSpan> _parseMessageText(String text, bool isUser, bool isError) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
        ));
      }

      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'NouvelR',
          color: isError
              ? Colors.red.shade700
              : isUser
                  ? Colors.black
                  : Colors.black,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
      ));
    }

    // If no bold text was found, return the whole text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF535450),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF535450),
                fontFamily: 'NouvelR',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSources(ChatMessage message) {
    // Implement source viewing functionality
    print('Show sources for: ${message.text}');
  }

  void _copyMessage(String text) {
    // Implement copy functionality
    print('Copy message: $text');
    // You can use package:flutter/services.dart Clipboard.setData() here
  }

  void _retryLastMessage() {
    // Implement retry functionality
    print('Retry last message');
    final currentConversation = _conversationManager.currentConversation;
    if (currentConversation != null &&
        currentConversation.messages.isNotEmpty) {
      // Find the last user message and resend it
      for (int i = currentConversation.messages.length - 1; i >= 0; i--) {
        final msg = currentConversation.messages[i];
        if (msg.isUser) {
          _messageController.text = msg.text;
          _sendMessage();
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _screenTransitionController.dispose();
    _iconTransitionController.dispose();
    _personPanelController.dispose();
    super.dispose();
  }
}
