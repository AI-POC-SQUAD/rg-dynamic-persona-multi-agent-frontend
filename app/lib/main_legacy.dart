import 'package:flutter/material.dart';
import 'widgets/orizon_chatbot_page.dart';

void main() {
  runApp(const DynamicPersonaApp());
}

class DynamicPersonaApp extends StatelessWidget {
  const DynamicPersonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: MaterialApp(
        title: 'Orizon Dynamic Persona',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF535450)),
          useMaterial3: true,
        ),
        home: const OrizonChatBotPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Legacy ChatPage - Replaced by OrizonChatBotPage
// The old implementation has been moved to a separate file for reference
