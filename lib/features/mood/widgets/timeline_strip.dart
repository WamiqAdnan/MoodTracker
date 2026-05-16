import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/timeline_face_painter.dart';
import 'package:intl/intl.dart';

class TimelineStrip extends StatelessWidget {
  const TimelineStrip({
    super.key,
    required this.entries,
    required this.onEntryTap,
    this.animatingId,
  });

  final List<MoodEntry> entries;
  final String? animatingId;
  final void Function(String id) onEntryTap;

  @override
  Widget build(BuildContext context) {
    final displayed = entries.take(7).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayed.isEmpty ? 7 : displayed.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        if (i >= displayed.length) return _PlaceholderCard(index: i);
        return _TimelineCard(
          entry: displayed[i],
          onTap: () => onEntryTap(displayed[i].id),
        );
      },
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = entry.moodType.color;
    final dateStr = DateFormat('EEE d').format(entry.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          border: Border(left: BorderSide(color: color, width: 3)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(48, 48),
              painter: TimelineFacePainter(
                mood: entry.moodType,
                accentColor: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.moodType.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 9, color: Color(0xFFB0ACBD)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD8D5E2),
          width: 1.5,
          // Dashed effect via a simple muted border
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '?',
            style: TextStyle(
              fontSize: 28,
              color: Color(0xFFD8D5E2),
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
