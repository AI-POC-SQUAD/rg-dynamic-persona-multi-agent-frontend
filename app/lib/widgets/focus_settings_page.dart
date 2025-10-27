import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';
import 'focus_answers_page.dart';

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
  final TextEditingController _topicController = TextEditingController();

  // Show the first selected persona
  late PersonaData _displayPersona;

  @override
  void initState() {
    super.initState();
    // Use the first persona from the selected personas or default to first available persona
    _displayPersona = widget.selectedPersonas.isNotEmpty
        ? widget.selectedPersonas[0]
        : const PersonaData(
            id: 'placeholder',
            name: 'No persona selected',
            description: 'Please add personas to start a discussion.',
          );
  }

  @override
  void dispose() {
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
                            'Set up the conversation',
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
    final String initial = _initialFor(persona);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Color(0xFF535450),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'NouvelR',
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            persona.description,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'NouvelR',
                              color: Colors.black87,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Define the conversation topic.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'NouvelR',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: const Color(0xFFC4C4C4), width: 1),
                  ),
                  child: TextField(
                    controller: _topicController,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter discussion topic',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'NouvelR',
                        color: Color(0xFFC4C4C4),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'NouvelR',
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                        Row(
                          children: [
                            for (int i = 0;
                                i < widget.selectedInstances.length;
                                i++)
                              Tooltip(
                                message:
                                    widget.selectedInstances[i].persona.name,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
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
                                              color: const Color(0xFF535450),
                                              width: 1,
                                            ),
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
                    ElevatedButton(
                      onPressed: _startDiscussion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'NouvelR',
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
    );
  }

  void _startDiscussion() {
    final topic = _topicController.text.isNotEmpty
        ? _topicController.text
        : 'Battery subscription analysis';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusAnswersPage(
          selectedPersonas: widget.selectedPersonas,
          selectedInstances: widget.selectedInstances,
          topic: topic,
          rounds: 3,
        ),
      ),
    );
  }

  String _initialFor(PersonaData persona) {
    final trimmed = persona.name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
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
