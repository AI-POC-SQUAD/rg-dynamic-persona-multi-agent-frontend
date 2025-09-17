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
  late Animation<double> _screenSlideAnimation;
  late Animation<double> _screenFadeAnimation;

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

    _screenSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _screenTransitionController,
      curve: Curves.easeInOut,
    ));

    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _screenTransitionController,
      curve: Curves.easeInOut,
    ));

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

    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFE1DFE2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _hasStartedConversation = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text(
                      'ORIZON',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (_selectedSegment != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedSegment!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildChatMessage(messages[index]);
            },
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),

        // Chat Input
        Container(
          color: const Color(0xFFE1DFE2),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildChatInput(),
            ),
          ),
        ),
      ],
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
          // First line: "Ask ORIZON" placeholder text
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Ask ORIZON',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Color(0xFF8F9893),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) {
              if (!_hasStartedConversation && _selectedSegment != null) {
                _startConversation();
              }
              _sendMessage();
            },
          ),

          const SizedBox(height: 16),

          // Second line: All icons
          Row(
            children: [
              // Attachment Icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1E1E3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_file,
                  size: 18,
                  color: Color(0xFF535450),
                ),
              ),

              const SizedBox(width: 12),

              // Grouped option icons in pill container
              Container(
                height: 36,
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
                        width: 32,
                        height: 32,
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
                          size: 16,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tree icon
                    GestureDetector(
                      onTap: () => _selectOptionMode('tree'),
                      child: Container(
                        width: 32,
                        height: 32,
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
                          size: 16,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Bar chart icon
                    GestureDetector(
                      onTap: () => _selectOptionMode('chart'),
                      child: Container(
                        width: 32,
                        height: 32,
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
                          size: 16,
                          color: Color(0xFF535450),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Voice input icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E3E8)),
                ),
                child: const Icon(
                  Icons.mic,
                  size: 18,
                  color: Color(0xFF535450),
                ),
              ),

              const SizedBox(width: 12),

              // Send Button
              GestureDetector(
                onTap: () {
                  if (!_hasStartedConversation && _selectedSegment != null) {
                    _startConversation();
                  }
                  _sendMessage();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF535450),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isError
                ? Colors.red.shade100
                : message.isUser
                    ? const Color(0xFF535450)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!message.isUser)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isError
                      ? Colors.red.shade700
                      : message.isUser
                          ? Colors.white
                          : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: message.isError
                      ? Colors.red.shade500
                      : message.isUser
                          ? Colors.white70
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
