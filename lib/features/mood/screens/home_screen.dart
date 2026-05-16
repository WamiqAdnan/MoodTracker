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

  _InsightData _getInsight() {
    if (_entries.isEmpty) {
      return _InsightData(
        title: 'Your story starts here',
        detail: 'Every check-in is a small act of self-awareness. Tap a mood above to log how you\'re feeling right now.',
        tags: [],
      );
    }

    final tags = _getInsightTags();

    if (_entries.length < 3) {
      final first = _entries.first.moodType;
      return _InsightData(
        title: 'Good to see you',
        detail: 'You\'ve started checking in — that already takes intention. A few more days and your patterns will start to reveal themselves.',
        tags: tags,
        highlight: first.label,
        highlightColor: first.color,
      );
    }

    // ── Trend ──
    if (_entries.length >= 4) {
      final recentVals = _entries.take(3).map((e) => e.moodType.graphValue).toList();
      final olderList  = _entries.skip(3).take(3).toList();
      if (olderList.isNotEmpty) {
        final recent = recentVals.fold(0, (a, b) => a + b) / recentVals.length;
        final older  = olderList.map((e) => e.moodType.graphValue).fold(0, (a, b) => a + b) / olderList.length;
        final diff   = recent - older;
        if (diff >= 0.7) {
          return _InsightData(
            title: 'Things are looking up',
            detail: 'Your recent check-ins are noticeably more positive than before. Whatever you\'re doing, it seems to be working — keep going.',
            tags: tags,
            highlight: 'Trending up',
            highlightColor: _kPositive,
          );
        }
        if (diff <= -0.7) {
          return _InsightData(
            title: 'A rough stretch lately',
            detail: 'Your mood has been lower recently than it was before. That\'s okay — tough periods pass. Notice what\'s draining you and be gentle with yourself.',
            tags: tags,
            highlight: 'Dipping',
            highlightColor: const Color(0xFFFF7675),
          );
        }
      }
    }

    // ── Best time of day ──
    if (_entries.length >= 5) {
      final timeGroups = <String, List<int>>{};
      for (final e in _entries) {
        final h = e.timestamp.hour;
        final slot = h < 12 ? 'Morning' : h < 17 ? 'Afternoon' : h < 21 ? 'Evening' : 'Night';
        timeGroups.putIfAbsent(slot, () => []).add(e.moodType.graphValue);
      }
      if (timeGroups.length >= 2) {
        final avgs = timeGroups.map((k, v) => MapEntry(k, v.fold(0, (a, b) => a + b) / v.length));
        final best  = avgs.entries.reduce((a, b) => a.value > b.value ? a : b);
        final worst = avgs.entries.reduce((a, b) => a.value < b.value ? a : b);
        if (best.value - worst.value >= 0.6) {
          return _InsightData(
            title: 'You\'re a ${best.key.toLowerCase()} person',
            detail: 'Your energy and mood consistently peak in the ${best.key.toLowerCase()}. If you have something important to do, that\'s your window.',
            tags: tags,
            highlight: best.key,
            highlightColor: _kAccent,
          );
        }
      }
    }

    // ── Best day of week ──
    if (_entries.length >= 7) {
      final dayGroups = <int, List<int>>{};
      for (final e in _entries) {
        dayGroups.putIfAbsent(e.timestamp.weekday, () => []).add(e.moodType.graphValue);
      }
      if (dayGroups.length >= 3) {
        final avgs = dayGroups.map((d, v) => MapEntry(d, v.fold(0, (a, b) => a + b) / v.length));
        final best = avgs.entries.reduce((a, b) => a.value > b.value ? a : b);
        const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayLabel = dayNames[best.key - 1];
        return _InsightData(
          title: '$dayLabel suits you',
          detail: '${dayLabel}s tend to bring out the best in you. You might want to schedule things you enjoy or find challenging on that day.',
          tags: tags,
          highlight: dayLabel,
          highlightColor: _kAccent,
        );
      }
    }

    // ── Most frequent mood ──
    final counts = <MoodType, int>{};
    for (final e in _entries.take(7)) {
      counts[e.moodType] = (counts[e.moodType] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (top.value >= 2) {
      final moodLabel = top.key.label.toLowerCase();
      return _InsightData(
        title: 'Feeling ${top.key.label} a lot lately',
        detail: _moodNarrative(top.key),
        tags: tags,
        highlight: top.key.label,
        highlightColor: top.key.color,
      );
    }

    // ── Streak fallback ──
    final streak = _computeStreak();
    return _InsightData(
      title: streak >= 2 ? 'On a roll' : 'Showing up matters',
      detail: streak >= 2
          ? 'Checking in $streak days in a row is a real habit forming. Self-awareness compounds — the longer you do this the more patterns emerge.'
          : 'Even logging once a week tells a story over time. There\'s no pressure — just notice and record whenever you can.',
      tags: tags,
    );
  }

  String _moodNarrative(MoodType mood) => switch (mood) {
    MoodType.ecstatic => 'You\'ve been riding a real high lately. Savour it, take note of what\'s contributing to it, and see if you can carry any of those conditions forward.',
    MoodType.happy    => 'Things seem to be going well for you. That steady positive baseline is worth protecting — notice what\'s feeding it.',
    MoodType.neutral  => 'You\'ve been holding steady in the middle ground. Neither soaring nor struggling — sometimes that calm consistency is exactly what you need.',
    MoodType.sad      => 'It\'s been a heavier stretch. Acknowledging that is the first step. Think about what small things have lifted your mood before, even briefly.',
    MoodType.awful    => 'You\'ve been going through a difficult time. Be patient with yourself — logging these feelings takes courage and is the start of understanding them.',
  };

  List<String> _getInsightTags() {
    if (_entries.isEmpty) return [];
    final last = _entries.first;
    final hour = last.timestamp.hour;
    final timeTag = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : hour < 21 ? 'Evening' : 'Night';
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
                      data: _getInsight(),
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
    required this.data,
    required this.streak,
    required this.average,
  });

  final _InsightData data;
  final int streak;
  final double average;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // Title + highlight badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (data.highlight != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (data.highlightColor ?? _kAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.highlight!,
                    style: TextStyle(
                      color: data.highlightColor ?? _kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              data.detail,
              style: const TextStyle(
                color: _kTextSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
          if (data.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              children: data.tags.map((t) => _Tag(label: t)).toList(),
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

// ── Insight data model ────────────────────────────────────────────────────────

class _InsightData {
  const _InsightData({
    required this.title,
    required this.detail,
    required this.tags,
    this.highlight,
    this.highlightColor,
  });

  final String title;
  final String detail;
  final List<String> tags;
  final String? highlight;
  final Color? highlightColor;
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
