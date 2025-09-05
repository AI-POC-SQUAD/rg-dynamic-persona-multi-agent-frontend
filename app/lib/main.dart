import 'package:flutter/material.dart';
import 'services/api_client.dart';

void main() {
  runApp(const DynamicPersonaApp());
}

class DynamicPersonaApp extends StatelessWidget {
  const DynamicPersonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Persona Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(title: 'Dynamic Persona Chat'),
      debugShowCheckedModeBanner: false,
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
  final List<ChatMessage> _messages = [];
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRuntimeConfig();
  }

  void _loadRuntimeConfig() {
    final config = _apiClient.getRuntimeConfig();
    if (config != null) {
      print('Runtime config loaded: $config');
    } else {
      print('Warning: Runtime config not available');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    try {
      final response = await _apiClient.sendChatMessage(userMessage);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showConfigDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageWidget(message: _messages[index]);
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

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
              Text(
                message.text,
                style: TextStyle(
                  color: message.isError
                      ? Colors.red.shade700
                      : message.isUser
                          ? Colors.white
                          : null,
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
                          : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
