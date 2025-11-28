import 'package:flutter/material.dart';
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
  final ADKApiClient _adkClient = ADKApiClient();
  final FocusNode _focusNode = FocusNode();

  bool _isCreatingSession = false;
  String? _errorMessage;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isCreatingSession = true;
      _errorMessage = null;
    });

    try {
      final session = await _adkClient.createSession();
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
        _errorMessage = e.toString();
      });
      print('❌ Failed to create session: $e');
    }
  }

  void _startExploration() {
    final topic = _topicController.text.trim();
    if (topic.isEmpty || !_adkClient.hasSession) return;

    Navigator.of(context).push(
      FadePageRoute(
        child: FocusAnswersPage(
          topic: topic,
          adkClient: _adkClient,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFBF046B),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not connect to ADK Server',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                fontFamily: 'NouvelR',
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF046B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicInputCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 64,
            color: Color(0xFFBF046B),
          ),
          const SizedBox(height: 24),
          const Text(
            'Explore Knowledge Base',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              fontFamily: 'NouvelR',
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter a topic or question to explore the corpus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              fontFamily: 'NouvelR',
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Topic input field
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              controller: _topicController,
              focusNode: _focusNode,
              onSubmitted: (_) => _startExploration(),
              decoration: InputDecoration(
                hintText:
                    'e.g., "What is in car_data_usage?" or "Explore eco-conscious_emma"',
                hintStyle: const TextStyle(
                  fontFamily: 'NouvelR',
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                suffixIcon: IconButton(
                  onPressed: _startExploration,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFFBF046B),
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'NouvelR',
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Start exploration button
          GestureDetector(
            onTap: _startExploration,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Exploration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NouvelR',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Session status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sessionId != null
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _sessionId != null
                    ? 'Session active: ${_sessionId!.substring(0, 8)}...'
                    : 'Connecting to ADK server...',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'NouvelR',
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, left: 80, right: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CORPUS EXPLORER title
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CORPUS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'EXPLORER',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  // Refresh session button
                  IconButton(
                    onPressed: _initializeSession,
                    icon: _isCreatingSession
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    iconSize: 32,
                    color: const Color(0xFF000000),
                    tooltip: 'Refresh session',
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: _isCreatingSession
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFBF046B),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Connecting to ADK server...',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'NouvelR',
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : _errorMessage != null
                        ? _buildErrorState()
                        : SingleChildScrollView(
                            child: _buildTopicInputCard(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
