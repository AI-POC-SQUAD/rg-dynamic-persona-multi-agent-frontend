import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import '../utils/fade_page_route.dart';
import 'selection_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _useVideoPlayer = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkVideoCompatibility();
    _setupFallbackAnimation();
  }

  void _checkVideoCompatibility() {
    // Check if we're running in WASM mode or if video player should be avoided
    // In WASM mode, video player might not work properly
    if (kIsWeb) {
      // Try to initialize video with a timeout
      _initializeVideo();
    } else {
      _initializeVideo();
    }
  }

  void _setupFallbackAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void _initializeVideo() {
    _videoController =
        VideoPlayerController.asset('assets/videos/sphere_animation.mp4');

    // Add a timeout for video initialization
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isVideoInitialized && mounted) {
        setState(() {
          _useVideoPlayer = false;
        });
      }
    });

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _useVideoPlayer = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0.0); // Mute the video
        _videoController.play();
      }
    }).catchError((error) {
      print('Error initializing video: $error');
      if (mounted) {
        setState(() {
          _useVideoPlayer = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: GestureDetector(
        onTap: () {
          // Navigate to selection page on any tap
          context.pushWithFade(
            const SelectionPage(),
          );
        },
        child: Stack(
          children: [
            // Main content overlay
            SafeArea(
              child: Column(
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.only(top: 24, left: 80, right: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left side - Navigation tabs
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildExperienceTab('Home'),
                                const SizedBox(width: 20),
                                _buildExperienceTab('About'),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // DYNAMIC PERSONA title - exactly as in Figma
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
                              ),
                            ),
                            const Text(
                              'PERSONA',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300, // Book
                                fontFamily: 'NouvelR',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Center content with sphere animation behind text
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenHeight = constraints.maxHeight;

                        return Stack(
                          children: [
                            // Background sphere animation positioned behind and slightly left/bottom of text
                            Positioned(
                              left: 0, // More to the left
                              bottom: 0, // Higher up
                              child: SizedBox(
                                width: screenHeight *
                                    1.5, // Much larger to match screenshot proportions
                                child: _useVideoPlayer && _isVideoInitialized
                                    ? ClipRRect(
                                        child: AspectRatio(
                                          aspectRatio: 1.23, // Square
                                          child: VideoPlayer(_videoController),
                                        ),
                                      )
                                    : AnimatedBuilder(
                                        animation: _scaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _scaleAnimation.value,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(325),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFFE8E6E9),
                                                    Color(0xFFDDD9DD),
                                                    Color(0xFFD1CCD1),
                                                    Color(0xFFE8E6E9),
                                                  ],
                                                  stops: [0.0, 0.3, 0.7, 1.0],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Right sidebar with CTAs - matching Figma design
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
                        const SizedBox(height: 8),
                        // Message button
                        Container(
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.chat_bubble_outline,
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

            // Welcome message centered on entire screen - positioned last to appear on top
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome message
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ), // Closing GestureDetector
    );
  }

  Widget _buildExperienceTab(String experience) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        experience,
        style: TextStyle(
          fontSize: 15,
          fontWeight: experience == 'Home' ? FontWeight.bold : FontWeight.w300,
          fontFamily: 'NouvelR',
          color: Colors.black,
        ),
      ),
    );
  }
}
