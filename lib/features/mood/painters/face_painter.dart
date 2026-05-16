import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';

class FacePainter extends CustomPainter {
  const FacePainter({
    required this.mood,
    required this.accentColor,
    this.animationValue = 1.0,
  });

  final MoodType mood;
  final Color accentColor;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * 0.85;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(animationValue);
    canvas.translate(-cx, -cy);

    _drawHead(canvas, cx, cy, radius);
    _drawEyes(canvas, cx, cy, radius);
    _drawBrows(canvas, cx, cy, radius);
    _drawMouth(canvas, cx, cy, radius);
    if (mood == MoodType.ecstatic || mood == MoodType.happy) {
      _drawCheeks(canvas, cx, cy, radius);
    }

    canvas.restore();
  }

  void _drawHead(Canvas canvas, double cx, double cy, double radius) {
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = accentColor.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final eyeY = cy - radius * 0.22;
    final eyeOffsetX = radius * 0.30;
    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), radius * 0.10, paint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), radius * 0.10, paint);
  }

  void _drawBrows(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final browY = cy - radius * 0.42;
    final eyeOffsetX = radius * 0.30;
    final hw = radius * 0.20; // half-width of each brow

    if (mood == MoodType.ecstatic || mood == MoodType.happy) {
      // Arch curving upward above each eye (∩ shape)
      for (final sign in [-1.0, 1.0]) {
        final bx = cx + sign * eyeOffsetX;
        final path = Path()
          ..moveTo(bx - hw, browY)
          ..quadraticBezierTo(bx, browY - hw * 0.8, bx + hw, browY);
        canvas.drawPath(path, paint);
      }
    } else if (mood == MoodType.neutral) {
      for (final sign in [-1.0, 1.0]) {
        final bx = cx + sign * eyeOffsetX;
        canvas.drawLine(Offset(bx - hw, browY), Offset(bx + hw, browY), paint);
      }
    } else {
      // Furrowed: inner corner angled downward toward center (\  /)
      final drop = hw * math.sin(mood.browAngle);
      for (final sign in [-1.0, 1.0]) {
        final bx = cx + sign * eyeOffsetX;
        // outer end: normal height; inner end (toward nose): lower
        final outerY = browY - drop;
        final innerY = browY + drop;
        final outerX = bx - sign * hw;
        final innerX = bx + sign * hw;
        canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), paint);
      }
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final mouthY = cy + radius * 0.32;
    final halfW = radius * 0.38;
    final curve = mood.mouthCurve;

    // Positive curve → control point below endpoints → ∪ = smile
    // Negative curve → control point above endpoints → ∩ = frown
    final cornerDrop = mood == MoodType.awful ? radius * 0.10 : 0.0;
    final startY = mouthY + cornerDrop;
    final endY = mouthY + cornerDrop;
    final cpY = mouthY + curve * radius * 0.30;

    final path = Path()
      ..moveTo(cx - halfW, startY)
      ..cubicTo(cx - halfW * 0.5, cpY, cx + halfW * 0.5, cpY, cx + halfW, endY);
    canvas.drawPath(path, paint);

    // Teeth hint for ecstatic (inner arc, lighter)
    if (mood.hasTeeth) {
      final teethPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final teethCpY = mouthY + curve * radius * 0.14;
      final teethPath = Path()
        ..moveTo(cx - halfW * 0.72, mouthY + radius * 0.06)
        ..cubicTo(
          cx - halfW * 0.3,
          teethCpY,
          cx + halfW * 0.3,
          teethCpY,
          cx + halfW * 0.72,
          mouthY + radius * 0.06,
        );
      canvas.drawPath(teethPath, teethPaint);
    }
  }

  void _drawCheeks(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final cheekY = cy + radius * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - radius * 0.55, cheekY),
        width: radius * 0.24,
        height: radius * 0.14,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + radius * 0.55, cheekY),
        width: radius * 0.24,
        height: radius * 0.14,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(FacePainter old) =>
      old.mood != mood ||
      old.accentColor != accentColor ||
      old.animationValue != animationValue;
}
