import 'package:flutter/material.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/face_painter.dart';

class MoodButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: mood.color, width: 3)
                  : null,
            ),
            child: CustomPaint(
              size: const Size(80, 80),
              painter: FacePainter(
                mood: mood,
                accentColor: mood.color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mood.label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9AAB)),
          ),
        ],
      ),
    );
  }
}
