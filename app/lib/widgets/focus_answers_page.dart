import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';
import '../utils/dummy_mindmap_data.dart';

class FocusAnswersPage extends StatefulWidget {
  final List<PersonaData> selectedPersonas;
  final List<PersonaInstance> selectedInstances;
  final String topic;
  final int rounds;

  const FocusAnswersPage({
    super.key,
    required this.selectedPersonas,
    required this.selectedInstances,
    required this.topic,
    required this.rounds,
  });

  @override
  State<FocusAnswersPage> createState() => _FocusAnswersPageState();
}

class _FocusAnswersPageState extends State<FocusAnswersPage>
    with TickerProviderStateMixin {
  int _currentTab = 0; // 0: Result, 1: Round Steps, 2: Summary
  String _analysisText = '';
  List<Map<String, dynamic>> _discussionRounds = [];
  bool _isLoading = true;
  String? _error;

  // Breathing animation controller
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize breathing animation
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFBF046B), // #BF046B
          end: const Color(0xFFF26716), // #F26716
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFF26716), // #F26716
          end: const Color(0xFFBF046B), // #BF046B
        ),
        weight: 50,
      ),
    ]).animate(_breathingController);

    _startFocusGroup();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  String _initialFor(PersonaData persona) {
    final trimmed = persona.name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  /// Start the focus group discussion with mock data (no backend)
  Future<void> _startFocusGroup() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Start breathing animation
      _breathingController.repeat();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Use mock data instead of API call
      final mockData = _getMockFocusGroupData();

      setState(() {
        _analysisText = mockData['executive_summary'];
        _discussionRounds =
            List<Map<String, dynamic>>.from(mockData['discussion'] ?? []);
        _isLoading = false;
      });

      // Stop breathing animation
      _breathingController.stop();
      print(
          '✅ Focus group completed with ${_discussionRounds.length} discussion turns (MOCK DATA)');
    } catch (e) {
      print('❌ Error in focus group: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fall back to mock analysis text
        _analysisText = _getMockAnalysisText();
      });

      // Stop breathing animation
      _breathingController.stop();
    }
  }

  /// Get mock focus group data including discussion rounds
  Map<String, dynamic> _getMockFocusGroupData() {
    return {
      'status': 'success',
      'executive_summary': _getMockAnalysisText(),
      'discussion': [
        {
          'turn': 1,
          'speaker': 'Status-driven commuter',
          'message':
              'I find the battery subscription model quite appealing. Being able to reduce my initial investment while maintaining flexibility is exactly what I need for my lifestyle.',
          'confidence': 87.5,
          'key_points': [
            'Lower entry cost is attractive',
            'Flexibility to upgrade batteries',
            'Suits high-income professionals'
          ],
          'concerns': ['Long-term subscription costs', 'Contract lock-in']
        },
        {
          'turn': 2,
          'speaker': 'Convenience buyer',
          'message':
              'The concept makes sense, but I\'m concerned about the added complexity. I just want a car that works without worrying about battery management.',
          'confidence': 62.3,
          'key_points': [
            'Simplicity is important',
            'Battery swapping could be complex',
            'Prefer straightforward purchase'
          ],
          'concerns': [
            'Administrative burden',
            'Unclear how battery replacement works'
          ]
        },
        {
          'turn': 3,
          'speaker': 'Price-conscious driver',
          'message':
              'Even with subscription, the upfront cost is still high. I\'d need much stronger savings to consider this option.',
          'confidence': 45.8,
          'key_points': [
            'Total cost of ownership is critical',
            'Hidden fees concern',
            'Need transparent pricing'
          ],
          'concerns': ['Overall affordability', 'Risk of price increases']
        },
        {
          'turn': 4,
          'speaker': 'Environment evangelist',
          'message':
              'I like how this model could extend battery lifecycle and improve recycling. That aligns with my environmental values.',
          'confidence': 71.2,
          'key_points': [
            'Supports sustainability',
            'Better battery lifecycle management',
            'Circular economy benefits'
          ],
          'concerns': [
            'Need proof of actual environmental benefits',
            'Recycling process unclear'
          ]
        },
        {
          'turn': 5,
          'speaker': 'Moderator synthesis',
          'message':
              'Key takeaway: Battery subscription works best for status-driven professionals (26% interest) but faces resistance from price-conscious consumers (11% interest). Success depends on transparent pricing and simplified logistics.',
          'confidence': 78.9,
          'key_points': [
            'Clear market segmentation identified',
            'Multiple concerns can be addressed with better communication',
            'Logistics and pricing are critical success factors'
          ],
          'concerns': []
        }
      ]
    };
  }

  String _getMockAnalysisText() {
    return """We can conclude that a battery subscription is a potentially good idea, but only if it is targeted at very specific customer segments. It is by no means a one-size-fits-all solution. Here is a detailed analysis based on the study's data.

The Battery Subscription Concept in the Study

The concept is directly addressed in the survey. To the question, "What would make you reduce your range expectations?", the option "Battery leasing (renting the EV's battery separately to reduce the initial cost and offer flexibility)" was proposed. The results vary considerably across segments:

• Status-driven commuters: This is the most interested group, with a 26% favorable response rate.
• Convenience buyers: Moderate interest at 19%.
• Environment evangelists: Moderate interest at 19%.
• Price-conscious errand drivers: Low interest at 11%.
• EV skeptic traditionalists: Very low interest at 10%.

This initial finding is already counter-intuitive: the most price-sensitive segments are the least interested in this cost-reduction solution.""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header section (reused from focus_settings_page)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, left: 80, right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with title, back button, and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left section with DYNAMIC PERSONA title and back button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DYNAMIC',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'PERSONA',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Back to start button
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Back to start',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'NouvelR',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Close button
                          GestureDetector(
                            onTap: () => Navigator.popUntil(
                                context, (route) => route.isFirst),
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

                // Toggle buttons for Result / Round Steps / Summary
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                  child: Row(
                    children: [
                      // Result tab
                      GestureDetector(
                        onTap: () => setState(() => _currentTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 24,
                                color: _currentTab == 0
                                    ? Colors.black
                                    : const Color(0xFFC4C4C4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Result',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NouvelR',
                                  color: _currentTab == 0
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Round Steps tab
                      GestureDetector(
                        onTap: () => setState(() => _currentTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 24,
                                color: _currentTab == 1
                                    ? Colors.black
                                    : const Color(0xFFC4C4C4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Round Steps',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NouvelR',
                                  color: _currentTab == 1
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Summary tab (new)
                      GestureDetector(
                        onTap: () => setState(() => _currentTab = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_tree_outlined,
                                size: 24,
                                color: _currentTab == 2
                                    ? Colors.black
                                    : const Color(0xFFC4C4C4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NouvelR',
                                  color: _currentTab == 2
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider line
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 80),
                  height: 1,
                  color: const Color(0xFFC4C4C4),
                ),

                // Content area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(80),
                    child: _buildContentArea(),
                  ),
                ),

                // Bottom conversation section with breathing animation
                AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                          // Breathing effect - only show when loading
                          if (_isLoading)
                            BoxShadow(
                              color: _colorAnimation.value
                                      ?.withValues(alpha: 0.6) ??
                                  Colors.transparent,
                              blurRadius: 30 + (20 * _breathingAnimation.value),
                              spreadRadius:
                                  5 + (10 * _breathingAnimation.value),
                              offset: const Offset(0, 0),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: ${widget.topic}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Selected personas row (reused from focus_settings_page)
                          Row(
                            children: [
                              for (int i = 0;
                                  i < widget.selectedInstances.length;
                                  i++)
                                Tooltip(
                                  message: _buildPersonaTooltip(
                                      widget.selectedInstances[i]),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'NouvelR',
                                    fontSize: 12,
                                  ),
                                  preferBelow: false,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Main circle
                                        Positioned(
                                          top: 3,
                                          left: 3,
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF535450),
                                                  width: 1),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _initialFor(widget
                                                    .selectedInstances[i]
                                                    .persona),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'NouvelR',
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Number overlay
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF535450),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${i + 1}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: 'NouvelR',
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Bottom explorer text (reused from focus_settings_page)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Explorer les cas d\'utilisation',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.black,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right sidebar (reused from focus_settings_page)
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

  Widget _buildContentArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF535450),
            ),
            const SizedBox(height: 24),
            Text(
              'Starting focus group discussion...',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'NouvelR',
                color: Color(0xFF535450),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'NouvelR',
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to start focus group',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'NouvelR',
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startFocusGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF535450),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Switch between tabs
    switch (_currentTab) {
      case 0:
        return _buildResultView();
      case 1:
        return _buildRoundStepsView();
      case 2:
        return _buildSummaryView();
      default:
        return _buildResultView();
    }
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: _analysisText,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                  height: 1.5,
                ),
                h1: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                h2: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                h3: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                strong: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                listBullet: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'NouvelR',
                  color: Colors.black,
                ),
                code: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Courier',
                  backgroundColor: Color(0xFFF5F5F5),
                  color: Color(0xFF535450),
                ),
                blockquote: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'NouvelR',
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundStepsView() {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discussion Rounds (${_discussionRounds.length} turns)',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            if (_discussionRounds.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No discussion rounds available yet.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'NouvelR',
                    color: Color(0xFF666666),
                  ),
                ),
              )
            else
              for (int i = 0; i < _discussionRounds.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF535450),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${_discussionRounds[i]['turn'] ?? i}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NouvelR',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _discussionRounds[i]['speaker'] ??
                                'Unknown Speaker',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_discussionRounds[i]['confidence'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(_discussionRounds[i]['confidence'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'NouvelR',
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_discussionRounds[i]['message'] != null) ...[
                              Text(
                                'Message:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(
                                data: _discussionRounds[i]['message'],
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'NouvelR',
                                    color: Color(0xFF333333),
                                    height: 1.4,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NouvelR',
                                    color: Color(0xFF333333),
                                  ),
                                  em: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'NouvelR',
                                    color: Color(0xFF333333),
                                  ),
                                  listBullet: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'NouvelR',
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                            if (_discussionRounds[i]['key_points'] != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Key Points:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final point in _discussionRounds[i]
                                  ['key_points'])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: MarkdownBody(
                                    data: point,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF444444),
                                        height: 1.3,
                                      ),
                                      strong: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF444444),
                                      ),
                                      em: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            if (_discussionRounds[i]['concerns'] != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Concerns:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final concern in _discussionRounds[i]
                                  ['concerns'])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: MarkdownBody(
                                    data: concern,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF666666),
                                        height: 1.3,
                                      ),
                                      strong: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF666666),
                                      ),
                                      em: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'NouvelR',
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  /// Build tooltip content for persona instance showing its settings
  String _buildPersonaTooltip(PersonaInstance instance) {
    return instance.persona.name;
  }

  /// Build the summary view with mind map visualization
  Widget _buildSummaryView() {
    // Generate persona names for the dummy data
    final personaNames = widget.selectedInstances
        .map((instance) => instance.persona.name)
        .toList();

    // Get dummy JSON data for the mind map
    // TODO: Replace this with actual backend response
    final mindMapData = DummyMindMapData.getFocusGroupSummary(
      widget.topic,
      personaNames,
    );

    return Column(
      children: [
        // Header with instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color: Color(0xFF535450),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Interactive Mind Map Summary - Pan to move, pinch to zoom',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'NouvelR',
                    color: Color(0xFF535450),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF046B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DEMO MODE - Backend integration pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'NouvelR',
                    color: Color(0xFFBF046B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mind map widget - centered view
        Expanded(
          child: Center(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: MindMapWidget(
                jsonData: mindMapData,
                useTreeLayout: true, // Use tree layout
                backgroundColor: const Color(0xFFE1DFE2),
                animationDuration: const Duration(seconds: 2),
                allowNodeOverlap: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
