import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';
import '../utils/fade_page_route.dart';
import 'focus_settings_page.dart';

class FocusPersonaSelectionPage extends StatefulWidget {
  const FocusPersonaSelectionPage({super.key});

  @override
  State<FocusPersonaSelectionPage> createState() =>
      _FocusPersonaSelectionPageState();
}

class _FocusPersonaSelectionPageState extends State<FocusPersonaSelectionPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final List<PersonaData> personas = PersonaData.getPersonas();

  // Selected persona instances for focus group (max 5)
  final List<PersonaInstance> _selectedPersonas = [];

  void _selectPersona(PersonaData persona) {
    setState(() {
      // Always add a new instance with current settings (no more max limit check for same persona)
      if (_selectedPersonas.length < 5) {
        _selectedPersonas.add(PersonaInstance.defaultFor(persona));
      }
    });
  }

  void _removePersonaInstance(PersonaInstance instance) {
    setState(() {
      _selectedPersonas.remove(instance);
    });
  }

  bool get _isStartButtonEnabled => _selectedPersonas.length >= 2;

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
                      // Top row with title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
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
                            'Select a segment to converse',
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
                        bottom: 120, // Position above the bottom text
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
                                        : Colors.black
                                            .withValues(alpha: 0.3),
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

                // Selected personas display and Start button
                Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSelectedPersonasDisplay(),
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
          width: 650 * 1.3, // Fixed width for better proportions
          height: 334 * 1.5,
          child: Stack(
            children: [
              // Background image (full width)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(42),
                    image: DecorationImage(
                      image: AssetImage(persona.backgroundAsset),
                      //fit: BoxFit.cover,
                      alignment: AlignmentDirectional(5.5, -0.5),
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
                  width: 500, // Fixed width for card
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Persona counter
                        Text(
                          'Persona ${index + 1}/5',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                          ),
                        ),

                        //const SizedBox(height: 16),

                        // Persona name
                        Text(
                          persona.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'NouvelR',
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Persona description
                        Expanded(
                          child: Text(
                            persona.description,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom row with persona selection and Go button
                        Row(
                          children: [
                            // Persona selection indicator
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(21),
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
                                        width: 40,
                                        height: 40,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w200,
                                  fontFamily: 'NouvelR',
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Select persona button (always clickable)
                            GestureDetector(
                              onTap: _selectedPersonas.length < 5
                                  ? () => _selectPersona(persona)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPersonas.length < 5
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Text(
                                  _selectedPersonas.length < 5
                                      ? 'Select'
                                      : 'Max 5',
                                  style: const TextStyle(
                                    fontSize: 21,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border:
                        Border.all(color: const Color(0xFFC4C4C4), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      persona.sphereAsset,
                      width: 40,
                      height: 40,
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

  Widget _buildSelectedPersonasDisplay() {
    return Column(
      children: [
        // "Your selection" text
        const Text(
          'Your selection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            fontFamily: 'NouvelR',
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        // Row with numbered circles and Start button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 5 numbered circles for persona selection
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final bool hasPersona = index < _selectedPersonas.length;
                return Container(
                  width: 50, // Increased to accommodate overflow
                  height: 50, // Increased to accommodate overflow
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    clipBehavior: Clip.none, // Allow overflow
                    children: [
                      // Main circle
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasPersona
                                ? Colors.white
                                : const Color(0xFFC4C4C4),
                            shape: BoxShape.circle,
                            border: hasPersona
                                ? Border.all(
                                    color: const Color(0xFF535450), width: 1)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // Persona sphere background (if selected)
                              if (hasPersona)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Image.asset(
                                      _selectedPersonas[index]
                                          .persona
                                          .sphereAsset,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              // Number text for empty slots (centered)
                              if (!hasPersona)
                                Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'NouvelR',
                                      color: Color(0xFFC4C4C4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Cross button with number on top-right (if selected)
                      if (hasPersona)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removePersonaInstance(
                                _selectedPersonas[index]),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'X',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NouvelR',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(width: 32),

            // Start button
            GestureDetector(
              onTap: _isStartButtonEnabled
                  ? () {
                      context.pushWithFade(
                        FocusSettingsPage(
                          selectedPersonas: _selectedPersonas
                              .map((instance) => instance.persona)
                              .toList(),
                          selectedInstances: _selectedPersonas,
                        ),
                      );
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isStartButtonEnabled
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color(0xFFC4C4C4),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'NouvelR',
                    color: _isStartButtonEnabled ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
