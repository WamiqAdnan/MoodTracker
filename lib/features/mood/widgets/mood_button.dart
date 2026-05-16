import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';

class MoodButton extends StatefulWidget {
  const MoodButton({
    super.key,
    required this.mood,
    required this.onTap,
    this.isSelected = false,
  });

  final MoodType mood;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  State<MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<MoodButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
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
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: showRing
                      ? Border.all(
                          color: color.withOpacity(widget.isSelected ? 1.0 : 0.55),
                          width: widget.isSelected ? 3.0 : 2.0,
                        )
                      : Border.all(color: Colors.transparent, width: 2.0),
                  boxShadow: showRing
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: FacePainter(
                    mood: widget.mood,
                    accentColor: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w400,
                color: widget.isSelected ? color : const Color(0xFF9E9AAB),
              ),
              child: Text(widget.mood.label),
            ),
          ],
        ),
      ),
    );
  }
}
