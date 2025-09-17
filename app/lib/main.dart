import 'package:flutter/material.dart';
import 'widgets/orizon_chatbot_page.dart';

void main() {
  runApp(const DynamicPersonaApp());
}

class DynamicPersonaApp extends StatelessWidget {
  const DynamicPersonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orizon Dynamic Persona',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF535450)),
        useMaterial3: true,
      ),
      home: const SelectionArea(
        child: OrizonChatBotPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
