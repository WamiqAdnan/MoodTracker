import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';
import 'package:mood_tracker/features/mood/widgets/mood_button.dart';
import 'package:mood_tracker/features/mood/widgets/timeline_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF12101F);
const _kCard = Color(0xFF1A1830);
const _kCardBorder = Color(0xFF252240);
const _kAccent = Color(0xFF7C6FF7);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF8B8FA8);
const _kPositive = Color(0xFF4ECDC4);

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
    if (mounted && loaded.isNotEmpty) setState(() => _entries.addAll(loaded));
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
    Future.delayed(const Duration(milliseconds: 1500),
        () { if (mounted) setState(() => _selectedMoodId = null); });
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) setState(() => _animatingEntryId = null); });
  }

  // ── Insight engine ───────────────────────────────────────────────────────────

  String _getInsight() {
    if (_entries.isEmpty) return 'Log your first mood to unlock insights.';
    if (_entries.length < 3) return 'Keep logging daily to reveal your patterns.';

    // Trend: recent 3 vs older
    if (_entries.length >= 4) {
      final recent = _entries.take(3).map((e) => e.moodType.graphValue).fold(0, (a, b) => a + b) / 3;
      final olderList = _entries.skip(3).take(3).toList();
      if (olderList.isNotEmpty) {
        final older = olderList.map((e) => e.moodType.graphValue).fold(0, (a, b) => a + b) / olderList.length;
        if (recent >= older + 0.7) return 'Your mood has been trending up lately. Great momentum!';
        if (recent <= older - 0.7) return 'Your mood has dipped recently. Be kind to yourself.';
      }
    }

    // Best day of week
    if (_entries.length >= 7) {
      final dayGroups = <int, List<int>>{};
      for (final e in _entries) {
        dayGroups.putIfAbsent(e.timestamp.weekday, () => []).add(e.moodType.graphValue);
      }
      if (dayGroups.length >= 3) {
        final dayAvgs = dayGroups.map((d, vals) =>
            MapEntry(d, vals.fold(0, (a, b) => a + b) / vals.length));
        final best = dayAvgs.entries.reduce((a, b) => a.value > b.value ? a : b);
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return 'You tend to feel best on ${days[best.key - 1]}s.';
      }
    }

    // Most frequent mood this week
    final counts = <MoodType, int>{};
    for (final e in _entries.take(7)) {
      counts[e.moodType] = (counts[e.moodType] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (top.value >= 2) return 'You\'ve been logging ${top.key.label} most this week.';

    // Streak fallback
    final streak = _computeStreak();
    return streak >= 2
        ? 'You\'re on a $streak-day streak. Keep it up!'
        : 'Consistency is key. Log daily to see your patterns.';
  }

  List<String> _getInsightTags() {
    if (_entries.isEmpty) return [];
    final last = _entries.first;
    final hour = last.timestamp.hour;
    final timeTag = hour < 12
        ? 'Morning'
        : hour < 17
            ? 'Afternoon'
            : hour < 21
                ? 'Evening'
                : 'Night';
    return [last.moodType.label, timeTag];
  }

  int _computeStreak() {
    if (_entries.isEmpty) return 0;
    final days = _entries
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    final todayN = DateTime(today.year, today.month, today.day);
    final yest = todayN.subtract(const Duration(days: 1));
    if (days.first != todayN && days.first != yest) return 0;
    var streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  double _computeAverage() {
    if (_entries.isEmpty) return 0;
    final list = _entries.take(7).toList();
    return list.map((e) => e.moodType.graphValue).fold(0, (a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _entries.isEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 8),

              // Center section
              Expanded(
                flex: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: 'How are you '),
                          TextSpan(
                            text: 'feeling',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check in with your internal weather.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _kTextSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Mood buttons
                    isEmpty ? _buildEmptyButtons() : _buildMoodRow(),
                  ],
                ),
              ),

              // Bottom cards
              Expanded(
                flex: 42,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _TrendCard(
                      entries: _entries,
                      animatingId: _animatingEntryId,
                    )),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _InsightStatsCard(
                      insight: _getInsight(),
                      tags: _getInsightTags(),
                      streak: _computeStreak(),
                      average: _computeAverage(),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Row(
      children: [
        // Logo avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF9B8FF7), Color(0xFF5B4FE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'MOOD TRACKER',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        // Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'TODAY',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              today,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Profile avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3D3560), Color(0xFF252240)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _kCardBorder, width: 1.5),
          ),
          child: const Center(
            child: Text(
              'U',
              style: TextStyle(
                color: _kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 16;
        final faceSize = ((available - 4 * 10) / 5).clamp(40.0, 72.0);
        final showLabel = faceSize >= 52;
        return Row(
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
              showLabel: showLabel,
              showBackground: true,
              onTap: () => _onMoodTapped(mood),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyButtons() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) => Transform.scale(
            scale: 0.92 + 0.08 * _pulseController.value,
            child: CustomPaint(
              size: const Size(72, 72),
              painter: FacePainter(
                mood: MoodType.neutral,
                accentColor: const Color(0xFF9B8EA8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'tap a mood to begin',
          style: TextStyle(fontSize: 13, color: _kTextSecondary),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth - 16;
            final faceSize = ((available - 4 * 10) / 5).clamp(40.0, 72.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((mood) => MoodButton(
                mood: mood,
                isSelected: false,
                faceSize: faceSize,
                showLabel: faceSize >= 52,
                showBackground: true,
                onTap: () => _onMoodTapped(mood),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Trend card ────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.entries, this.animatingId});

  final List<MoodEntry> entries;
  final String? animatingId;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY TREND',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TimelineStrip(
              entries: entries,
              animatingId: animatingId,
              onEntryTap: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Combined insight + stats card ─────────────────────────────────────────────

class _InsightStatsCard extends StatelessWidget {
  const _InsightStatsCard({
    required this.insight,
    required this.tags,
    required this.streak,
    required this.average,
  });

  final String insight;
  final List<String> tags;
  final int streak;
  final double average;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insight section
          const Text(
            'INSIGHT',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              children: tags.map((t) => _Tag(label: t)).toList(),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: _kCardBorder),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STREAK',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'days',
                          style: TextStyle(
                              color: _kTextSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: _kCardBorder),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVERAGE',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          average > 0 ? average.toStringAsFixed(1) : '--',
                          style: const TextStyle(
                            color: _kPositive,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 5',
                          style: TextStyle(
                              color: _kTextSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kAccent,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}
