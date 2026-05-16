import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';

// Same logic as FacePainter, tuned for a 48×48 canvas.
class TimelineFacePainter extends CustomPainter {
  const TimelineFacePainter({
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
    final radius = math.min(cx, cy) * 0.82;

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
        ..strokeWidth = 1.5,
    );
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final eyeY = cy - radius * 0.22;
    canvas.drawCircle(Offset(cx - radius * 0.30, eyeY), radius * 0.10, paint);
    canvas.drawCircle(Offset(cx + radius * 0.30, eyeY), radius * 0.10, paint);
  }

  void _drawBrows(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final browY = cy - radius * 0.42;
    final eyeOffsetX = radius * 0.30;
    final hw = radius * 0.20;

    if (mood == MoodType.ecstatic || mood == MoodType.happy) {
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
      final drop = hw * math.sin(mood.browAngle);
      for (final sign in [-1.0, 1.0]) {
        final bx = cx + sign * eyeOffsetX;
        final outerX = bx - sign * hw;
        final innerX = bx + sign * hw;
        canvas.drawLine(
          Offset(outerX, browY - drop),
          Offset(innerX, browY + drop),
          paint,
        );
      }
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mouthY = cy + radius * 0.32;
    final halfW = radius * 0.38;
    final curve = mood.mouthCurve;
    final cornerDrop = mood == MoodType.awful ? radius * 0.10 : 0.0;
    final cpY = mouthY + curve * radius * 0.30;

    final path = Path()
      ..moveTo(cx - halfW, mouthY + cornerDrop)
      ..cubicTo(
        cx - halfW * 0.5,
        cpY,
        cx + halfW * 0.5,
        cpY,
        cx + halfW,
        mouthY + cornerDrop,
      );
    canvas.drawPath(path, paint);

    if (mood.hasTeeth) {
      final teethCpY = mouthY + curve * radius * 0.14;
      canvas.drawPath(
        Path()
          ..moveTo(cx - halfW * 0.72, mouthY + radius * 0.06)
          ..cubicTo(
            cx - halfW * 0.3,
            teethCpY,
            cx + halfW * 0.3,
            teethCpY,
            cx + halfW * 0.72,
            mouthY + radius * 0.06,
          ),
        Paint()
          ..color = accentColor.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCheeks(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - radius * 0.55, cy + radius * 0.08),
        width: radius * 0.22,
        height: radius * 0.13,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + radius * 0.55, cy + radius * 0.08),
        width: radius * 0.22,
        height: radius * 0.13,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(TimelineFacePainter old) =>
      old.mood != mood ||
      old.accentColor != accentColor ||
      old.animationValue != animationValue;
}
