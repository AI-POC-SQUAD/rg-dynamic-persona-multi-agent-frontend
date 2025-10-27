import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';
import '../services/api_client.dart';
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
  final ApiClient _apiClient = ApiClient();

  int _currentIndex = 0;
  List<PersonaData> _personas = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selected persona instances for focus group (max 5)
  final List<PersonaInstance> _selectedPersonas = [];

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final personas = await _apiClient.fetchPersonas();
      if (!mounted) return;
      setState(() {
        _personas = personas;
        _currentIndex = personas.isNotEmpty ? 0 : 0;
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
    final hasPersonas =
        !_isLoading && _errorMessage == null && _personas.isNotEmpty;
    final canNavigate = hasPersonas && _personas.length > 1;

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
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_errorMessage != null)
                        Center(
                          child: _buildErrorState(),
                        )
                      else if (_personas.isEmpty)
                        const Center(
                          child: Text(
                            'No personas available right now.',
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
                          itemCount: _personas.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child:
                                  _buildPersonaCard(_personas[index], index),
                            );
                          },
                        ),

                      // Left navigation arrow (only show if not on first card)
                      if (canNavigate && _currentIndex > 0)
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
                      if (canNavigate && _currentIndex < _personas.length - 1)
                        Positioned(
                          right: 120,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentIndex < _personas.length - 1) {
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
                      if (hasPersonas)
                        Positioned(
                          bottom: 120, // Position above the bottom text
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _personas.length,
                              (index) {
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
                                      duration:
                                          const Duration(milliseconds: 300),
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

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Unable to load personas.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            fontFamily: 'NouvelR',
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadPersonas,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  String _initialFor(PersonaData persona) {
    final trimmed = persona.name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  Widget _buildPersonaCard(PersonaData persona, int index) {
    final bool canSelectMore = _selectedPersonas.length < 5;
    final String initial = _initialFor(persona);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persona ${index + 1}/${_personas.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  persona.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  persona.description.isNotEmpty
                      ? persona.description
                      : 'No description provided.',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        persona.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          canSelectMore ? () => _selectPersona(persona) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(canSelectMore ? 'Select' : 'Max 5'),
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
                                Center(
                                  child: Text(
                                    _initialFor(
                                        _selectedPersonas[index].persona),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NouvelR',
                                      color: Colors.black,
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
