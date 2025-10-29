import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/discussion_selection_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (optional for production)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file. Using environment variables: $e');
    // In production/Docker, environment variables will be available via runtime config
  }

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
        child: DiscussionSelectionPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
