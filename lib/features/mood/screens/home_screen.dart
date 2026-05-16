import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/widgets/mood_button.dart';
import 'package:mood_tracker/features/mood/widgets/timeline_strip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<MoodEntry> _entries = [];
  String? _selectedMoodId;
  String? _animatingEntryId;
  late final AnimationController _addController;

  @override
  void initState() {
    super.initState();
    _addController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _onMoodTapped(MoodType mood) {
    final entry = MoodEntry.create(mood);
    setState(() {
      _entries.insert(0, entry);
      if (_entries.length > 50) _entries.removeLast();
      _selectedMoodId = entry.id;
      _animatingEntryId = entry.id;
    });

    _addController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _selectedMoodId = null);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _animatingEntryId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'how are you feeling?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3A4A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    today,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9AAB),
                    ),
                  ),
                ],
              ),
            ),

            // Mood selector
            Expanded(
              flex: 55,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: MoodType.values.map((mood) {
                      return MoodButton(
                        mood: mood,
                        isSelected: _selectedMoodId != null &&
                            _entries.isNotEmpty &&
                            _entries.first.id == _selectedMoodId &&
                            _entries.first.moodType == mood,
                        onTap: () => _onMoodTapped(mood),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Divider label
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'LAST 7 ENTRIES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB0ACBD),
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Timeline strip
            Expanded(
              flex: 30,
              child: TimelineStrip(
                entries: _entries,
                animatingId: _animatingEntryId,
                onEntryTap: (id) {},
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
