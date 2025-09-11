import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/conversation_manager.dart';

class ConversationListDrawer extends StatefulWidget {
  final ConversationManager conversationManager;
  final Function(String) onConversationSelected;
  final VoidCallback onNewConversation;

  const ConversationListDrawer({
    super.key,
    required this.conversationManager,
    required this.onConversationSelected,
    required this.onNewConversation,
  });

  @override
  State<ConversationListDrawer> createState() => _ConversationListDrawerState();
}

class _ConversationListDrawerState extends State<ConversationListDrawer> {
  @override
  Widget build(BuildContext context) {
    final conversations = widget.conversationManager.conversations;
    final currentConversationId = widget.conversationManager.currentConversationId;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Dynamic Persona',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chat Conversations',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onNewConversation,
                icon: const Icon(Icons.add),
                label: const Text('New Conversation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: conversations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No conversations yet.\nCreate your first conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected = conversation.id == currentConversationId;
                      
                      return ConversationListTile(
                        conversation: conversation,
                        isSelected: isSelected,
                        onTap: () => widget.onConversationSelected(conversation.id),
                        onDelete: () => _deleteConversation(conversation.id),
                        onRename: (newTitle) => _renameConversation(conversation.id, newTitle),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _clearAllConversations,
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.conversationManager.deleteConversation(conversationId);
              Navigator.of(context).pop();
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _renameConversation(String conversationId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Conversation Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                widget.conversationManager.updateConversationTitle(conversationId, newTitle);
                setState(() {});
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearAllConversations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text('Are you sure you want to delete all conversations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.conversationManager.clearAllConversations();
              Navigator.of(context).pop();
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onRename;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessageText = conversation.messages.isNotEmpty
        ? conversation.messages.last.text
        : 'No messages yet';
    
    final timeAgo = _getTimeAgo(conversation.lastMessageAt);

    return ListTile(
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.chat,
          color: isSelected ? Colors.white : null,
          size: 20,
        ),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.person, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 2),
              Text(
                conversation.userId,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: const [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'delete') {
            onDelete();
          } else if (value == 'rename') {
            onRename(conversation.title);
          }
        },
      ),
      onTap: onTap,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
