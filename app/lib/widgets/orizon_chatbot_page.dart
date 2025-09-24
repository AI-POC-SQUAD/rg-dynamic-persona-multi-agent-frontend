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
// 'chat', 'tree', 'chart'

  // Slider values for persona criteria

  // Animation controllers

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers

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

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // White chat rectangle (wider)
          Container(
            width: 900, // Made wider (was 760)
            constraints: const BoxConstraints(minHeight: 200),
            child: _buildChatInputContainer(),
          ),

          const SizedBox(height: 20),

          // Explorer text below the white rectangle
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        ],
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
          child: Column(
            children: [
              // White chat rectangle (wider)
              Container(
                width: 900, // Made wider (was 760)
                constraints: const BoxConstraints(minHeight: 150),
                child: _buildChatInputContainer(),
              ),

              const SizedBox(height: 20),

              // Explorer text below the white rectangle
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
            ],
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Ask ${widget.selectedPersona?.name ?? 'ORIZON'}',
            style: const TextStyle(
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
              color: Colors.black,
            ),
            maxLines: 2,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          ),

          const SizedBox(height: 16),

          // Bottom row with segment selector and Go button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Positioned(
                          left: 1,
                          top: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(_selectedSegment!.iconPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Segment name
                    Text(
                      widget.selectedPersona?.name ?? 'ORIZON',
                      style: const TextStyle(
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
              child: //ImageIcon(
                  //AssetImage(_selectedSegment!.iconPath),
                  //size: 10,
                  //)
                  Positioned(
                left: 1,
                top: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_selectedSegment!.iconPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
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
                color: isUser ? Colors.transparent : Colors.white,
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
                        '${_selectedSegment!.name}',
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
                      color: Colors.black,
                      fontSize: 16,
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
              margin: const EdgeInsets.only(left: 12, top: 4, right: 60),
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

    setState(() {});

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
      setState(() {});
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
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header section (matching persona selection page)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, left: 80, right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with title and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // DYNAMIC PERSONA title (matching Figma layout)
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
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFC4C4C4), width: 0.5),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF535450),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat content area
                Expanded(
                  child: hasMessages
                      ? _buildChatWithMessages()
                      : _buildEmptyChat(),
                ),
              ],
            ),
          ),

          // Right sidebar (matching persona selection page)
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
}
