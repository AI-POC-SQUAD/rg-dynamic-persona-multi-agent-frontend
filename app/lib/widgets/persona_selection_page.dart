import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import 'orizon_chatbot_page.dart';

class PersonaSelectionPage extends StatefulWidget {
  const PersonaSelectionPage({super.key});

  @override
  State<PersonaSelectionPage> createState() => _PersonaSelectionPageState();
}

class _PersonaSelectionPageState extends State<PersonaSelectionPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<PersonaData> personas = PersonaData.getPersonas();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                      // Top row with title and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // DYNAMIC PERSONA title (matching Figma layout)
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
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'PERSONA',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300, // Book weight
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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

                // Persona carousel section
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Column(
                        children: [
                          Text(
                            'Select a customer segment',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Before starting conversation',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // PageView for personas
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemCount: personas.length,
                        itemBuilder: (context, index) {
                          return Center(
                            child: _buildPersonaCard(personas[index], index),
                          );
                        },
                      ),

                      // Left navigation arrow (only show if not on first card)
                      if (_currentIndex > 0)
                        Positioned(
                          left: 60,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentIndex > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF535450),
                                size: 48,
                              ),
                            ),
                          ),
                        ),

                      // Right navigation arrow (only show if not on last card)
                      if (_currentIndex < personas.length - 1)
                        Positioned(
                          right: 120,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentIndex < personas.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF535450),
                                size: 48,
                              ),
                            ),
                          ),
                        ),

                      // Fixed carousel indicators positioned under the persona cards
                      Positioned(
                        bottom: 60, // Position above the bottom text
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            personas.length,
                            (index) {
                              // Specific sizes for each indicator as per Figma design
                              double size;
                              if (index == _currentIndex) {
                                size = 12.0; // Active indicator (largest)
                              } else if ((index - _currentIndex).abs() == 1) {
                                size = 8.0; // Adjacent indicators (medium)
                              } else {
                                size = 4.0; // Far indicators (smallest)
                              }

                              return GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: size == 12.0 ? 8 : 6),
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    color: index == _currentIndex
                                        ? Colors.black
                                        : Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom text
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Explorer les cas d\'utilisation',
                        style: TextStyle(
                          fontSize: 12,
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

          // Right sidebar
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

  Widget _buildPersonaCard(PersonaData persona, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 64),
      child: Center(
        child: SizedBox(
          width: 650, // Fixed width for better proportions
          height: 334,
          child: Stack(
            children: [
              // Background image (full width)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: AssetImage(persona.backgroundAsset),
                      //fit: BoxFit.cover,
                      alignment: AlignmentDirectional(2.5, -0.5),
                      //fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Overlaid persona card (left side)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 400, // Fixed width for card
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
                        // Persona counter
                        Text(
                          'Persona ${index + 1}/5',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Persona name
                        Text(
                          persona.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Description
                        Expanded(
                          child: Text(
                            persona.description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom row with persona selection and Go button
                        Row(
                          children: [
                            // Persona selection indicator
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFC4C4C4), width: 0.5),
                              ),
                              child: Stack(
                                children: [
                                  // Chat icon
                                  const Positioned(
                                    left: 6,
                                    top: 6,
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      size: 15,
                                      color: Color(0xFF535450),
                                    ),
                                  ),
                                  // Masked persona sphere
                                  Positioned(
                                    left: 1,
                                    top: 1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                AssetImage(persona.sphereAsset),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Persona name text
                            Expanded(
                              child: Text(
                                persona.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w200,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Settings icon
                            const Icon(
                              Icons.settings,
                              size: 16,
                              color: Color(0xFF535450),
                            ),

                            const SizedBox(width: 16),

                            // Go button
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrizonChatBotPage(
                                      selectedPersona: persona,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sphere icon in bottom right corner of the image
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFC4C4C4), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      persona.sphereAsset,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
