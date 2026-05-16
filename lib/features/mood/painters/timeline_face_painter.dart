import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';

// Same logic as FacePainter but tuned for a 48×48 canvas.
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
        ..color = accentColor.withOpacity(0.20)
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
    final eyeOffsetX = radius * 0.30;
    final eyeRadius = radius * 0.10;

    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), eyeRadius, paint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), eyeRadius, paint);
  }

  void _drawBrows(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final browY = cy - radius * 0.42;
    final eyeOffsetX = radius * 0.30;
    final browHalfW = radius * 0.18;

    if (mood == MoodType.ecstatic || mood == MoodType.happy) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: browHalfW * 2.2,
        height: browHalfW * 1.2,
      );
      for (final sign in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(cx + sign * eyeOffsetX, browY);
        canvas.drawArc(rect, math.pi, math.pi, false, paint);
        canvas.restore();
      }
    } else if (mood == MoodType.neutral) {
      for (final sign in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(cx + sign * eyeOffsetX - browHalfW, browY),
          Offset(cx + sign * eyeOffsetX + browHalfW, browY),
          paint,
        );
      }
    } else {
      final angle = mood.browAngle;
      for (final sign in [-1.0, 1.0]) {
        final bx = cx + sign * eyeOffsetX;
        final path = Path()
          ..moveTo(bx - sign * browHalfW, browY + browHalfW * math.sin(angle))
          ..lineTo(bx + sign * browHalfW, browY - browHalfW * math.sin(angle));
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mouthY = cy + radius * 0.30;
    final halfW = radius * 0.38;
    final curve = mood.mouthCurve;
    final cornerDrop = mood == MoodType.awful ? radius * 0.12 : 0.0;

    final startX = cx - halfW;
    final endX = cx + halfW;
    final cpY = mouthY - curve * radius * 0.28;

    final path = Path()
      ..moveTo(startX, mouthY + cornerDrop)
      ..cubicTo(
        startX + halfW * 0.5, cpY,
        endX - halfW * 0.5, cpY,
        endX, mouthY + cornerDrop,
      );
    canvas.drawPath(path, paint);

    if (mood.hasTeeth) {
      final teethPath = Path()
        ..moveTo(startX + halfW * 0.15, mouthY + radius * 0.04)
        ..cubicTo(
          startX + halfW * 0.5, mouthY - curve * radius * 0.10 + radius * 0.08,
          endX - halfW * 0.5, mouthY - curve * radius * 0.10 + radius * 0.08,
          endX - halfW * 0.15, mouthY + radius * 0.04,
        );
      canvas.drawPath(
        teethPath,
        Paint()
          ..color = accentColor.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCheeks(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final cheekY = cy + radius * 0.08;
    final cheekOffsetX = radius * 0.55;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - cheekOffsetX, cheekY),
        width: radius * 0.22,
        height: radius * 0.13,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + cheekOffsetX, cheekY),
        width: radius * 0.22,
        height: radius * 0.13,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(TimelineFacePainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.animationValue != animationValue;
}
