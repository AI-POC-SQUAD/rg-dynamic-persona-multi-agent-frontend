import 'package:flutter/material.dart';
import '../models/persona_data.dart';
import '../models/persona_instance.dart';

class FocusAnswersPage extends StatefulWidget {
  final List<PersonaData> selectedPersonas;
  final List<PersonaInstance> selectedInstances;
  final String topic;
  final int rounds;

  const FocusAnswersPage({
    super.key,
    required this.selectedPersonas,
    required this.selectedInstances,
    required this.topic,
    required this.rounds,
  });

  @override
  State<FocusAnswersPage> createState() => _FocusAnswersPageState();
}

class _FocusAnswersPageState extends State<FocusAnswersPage> {
  bool _showRoundSteps = false; // Toggle between Result and Round Steps
  String _analysisText = '';

  @override
  void initState() {
    super.initState();
    // Initialize with mock analysis text based on the Figma design
    _analysisText = _getMockAnalysisText();
  }

  String _getMockAnalysisText() {
    return """We can conclude that a battery subscription is a potentially good idea, but only if it is targeted at very specific customer segments. It is by no means a one-size-fits-all solution. Here is a detailed analysis based on the study's data.

The Battery Subscription Concept in the Study

The concept is directly addressed in the survey. To the question, "What would make you reduce your range expectations?", the option "Battery leasing (renting the EV's battery separately to reduce the initial cost and offer flexibility)" was proposed. The results vary considerably across segments:

• Status-driven commuters: This is the most interested group, with a 26% favorable response rate.
• Convenience buyers: Moderate interest at 19%.
• Environment evangelists: Moderate interest at 19%.
• Price-conscious errand drivers: Low interest at 11%.
• EV skeptic traditionalists: Very low interest at 10%.

This initial finding is already counter-intuitive: the most price-sensitive segments are the least interested in this cost-reduction solution.""";
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
                // Header section (reused from focus_settings_page)
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
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Back to start',
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

                // Toggle buttons for Result / Round Steps
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                  child: Row(
                    children: [
                      // Result tab
                      GestureDetector(
                        onTap: () => setState(() => _showRoundSteps = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 24,
                                color: !_showRoundSteps
                                    ? Colors.black
                                    : const Color(0xFFC4C4C4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Result',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NouvelR',
                                  color: !_showRoundSteps
                                      ? Colors.black
                                      : const Color(0xFFC4C4C4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Round Steps tab
                      GestureDetector(
                        onTap: () => setState(() => _showRoundSteps = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 24,
                                color: _showRoundSteps
                                    ? Colors.black
                                    : const Color(0xFFC4C4C4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Round Steps',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NouvelR',
                                  color: _showRoundSteps
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

                // Divider line
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 80),
                  height: 1,
                  color: const Color(0xFFC4C4C4),
                ),

                // Content area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(80),
                    child: _showRoundSteps
                        ? _buildRoundStepsView()
                        : _buildResultView(),
                  ),
                ),

                // Bottom conversation section (reused from focus_settings_page)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject: ${widget.topic}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'NouvelR',
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Selected personas row (reused from focus_settings_page)
                      Row(
                        children: [
                          for (int i = 0;
                              i < widget.selectedInstances.length;
                              i++)
                            Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                clipBehavior: Clip.none,
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
                                            color: const Color(0xFF535450),
                                            width: 1),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Persona sphere
                                          Positioned.fill(
                                            child: ClipOval(
                                              child: Image.asset(
                                                widget.selectedInstances[i]
                                                    .persona.sphereAsset,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Number overlay
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF535450),
                                        borderRadius: BorderRadius.circular(8),
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
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom explorer text (reused from focus_settings_page)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Explorer les cas d\'utilisation',
                        style: TextStyle(
                          fontSize: 10,
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

          // Right sidebar (reused from focus_settings_page)
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

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Text(
          _analysisText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            fontFamily: 'NouvelR',
            color: Colors.black,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundStepsView() {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Group Rounds Progress',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                fontFamily: 'NouvelR',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            for (int round = 1; round <= widget.rounds; round++)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    'Round $round',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'NouvelR',
                      color: Colors.black,
                    ),
                  ),
                  children: [
                    for (int i = 0; i < widget.selectedInstances.length; i++)
                      ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF535450)),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              widget.selectedInstances[i].persona.sphereAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          widget.selectedInstances[i].persona.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'NouvelR',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          'Round $round response would appear here...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'NouvelR',
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
