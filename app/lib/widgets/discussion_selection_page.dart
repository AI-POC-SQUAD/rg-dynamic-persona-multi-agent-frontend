import 'package:flutter/material.dart';
import '../models/discussion.dart';
import '../services/api_client.dart';
import '../utils/fade_page_route.dart';
import 'focus_answers_page.dart';

class DiscussionSelectionPage extends StatefulWidget {
  const DiscussionSelectionPage({super.key});

  @override
  State<DiscussionSelectionPage> createState() =>
      _DiscussionSelectionPageState();
}

class _DiscussionSelectionPageState extends State<DiscussionSelectionPage> {
  final PageController _pageController = PageController();
  final ApiClient _apiClient = ApiClient();

  int _currentIndex = 0;
  List<Discussion> _discussions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final discussions = await _apiClient.fetchDiscussions();
      if (!mounted) return;
      setState(() {
        _discussions = discussions;
        _currentIndex = discussions.isNotEmpty ? 0 : 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _selectDiscussion(Discussion discussion) {
    Navigator.of(context).push(
      FadePageRoute(
        child: FocusAnswersPage(
          discussionId: discussion.id,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
              'Could not load discussions',
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
              onPressed: _loadDiscussions,
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

  Widget _buildDiscussionCard(Discussion discussion, int index) {
    final isCenter = index == _currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: isCenter ? 40 : 80,
        vertical: isCenter ? 100 : 120,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isCenter ? 0.15 : 0.08),
            blurRadius: isCenter ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _selectDiscussion(discussion),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 48,
                  color: Color(0xFFBF046B),
                ),
                const SizedBox(height: 20),
                Text(
                  discussion.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Discussion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NouvelR',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscussions =
        !_isLoading && _errorMessage == null && _discussions.isNotEmpty;
    final canNavigate = hasDiscussions && _discussions.length > 1;

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // DYNAMIC PERSONA title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DYNAMIC',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'PERSONA',
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
                      // Refresh button
                      IconButton(
                        onPressed: _loadDiscussions,
                        icon: const Icon(Icons.refresh),
                        iconSize: 32,
                        color: const Color(0xFF000000),
                        tooltip: 'Refresh discussions',
                      ),
                    ],
                  ),
                ),

                // Discussion carousel section
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: const [
                          SizedBox(height: 40),
                          Text(
                            'Select a discussion to view',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_errorMessage != null)
                        _buildErrorState()
                      else if (_discussions.isEmpty)
                        const Center(
                          child: Text(
                            'No discussions available right now.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: _discussions.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: _buildDiscussionCard(
                                  _discussions[index], index),
                            );
                          },
                        ),

                      // Left navigation arrow
                      if (canNavigate && _currentIndex > 0)
                        Positioned(
                          left: 60,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF000000),
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                      // Right navigation arrow
                      if (canNavigate &&
                          _currentIndex < _discussions.length - 1)
                        Positioned(
                          right: 60,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF000000),
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                      // Page indicator dots
                      if (hasDiscussions && _discussions.length > 1)
                        Positioned(
                          bottom: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _discussions.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentIndex == index ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? const Color(0xFF000000)
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
