import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';

void showFacePreview(BuildContext context, MoodType mood) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, a, b) => _FacePreviewContent(mood: mood),
    transitionBuilder: (ctx, anim, b, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _FacePreviewContent extends StatefulWidget {
  const _FacePreviewContent({required this.mood});
  final MoodType mood;

  @override
  State<_FacePreviewContent> createState() => _FacePreviewContentState();
}

class _FacePreviewContentState extends State<_FacePreviewContent>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.mood.pulseDuration,
    );
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: widget.mood.pulseCurve,
    );
    _pulseCtrl.repeat(reverse: true);
    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder:
                    (ctx, child) => CustomPaint(
                      size: const Size(200, 200),
                      painter: FacePainter(
                        mood: widget.mood,
                        accentColor: widget.mood.color,
                        expressionPulse: _pulseAnim.value,
                      ),
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.mood.label.toUpperCase(),
                style: TextStyle(
                  color: widget.mood.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.mood.previewMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
