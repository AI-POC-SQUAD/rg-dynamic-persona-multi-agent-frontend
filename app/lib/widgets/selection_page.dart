import 'package:flutter/material.dart';
import 'persona_selection_page.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DFE2),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/persona_0.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Main content overlay
          SafeArea(
            child: Column(
              children: [
                // Header section - same as home page
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, left: 80, right: 80),
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

                // Content section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;

                      return Stack(
                        children: [
                          // Main title
                          Positioned(
                            left: screenWidth * 0.5 -
                                800, // Center the text (approximate width 1040px)
                            top: screenHeight * 0.125, // Position from Figma
                            child: SizedBox(
                              width: 1600,
                              child: Text(
                                'STEP INTO THE EXPERIENCE YOU WANT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'NouvelR',
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),

                          // Mode selection cards
                          Positioned(
                            left: screenWidth * 0.5 -
                                414, // Center both cards (total width 828px with 48px gap)
                            top: screenHeight * 0.325,
                            child: Row(
                              children: [
                                // Focus Group card
                                _buildModeCard(
                                  title: 'Focus Group',
                                  description:
                                      'Launch a debate between multiple customer segments and get a synthesis of their combined perspectives.',
                                  onPressed: () {
                                    // TODO: Implement Focus Group functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Focus Group coming soon!'),
                                        backgroundColor: Color(0xFF535450),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(width: 48),

                                // Conversational card
                                _buildModeCard(
                                  title: 'Conversational',
                                  description:
                                      'Interact live with a customer segment to explore their motivations, gather candid answers, and collect valuable insights and data about the topic.',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PersonaSelectionPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Bottom text
                          Positioned(
                            left: screenWidth * 0.5 - 88.5, // Center the text
                            bottom: 16,
                            child: Row(
                              children: [
                                const Text(
                                  'Explorer les cas d\'utilisation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: 'NouvelR',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Colors.white,
                                  size: 16,
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

          // Right sidebar with CTAs - same as home page
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
        ],
      ),
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

  Widget _buildModeCard({
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 390,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 60,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode label
            const Text(
              'Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w200,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                fontFamily: 'NouvelR',
                color: Colors.black,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 58),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                fontFamily: 'NouvelR',
                color: Colors.black,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Go button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Text(
                    'Go',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w200,
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
    );
  }
}
