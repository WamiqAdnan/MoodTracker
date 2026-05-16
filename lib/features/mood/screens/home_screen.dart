import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';
import 'package:mood_tracker/features/mood/widgets/mood_button.dart';
import 'package:mood_tracker/features/mood/widgets/timeline_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<MoodEntry> _entries = [];

  String? _selectedMoodId;
  String? _animatingEntryId;
  late final AnimationController _addController;
  late final AnimationController _pulseController;

  static const _prefsKey = 'mood_entries';

  @override
  void initState() {
    super.initState();
    _addController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _loadEntries();
  }

  @override
  void dispose() {
    _addController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    final loaded = jsonList
        .map((s) => MoodEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    if (mounted && loaded.isNotEmpty) {
      setState(() => _entries.addAll(loaded));
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _entries.take(50).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void _onMoodTapped(MoodType mood) {
    final entry = MoodEntry.create(mood);
    setState(() {
      _entries.insert(0, entry);
      if (_entries.length > 50) _entries.removeLast();
      _selectedMoodId = entry.id;
      _animatingEntryId = entry.id;
    });

    _saveEntries();
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
    final isEmpty = _entries.isEmpty;

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

            // Mood selector or empty state
            Expanded(
              flex: 55,
              child: isEmpty ? _buildEmptyState() : _buildMoodSelector(),
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

  Widget _buildMoodSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        final faceSize = narrow ? 56.0 : 80.0;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((mood) {
                final isSelected = _selectedMoodId != null &&
                    _entries.isNotEmpty &&
                    _entries.first.id == _selectedMoodId &&
                    _entries.first.moodType == mood;
                return MoodButton(
                  mood: mood,
                  isSelected: isSelected,
                  faceSize: faceSize,
                  showLabel: !narrow,
                  onTap: () => _onMoodTapped(mood),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final scale = 0.92 + 0.08 * _pulseController.value;
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: FacePainter(
                  mood: MoodType.neutral,
                  accentColor: const Color(0xFF9B8EA8),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'tap a mood to begin',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0ACBD),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;
            final faceSize = narrow ? 56.0 : 80.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((mood) {
                return MoodButton(
                  mood: mood,
                  isSelected: false,
                  faceSize: faceSize,
                  showLabel: !narrow,
                  onTap: () => _onMoodTapped(mood),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
