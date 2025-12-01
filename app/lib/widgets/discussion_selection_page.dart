import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/conversation.dart';
import '../services/adk_api_client.dart';
import '../utils/fade_page_route.dart';
import 'focus_answers_page.dart';

class DiscussionSelectionPage extends StatefulWidget {
  const DiscussionSelectionPage({super.key});

  @override
  State<DiscussionSelectionPage> createState() =>
      _DiscussionSelectionPageState();
}

class _DiscussionSelectionPageState extends State<DiscussionSelectionPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ADKApiClient _adkClient = ADKApiClient();
  final FocusNode _focusNode = FocusNode();

  bool _isCreatingSession = false;
  bool _isLoadingConversations = false;
  bool _isRestoringSession = false;
  String? _sessionId;
  List<ConversationSummary> _savedConversations = [];
  List<ConversationSummary> _filteredConversations = [];

  // UI state
  bool _showRestoreInput = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadSavedConversations();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterConversations();
    });
  }

  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = _savedConversations;
    } else {
      _filteredConversations = _savedConversations.where((conv) {
        return conv.title.toLowerCase().contains(_searchQuery) ||
            conv.sessionId.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      final topic = _topicController.text.trim();
      final session = await _adkClient.createSession(
        initialTopic: topic.isNotEmpty ? topic : null,
      );
      if (!mounted) return;
      setState(() {
        _isCreatingSession = false;
        _sessionId = session.id;
      });
      print('✅ ADK Session created: ${session.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingSession = false;
      });
      _showErrorSnackBar('Failed to create session: ${e.toString()}');
      print('❌ Failed to create session: $e');
    }
  }

  Future<void> _loadSavedConversations() async {
    setState(() {
      _isLoadingConversations = true;
    });

    try {
      final conversations = await _adkClient.listConversations();
      if (!mounted) return;
      setState(() {
        _savedConversations = conversations;
        _filterConversations();
        _isLoadingConversations = false;
      });
      print('📚 Loaded ${conversations.length} saved conversations');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
      print('❌ Failed to load conversations: $e');
    }
  }

  Future<void> _restoreConversation(String sessionId) async {
    setState(() {
      _isRestoringSession = true;
    });

    try {
      final success = await _adkClient.restoreSession(sessionId);
      if (!mounted) return;

      if (success) {
        setState(() {
          _isRestoringSession = false;
          _sessionId = sessionId;
        });

        final conversation = _adkClient.conversation;
        Navigator.of(context).push(
          FadePageRoute(
            child: FocusAnswersPage(
              topic: conversation?.title ?? 'Restored conversation',
              adkClient: _adkClient,
              isRestoredSession: true,
            ),
          ),
        );
      } else {
        setState(() {
          _isRestoringSession = false;
        });
        _showErrorSnackBar('Could not find conversation with ID: $sessionId');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoringSession = false;
      });
      _showErrorSnackBar('Failed to restore session: ${e.toString()}');
    }
  }

  Future<void> _deleteConversation(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Conversation'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this conversation and its mindmap? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adkClient.deleteConversation(sessionId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        _loadSavedConversations();
      }
    }
  }

  void _startExploration() {
    final topic = _topicController.text.trim();
    if (topic.isEmpty || !_adkClient.hasSession) return;

    _adkClient.updateConversationTitle(topic);

    Navigator.of(context).push(
      FadePageRoute(
        child: FocusAnswersPage(
          topic: topic,
          adkClient: _adkClient,
        ),
      ),
    );
  }

  void _handleRestoreFromInput() {
    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) return;
    _restoreConversation(sessionId);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Session ID copied: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _sessionIdController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main content
            Expanded(
              child: isWideScreen
                  ? _buildWideLayout()
                  : _buildNarrowLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBF046B), Color(0xFFF26716)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CORPUS EXPLORER',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NouvelR',
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Knowledge Base & RAG Agent Interface',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'NouvelR',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Status and actions
          Row(
            children: [
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _sessionId != null
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sessionId != null
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sessionId != null ? 'Connected' : 'Connecting...',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'NouvelR',
                        fontWeight: FontWeight.w500,
                        color: _sessionId != null
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Refresh button
              IconButton(
                onPressed: () {
                  _initializeSession();
                  _loadSavedConversations();
                },
                icon: _isCreatingSession || _isLoadingConversations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left panel - New Exploration
        Expanded(
          flex: 2,
          child: _buildNewExplorationPanel(),
        ),
        // Right panel - Saved Conversations
        Expanded(
          flex: 3,
          child: _buildSavedConversationsPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildNewExplorationCard(),
          const SizedBox(height: 32),
          _buildSavedConversationsCard(),
        ],
      ),
    );
  }

  Widget _buildNewExplorationPanel() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: _buildNewExplorationCard(),
    );
  }

  Widget _buildNewExplorationCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBF046B), Color(0xFFF26716)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Exploration',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NouvelR',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Start a new conversation with the RAG agent',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'NouvelR',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Topic input
          const Text(
            'Topic or Question',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'NouvelR',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topicController,
            focusNode: _focusNode,
            onSubmitted: (_) => _startExploration(),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g., "Explore car_data_usage namespace" or "What do eco-conscious customers want?"',
              hintStyle: const TextStyle(
                fontFamily: 'NouvelR',
                color: Colors.black38,
                fontSize: 15,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFBF046B),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NouvelR',
            ),
          ),
          const SizedBox(height: 24),
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startExploration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Exploration',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NouvelR',
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Divider
          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'NouvelR',
                    color: Colors.black38,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 24),
          // Restore by session ID
          _buildRestoreByIdSection(),
        ],
      ),
    );
  }

  Widget _buildRestoreByIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showRestoreInput = !_showRestoreInput;
            });
          },
          child: Row(
            children: [
              Icon(
                _showRestoreInput ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Restore by Session ID',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'NouvelR',
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ),
        if (_showRestoreInput) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _sessionIdController,
            onSubmitted: (_) => _handleRestoreFromInput(),
            decoration: InputDecoration(
              hintText: 'Paste session ID here...',
              hintStyle: const TextStyle(
                fontFamily: 'NouvelR',
                color: Colors.black38,
              ),
              filled: true,
              fillColor: const Color(0xFFF0F7FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2196F3),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: _isRestoringSession
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Color(0xFF2196F3)),
                      onPressed: _handleRestoreFromInput,
                    ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'NouvelR',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSavedConversationsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: _buildSavedConversationsCard(),
    );
  }

  Widget _buildSavedConversationsCard() {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFBF046B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_special,
                  color: Color(0xFFBF046B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Saved Conversations',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBF046B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_savedConversations.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NouvelR',
                              color: Color(0xFFBF046B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _savedConversations.isEmpty
                          ? 'No conversations yet'
                          : 'Click on a conversation to continue',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'NouvelR',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _loadSavedConversations,
                icon: _isLoadingConversations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                color: Colors.black54,
                tooltip: 'Refresh conversations',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: const TextStyle(
                fontFamily: 'NouvelR',
                color: Colors.black38,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'NouvelR',
            ),
          ),
          const SizedBox(height: 20),
          // Conversations list
          Expanded(
            child: _buildConversationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_isLoadingConversations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFBF046B)),
            SizedBox(height: 16),
            Text(
              'Loading conversations...',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (_savedConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saved conversations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new exploration to create\nyour first conversation',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'NouvelR',
                color: Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredConversations.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations match "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conv = _filteredConversations[index];
        return _buildConversationCard(conv, index);
      },
    );
  }

  Widget _buildConversationCard(ConversationSummary conv, int index) {
    final isRecent = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _restoreConversation(conv.sessionId),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecent
                  ? const Color(0xFFFFF8F5)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRecent
                    ? const Color(0xFFBF046B).withOpacity(0.2)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: conv.hasMindmap
                        ? const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFFBF046B).withOpacity(0.8),
                              const Color(0xFFF26716).withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    conv.hasMindmap
                        ? Icons.account_tree
                        : Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NouvelR',
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecent)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBF046B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Recent',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NouvelR',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${conv.messageCount} messages',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'NouvelR',
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conv.timeAgo,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'NouvelR',
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (conv.hasMindmap) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_tree,
                                    size: 12,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mindmap',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NouvelR',
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Copy Session ID',
                      onTap: () => _copyToClipboard(conv.sessionId),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: Colors.red.shade400,
                      onTap: () => _deleteConversation(conv.sessionId),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.arrow_forward_ios,
                      tooltip: 'Open',
                      color: const Color(0xFFBF046B),
                      onTap: () => _restoreConversation(conv.sessionId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (color ?? Colors.grey.shade600).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
