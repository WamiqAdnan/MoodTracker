import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/timeline_face_painter.dart';

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
    // Always show exactly 7 slots: real entries first, placeholders fill the rest.
    final displayed = entries.take(7).toList();
    final placeholderCount = (7 - displayed.length).clamp(0, 7);

    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final entry in displayed)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TimelineCard(
              key: ValueKey(entry.id),
              entry: entry,
              isAnimating: animatingId == entry.id,
              onTap: () => onEntryTap(entry.id),
            ),
          ),
        for (var i = 0; i < placeholderCount; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PlaceholderCard(key: ValueKey('ph_$i')),
          ),
      ],
    );
  }
}

// ── Real card ─────────────────────────────────────────────────────────────────

class _TimelineCard extends StatefulWidget {
  const _TimelineCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.isAnimating = false,
  });

  final MoodEntry entry;
  final VoidCallback onTap;
  final bool isAnimating;

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_TimelineCard old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !old.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.entry.moodType.color;
    final dateStr = DateFormat('EEE d').format(widget.entry.timestamp);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
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
                  mood: widget.entry.moodType,
                  accentColor: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.entry.moodType.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFFB0ACBD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Placeholder card ──────────────────────────────────────────────────────────

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: SizedBox(
        width: 80,
        child: Center(
          child: CustomPaint(
            size: const Size(48, 48),
            painter: _QuestionFacePainter(),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFD8D5E2);
    const dashW = 5.0;
    const dashGap = 4.0;
    const radius = 8.0;
    const strokeW = 1.5;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeW / 2, strokeW / 2, size.width - strokeW,
            size.height - strokeW),
        const Radius.circular(radius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashW).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashW + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter _) => false;
}

class _QuestionFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFD8D5E2);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 * 0.82;

    final fill = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, stroke);

    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.22), r * 0.08, dot);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.22), r * 0.08, dot);

    canvas.drawLine(
      Offset(cx - r * 0.30, cy + r * 0.30),
      Offset(cx + r * 0.30, cy + r * 0.30),
      stroke,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy - r * 0.05),
        width: r * 0.32,
        height: r * 0.28,
      ),
      math.pi + 0.4,
      math.pi + 0.2,
      false,
      stroke,
    );
    canvas.drawCircle(Offset(cx, cy + r * 0.12), r * 0.06, dot);
  }

  @override
  bool shouldRepaint(_QuestionFacePainter _) => false;
}
