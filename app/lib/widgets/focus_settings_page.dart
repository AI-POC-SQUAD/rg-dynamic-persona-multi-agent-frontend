import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';

class FocusSettingsPage extends StatefulWidget {
  final List<PersonaData> selectedPersonas;
  final List<PersonaInstance> selectedInstances;

  const FocusSettingsPage({
    super.key,
    required this.selectedPersonas,
    required this.selectedInstances,
  });

  @override
  State<FocusSettingsPage> createState() => _FocusSettingsPageState();
}

class _FocusSettingsPageState extends State<FocusSettingsPage> {
  final TextEditingController _roundsController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  // Show the first selected persona
  late PersonaData _displayPersona;

  @override
  void initState() {
    super.initState();
    // Use the first persona from the selected personas or default to first available persona
    _displayPersona = widget.selectedPersonas.isNotEmpty
        ? widget.selectedPersonas[0]
        : PersonaData.getPersonas()[0];
  }

  @override
  void dispose() {
    _roundsController.dispose();
    _topicController.dispose();
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

                // Content section
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
                          SizedBox(height: 8),
                          Text(
                            'Before starting focus group',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Single persona card display
                      Center(
                        child: _buildPersonaCard(_displayPersona),
                      ),
                    ],
                  ),
                ),

                // Settings and selected personas display
                Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSettingsSection(),
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

  Widget _buildPersonaCard(PersonaData persona) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 64),
      child: Center(
        child: SizedBox(
          width: 650 * 1.5, // Fixed width for better proportions
          height: 334 * 1.7,
          child: Stack(
            children: [
              // Background image (full width)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(42),
                    image: DecorationImage(
                      image: AssetImage(persona.backgroundAsset),
                      alignment: AlignmentDirectional(4.5, -0.5),
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
                  width: 600, // Fixed width for card
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                        // Back arrow
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: Color(0xFF535450),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const SizedBox(height: 24),

                        // "Define the depth of the conversation" text
                        Center(
                          child: const Text(
                            'Define the depth of the conversation.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Rounds input field (centered)
                        Center(
                          child: Container(
                            width: 400,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFC4C4C4), width: 1),
                            ),
                            child: TextField(
                              controller: _roundsController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Indicate how many rounds',
                                hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'NouvelR',
                                  color: Color(0xFFC4C4C4),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NouvelR',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        Center(
                          child: const Text(
                            'Define the conversation topic.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Topic input field (centered)
                        Center(
                          child: Container(
                            width: 400,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFC4C4C4), width: 1),
                            ),
                            child: TextField(
                              controller: _topicController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Enter discussion topic',
                                hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'NouvelR',
                                  color: Color(0xFFC4C4C4),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NouvelR',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Selected personas and Go button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Selected personas section on the left
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected personas:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'NouvelR',
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Show selected personas with sphere icons
                                Row(
                                  children: [
                                    for (int i = 0;
                                        i < widget.selectedInstances.length;
                                        i++)
                                      Tooltip(
                                        message:
                                            '${widget.selectedInstances[i].persona.name}\n${widget.selectedInstances[i].settingsSummary}',
                                        child: Container(
                                          width:
                                              48, // Increased to accommodate overflow
                                          height:
                                              48, // Increased to accommodate overflow
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          child: Stack(
                                            clipBehavior:
                                                Clip.none, // Allow overflow
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
                                                        color: const Color(
                                                            0xFF535450),
                                                        width: 1),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      // Persona sphere
                                                      Positioned.fill(
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                            widget
                                                                .selectedInstances[
                                                                    i]
                                                                .persona
                                                                .sphereAsset,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Number overlay (outside main circle)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF535450),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${i + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w400,
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
                            // Go button on the right
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to focus group conversation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Starting focus group with ${widget.selectedInstances.length} personas for ${_roundsController.text.isNotEmpty ? _roundsController.text : 'default'} rounds${_topicController.text.isNotEmpty ? ' on topic: ${_topicController.text}' : ''}'),
                                    backgroundColor: const Color(0xFF535450),
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

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Text(
            'Focus group settings configured',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'NouvelR',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.selectedInstances.length} personas selected',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              fontFamily: 'NouvelR',
              color: Color(0xFF535450),
            ),
          ),
        ],
      ),
    );
  }
}
