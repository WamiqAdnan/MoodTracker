import 'package:flutter/material.dart';
import 'package:mood_tracker/features/mood/screens/home_screen.dart';

void main() {
  runApp(const MoodTrackerApp());
}

class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF12101F),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
