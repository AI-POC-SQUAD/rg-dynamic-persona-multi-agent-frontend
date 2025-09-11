import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_client.dart';
import 'services/conversation_manager.dart';
import 'models/conversation.dart';
import 'widgets/conversation_list_drawer.dart';

void main() {
  runApp(const DynamicPersonaApp());
}

class DynamicPersonaApp extends StatelessWidget {
  const DynamicPersonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: MaterialApp(
        title: 'Dynamic Persona Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ChatPage(title: 'Dynamic Persona Chat'),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final ConversationManager _conversationManager = ConversationManager();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    // If no conversations exist, create the first one
    if (_conversationManager.conversations.isEmpty) {
      _conversationManager.createConversation(title: 'Welcome Chat');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final currentConversation = _conversationManager.currentConversation;
    
    if (currentConversation == null) {
      // Create a new conversation if none exists
      _conversationManager.createConversation(title: 'New Chat');
    }

    final userId = _conversationManager.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _addErrorMessage('No active conversation. Please create a new conversation.');
      });
      return;
    }

    _messageController.clear();

    // Add user message to conversation
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _conversationManager.addMessageToCurrentConversation(userChatMessage);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.sendChatMessage(userMessage, userId);
      
      // Extract answer and session_id from response
      final answerText = response['answer'] ?? response['response'] ?? response['message'] ?? 'No response from server';
      final sessionId = response['session_id'];
      
      final botChatMessage = ChatMessage(
        text: answerText,
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      
      _conversationManager.addMessageToCurrentConversation(botChatMessage);
      
      // Update conversation title if it's still the default and we have messages
      final conversation = _conversationManager.currentConversation;
      if (conversation != null && 
          (conversation.title.startsWith('New Conversation') || 
           conversation.title == 'Welcome Chat') &&
          conversation.messages.length >= 2) {
        // Use first few words of the user's first message as title
        final firstUserMessage = conversation.messages
            .where((m) => m.isUser)
            .isNotEmpty ? conversation.messages.where((m) => m.isUser).first : null;
        if (firstUserMessage != null) {
          final words = firstUserMessage.text.split(' ').take(4);
          final newTitle = words.join(' ') + (words.length >= 4 ? '...' : '');
          _conversationManager.updateConversationTitle(conversation.id, newTitle);
        }
      }
      
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      _conversationManager.addMessageToCurrentConversation(errorMessage);
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
  }

  void _onConversationSelected(String conversationId) {
    _conversationManager.switchToConversation(conversationId);
    setState(() {});
    Navigator.of(context).pop(); // Close drawer
  }

  void _onNewConversation() {
    _conversationManager.createConversation();
    setState(() {});
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    final currentConversation = _conversationManager.currentConversation;
    final messages = currentConversation?.messages ?? [];
    final conversationTitle = currentConversation?.title ?? 'No Conversation';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            if (currentConversation != null)
              Text(
                conversationTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showConfigDialog(),
          ),
        ],
      ),
      drawer: ConversationListDrawer(
        conversationManager: _conversationManager,
        onConversationSelected: _onConversationSelected,
        onNewConversation: _onNewConversation,
      ),
      body: Column(
        children: [
          if (currentConversation == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Text(
                'No conversation selected. Use the menu to create or select a conversation.',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatMessageWidget(message: messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: currentConversation != null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: (_isLoading || currentConversation == null) ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    final config = _apiClient.getRuntimeConfig();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Runtime Configuration'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config != null) ...[
                Text('Backend URL: ${config['BACKEND_BASE_URL']}'),
                Text('IAP Mode: ${config['IAP_MODE']}'),
                Text('Public Path: ${config['APP_PUBLIC_PATH']}'),
                if (config['IAP_AUDIENCE']?.isNotEmpty == true)
                  Text('IAP Audience: ${config['IAP_AUDIENCE']}'),
              ] else
                const Text('Runtime configuration not available'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  void _copyMessageToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isError
                ? Colors.red.shade100
                : message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isError
                            ? Colors.red.shade700
                            : message.isUser
                                ? Colors.white
                                : null,
                      ),
                    ),
                  ),
                  if (!message.isUser) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyMessageToClipboard(context, message.text),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isError
                          ? Colors.red.shade500
                          : message.isUser
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  if (message.sessionId != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.link,
                      size: 12,
                      color: message.isUser
                          ? Colors.white70
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
