// Alternative implementation without any Expanded/Flexible widgets
// Use this if the Flexible widgets still cause issues

Widget _buildChatWithMessagesAlternative() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate available height for messages
      final availableHeight = constraints.maxHeight - 200; // Reserve space for input
      
      return Column(
        children: [
          // Chat messages area with fixed height
          SizedBox(
            height: availableHeight > 0 ? availableHeight : 300,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                reverse: true,
                itemCount: _conversationManager.currentConversation?.messages.length ?? 0,
                itemBuilder: (context, index) {
                  final messages = _conversationManager.currentConversation!.messages;
                  final message = messages[messages.length - 1 - index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          
          // Fixed height input container
          SizedBox(
            height: 200,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Input container
                  Container(
                    width: 900,
                    constraints: const BoxConstraints(minHeight: 150),
                    child: _buildChatInputContainer(),
                  ),
                  const SizedBox(height: 20),
                  // Explorer text
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Explorer les cas d\'utilisation', /* styling */),
                      SizedBox(width: 8),
                      Icon(Icons.format_list_bulleted, size: 16, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}