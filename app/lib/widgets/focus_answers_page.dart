import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';
import '../models/discussion.dart';
import '../services/api_client.dart';

class FocusAnswersPage extends StatefulWidget {
  final String discussionId;

  const FocusAnswersPage({
    super.key,
    required this.discussionId,
  });

  @override
  State<FocusAnswersPage> createState() => _FocusAnswersPageState();
}

class _FocusAnswersPageState extends State<FocusAnswersPage>
    with TickerProviderStateMixin {
  int _currentTab = 0; // 0: Summary, 1: Mindmap
  bool _isLoading = true;
  String? _error;
  DiscussionDetail? _discussionDetail;

  final ApiClient _apiClient = ApiClient();

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
          begin: const Color(0xFFBF046B),
          end: const Color(0xFFF26716),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFF26716),
          end: const Color(0xFFBF046B),
        ),
        weight: 50,
      ),
    ]).animate(_breathingController);

    _loadDiscussion();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  /// Load the discussion details from the API
  Future<void> _loadDiscussion() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Start breathing animation
      _breathingController.repeat();

      final discussionDetail =
          await _apiClient.getDiscussion(widget.discussionId);

      if (!mounted) return;

      setState(() {
        _discussionDetail = discussionDetail;
        _isLoading = false;
      });

      // Stop breathing animation
      _breathingController.stop();
      print('✅ Discussion loaded successfully');
    } catch (e) {
      print('❌ Error loading discussion: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      // Stop breathing animation
      _breathingController.stop();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Container(
                width: 120 + (_breathingAnimation.value * 20),
                height: 120 + (_breathingAnimation.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colorAnimation.value?.withOpacity(0.3),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading discussion...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'NouvelR',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
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
              'Could not load discussion',
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
              _error ?? 'Unknown error',
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
              onPressed: _loadDiscussion,
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

  Widget _buildSummaryTab() {
    if (_discussionDetail == null) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      padding: const EdgeInsets.all(80),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _discussionDetail!.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: _discussionDetail!.summary,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'NouvelR',
                    color: Colors.black87,
                    height: 1.6,
                  ),
                  h1: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  h2: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  h3: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  listBullet: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'NouvelR',
                    color: Color(0xFFBF046B),
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NouvelR',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindmapTab() {
    if (_discussionDetail == null) {
      return const Center(child: Text('No data available'));
    }

    // Convert our mindmap data to JSON string for flutter_mindmap
    final mindmapJson = {
      'nodes': _discussionDetail!.mindmap.nodes.map((node) {
        return {
          'id': node.id,
          'label': node.label.replaceAll('\$topic', _discussionDetail!.title),
          'color': node.color,
          if (node.tooltip != null) 'tooltip': node.tooltip,
        };
      }).toList(),
      'edges': _discussionDetail!.mindmap.edges.map((edge) {
        return {
          'from': edge.from,
          'to': edge.to,
        };
      }).toList(),
    };

    final jsonString = jsonEncode(mindmapJson);

    return Container(
      padding: const EdgeInsets.all(40),
      child: MindMapWidget(
        jsonData: jsonString,
        useTreeLayout: true,
        backgroundColor: const Color(0xFFE1DFE2),
        edgeColor: const Color(0xFF535450),
        animationDuration: const Duration(seconds: 2),
        allowNodeOverlap: false,
        expandAllNodesByDefault: false,
        tooltipBackgroundColor: const Color(0xFF535450).withOpacity(0.9),
        tooltipTextColor: Colors.white,
        tooltipTextSize: 14.0,
        tooltipBorderRadius: 10.0,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        tooltipMaxWidth: 280.0,
      ),
    );
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
                // Header section
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
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back to discussions',
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

                // Toggle buttons for Summary / Mindmap
                if (!_isLoading && _error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 20),
                    child: Row(
                      children: [
                        // Summary tab
                        GestureDetector(
                          onTap: () => setState(() => _currentTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 24,
                                  color: _currentTab == 0
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Summary',
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
                        // Mindmap tab
                        GestureDetector(
                          onTap: () => setState(() => _currentTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_tree_outlined,
                                  size: 24,
                                  color: _currentTab == 1
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mindmap',
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
                      ],
                    ),
                  ),

                // Tab content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildErrorState()
                          : _currentTab == 0
                              ? _buildSummaryTab()
                              : _buildMindmapTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
