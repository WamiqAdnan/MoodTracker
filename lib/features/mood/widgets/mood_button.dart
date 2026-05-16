import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';
import 'package:mood_tracker/features/mood/widgets/face_preview_overlay.dart';

class MoodButton extends StatefulWidget {
  const MoodButton({
    super.key,
    required this.mood,
    required this.onTap,
    this.isSelected = false,
    this.faceSize = 80,
    this.showLabel = true,
    this.showBackground = false,
  });

  final MoodType mood;
  final VoidCallback onTap;
  final bool isSelected;
  final double faceSize;
  final bool showLabel;
  final bool showBackground;

  @override
  State<MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<MoodButton>
    with TickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: widget.mood.pulseDuration,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: widget.mood.pulseCurve,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
    } else {
      _scaleController.reverse();
      _pulseController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mood.color;
    final showRing = _hovered || widget.isSelected;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          showFacePreview(context, widget.mood);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.faceSize + 16,
                height: widget.faceSize + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.showBackground
                      ? const Color(0xFF1E1B2E)
                      : Colors.transparent,
                  border: showRing
                      ? Border.all(
                          color: color.withValues(
                            alpha: widget.isSelected ? 1.0 : 0.55,
                          ),
                          width: widget.isSelected ? 2.5 : 1.5,
                        )
                      : Border.all(
                          color: widget.showBackground
                              ? const Color(0xFF2A2740)
                              : Colors.transparent,
                          width: 1.0,
                        ),
                  boxShadow: showRing
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) => CustomPaint(
                      size: Size(widget.faceSize, widget.faceSize),
                      painter: FacePainter(
                        mood: widget.mood,
                        accentColor: color,
                        expressionPulse: _pulseAnimation.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.isSelected ? color : const Color(0xFF8B8FA8),
                  letterSpacing: 0.8,
                ),
                child: Text(widget.mood.label.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
