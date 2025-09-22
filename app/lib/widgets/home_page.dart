import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'orizon_chatbot_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedExperience;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController =
        VideoPlayerController.asset('assets/videos/sphere_animation.mp4');
    _videoController.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // Mute the video
      _videoController.play();
    }).catchError((error) {
      print('Error initializing video: $error');
      // If video fails to load, we'll just show the gradient fallback
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _selectExperience(String experience) {
    setState(() {
      _selectedExperience = experience;
    });

    // Navigate to the appropriate page based on selection
    if (experience == 'Experience#1') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrizonChatBotPage(),
        ),
      );
    } else if (experience == 'Experience#2') {
      // Future implementation for Experience#2
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Experience#2 coming soon!'),
          backgroundColor: Color(0xFF535450),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          // Main content overlay
          SafeArea(
            child: Column(
              children: [
                // Header section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Experience navigation
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildExperienceTab('Experience#1'),
                            const SizedBox(width: 20),
                            _buildExperienceTab('Experience#2'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // DYNAMIC PERSONA title
                      const Text(
                        'DYNAMIC PERSONA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'L\'(a)vie de nos clients, en conversation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center content with sphere animation behind text
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;

                      return Stack(
                        children: [
                          // Background sphere animation positioned behind and slightly left/bottom of text
                          Positioned(
                            left: 0, // More to the left
                            bottom: 0, // Higher up
                            child: SizedBox(
                              width: screenHeight *
                                  0.7, // Much larger to match screenshot proportions
                              height:
                                  screenHeight * 0.7, // Square aspect, larger
                              child: _isVideoInitialized
                                  ? ClipRRect(
                                      child: AspectRatio(
                                        aspectRatio: 1.23, // Square
                                        child: VideoPlayer(_videoController),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(325),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFE8E6E9),
                                            Color(0xFFDDD9DD),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          // Welcome message centered horizontally
                          Positioned(
                            left: screenWidth * 0.5 -
                                195, // Center the text block (approximate width 350px)
                            top: screenHeight * 0.34, // Keep vertical position
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome message
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'welcome, ',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'NouvelR',
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Nathalie',
                                        style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w300,
                                            fontFamily: 'NouvelR',
                                            color: Colors.black,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Interaction instructions centered below welcome text
                          Positioned(
                            left: screenWidth * 0.5 -
                                120, // Center the instructions (approximate width 245px)
                            top: screenHeight * 0.41, // Below welcome text
                            child: Row(
                              children: [
                                const Text(
                                  'Click to type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'NouvelR',
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF535450),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Text(
                                  'Press and hold',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'NouvelR',
                                    color: Colors.black,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildExperienceTab(String experience) {
    final isSelected = _selectedExperience == experience;

    return GestureDetector(
      onTap: () => _selectExperience(experience),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF535450) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF535450) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          experience,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            fontFamily: 'NouvelR',
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
