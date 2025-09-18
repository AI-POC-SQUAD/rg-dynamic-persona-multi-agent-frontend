import 'package:flutter/material.dart';
import '../models/customer_segment.dart';
import '../services/api_client.dart';
import '../services/conversation_manager.dart';
import '../models/conversation.dart';

class OrizonChatBotPage extends StatefulWidget {
  const OrizonChatBotPage({super.key});

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
  bool _hasStartedConversation = false;
  String _selectedOptionMode = 'chat'; // 'chat', 'tree', 'chart'

  // Animation controllers
  late AnimationController _screenTransitionController;
  late AnimationController _iconTransitionController;

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

    _loadRuntimeConfig();
    _initializeConversation();
  }

  void _loadRuntimeConfig() {
    final config = _apiClient.getRuntimeConfig();
    if (config != null) {
      print('Runtime config loaded: $config');
    } else {
      print('Warning: Runtime config not available');
    }
  }

  void _initializeConversation() {
    if (_conversationManager.conversations.isEmpty) {
      _conversationManager.createConversation(title: 'Orizon Chat');
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

  void _startConversation() {
    if (_selectedSegment == null) return;

    // Start screen transition animation
    _screenTransitionController.forward().then((_) {
      setState(() {
        _hasStartedConversation = true;
      });
      _screenTransitionController.reset();
    });

    // Add initial system message about the selected segment
    final initialMessage = ChatMessage(
      text:
          'You have selected: ${_selectedSegment!.name}. How can Orizon assist you today?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _conversationManager.addMessageToCurrentConversation(initialMessage);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final currentConversation = _conversationManager.currentConversation;

    if (currentConversation == null) {
      _conversationManager.createConversation(title: 'Orizon Chat');
    }

    final userId = _conversationManager.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _addErrorMessage(
            'No active conversation. Please create a new conversation.');
      });
      return;
    }

    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _conversationManager.addMessageToCurrentConversation(userChatMessage);

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

      _conversationManager.addMessageToCurrentConversation(botChatMessage);
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      _conversationManager.addMessageToCurrentConversation(errorMessage);
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addErrorMessage(String message) {
    final errorMessage = ChatMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
    _conversationManager.addMessageToCurrentConversation(errorMessage);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _hasStartedConversation
            ? Container(key: const ValueKey('chat'), child: _buildChatView())
            : Container(
                key: const ValueKey('segments'),
                child: _buildSegmentSelection()),
      ),
    );
  }

  Widget _buildSegmentSelection() {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Column(
        children: [
          // Top Header with ORIZON title (bigger and top left)
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ORIZON',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NouvelR',
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderIcon(Icons.assignment),
                      const SizedBox(width: 12),
                      _buildHeaderIcon(Icons.person),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Middle section with segments (vertically centered)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title Section
                  const Column(
                    children: [
                      Text(
                        'Select a customer segment',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Before starting conversation',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Customer Segments - Horizontal Layout
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _segments.length; i++) ...[
                          _buildSegmentCard(_segments[i]),
                          if (i < _segments.length - 1)
                            const SizedBox(width: 24),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Edit Icon
                  const Icon(
                    Icons.edit,
                    size: 15,
                    color: Color(0xFF535450),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section with chat input
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
    );
  }

  Widget _buildChatView() {
    final currentConversation = _conversationManager.currentConversation;
    final messages = currentConversation?.messages ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Column(
        children: [
          // Header with centered ORIZON title and action buttons
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button and ORIZON title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _hasStartedConversation = false;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ORIZON',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // Assignment and Person buttons (keeping as requested)
                  Row(
                    children: [
                      _buildHeaderIcon(Icons.assignment),
                      const SizedBox(width: 12),
                      _buildHeaderIcon(Icons.person),
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
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildChatInput(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFE1E1E3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: const Color(0xFF535450),
      ),
    );
  }

  Widget _buildSegmentCard(CustomerSegment segment) {
    final isSelected = segment.isSelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segment Button with animation
        GestureDetector(
          onTap: () => _selectSegment(segment),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 50,
            constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : const Color(0xFFE1E1E3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFC4C4C4),
                width: 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'NouvelR',
                  color: isSelected ? Colors.white : Colors.black,
                ),
                child: Text(
                  segment.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Connecting Line
        Container(
          height: 24,
          width: 1,
          color: const Color(0xFFE1DFE2),
        ),

        const SizedBox(height: 8),

        // Sphere/Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: segment.id == 'environment_evangelists'
                ? const RadialGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                  )
                : null,
            color: segment.id != 'environment_evangelists'
                ? const Color(0xFF4ECDC4)
                : null,
          ),
        ),
      ],
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
              if (!_hasStartedConversation && _selectedSegment != null) {
                _startConversation();
              }
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

              // Selected segment indicator with edit option
              if (_selectedSegment != null)
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFE2E3E8)),
                    ),
                    child: Row(
                      children: [
                        // Segment indicator with colored circle
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _selectedSegment!.id ==
                                        'environment_evangelists'
                                    ? const RadialGradient(
                                        colors: [
                                          Color(0xFFFF6B6B),
                                          Color(0xFF4ECDC4)
                                        ],
                                      )
                                    : null,
                                color: _selectedSegment!.id !=
                                        'environment_evangelists'
                                    ? const Color(0xFF4ECDC4)
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Segment name
                        Expanded(
                          child: Text(
                            _selectedSegment!.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'NouvelR',
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Edit icon
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasStartedConversation = false;
                            });
                          },
                          child: const Icon(
                            Icons.edit,
                            size: 15,
                            color: Color(0xFF535450),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Grouped option icons in pill container (when no segment selected)
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

              // Send Button (styled as "Go" button from Figma)
              GestureDetector(
                onTap: () {
                  if (!_hasStartedConversation && _selectedSegment != null) {
                    _startConversation();
                  }
                  _sendMessage();
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF535450),
                    borderRadius: BorderRadius.circular(32),
                    border:
                        Border.all(color: const Color(0xFFC4C4C4), width: 0.5),
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
    super.dispose();
  }
}
