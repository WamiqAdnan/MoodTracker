import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum MoodType { ecstatic, happy, neutral, sad, awful }

extension MoodTypeX on MoodType {
  String get label => switch (this) {
        MoodType.ecstatic => 'Ecstatic',
        MoodType.happy => 'Happy',
        MoodType.neutral => 'Neutral',
        MoodType.sad => 'Sad',
        MoodType.awful => 'Awful',
      };

  Color get color => switch (this) {
        MoodType.ecstatic => const Color(0xFFFFD166),
        MoodType.happy => const Color(0xFFFFB347),
        MoodType.neutral => const Color(0xFF9B8EA8),
        MoodType.sad => const Color(0xFF6B9FD4),
        MoodType.awful => const Color(0xFFD46B6B),
      };

  double get mouthCurve => switch (this) {
        MoodType.ecstatic => 1.0,
        MoodType.happy => 0.6,
        MoodType.neutral => 0.0,
        MoodType.sad => -0.6,
        MoodType.awful => -1.0,
      };

  double get browAngle => switch (this) {
        MoodType.ecstatic => -0.4,
        MoodType.happy => -0.2,
        MoodType.neutral => 0.0,
        MoodType.sad => 0.3,
        MoodType.awful => 0.5,
      };

  bool get hasTeeth => this == MoodType.ecstatic;

  int get graphValue => switch (this) {
        MoodType.awful => 1,
        MoodType.sad => 2,
        MoodType.neutral => 3,
        MoodType.happy => 4,
        MoodType.ecstatic => 5,
      };
}

class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.moodType,
    required this.timestamp,
  });

  factory MoodEntry.create(MoodType moodType) => MoodEntry(
        id: const Uuid().v4(),
        moodType: moodType,
        timestamp: DateTime.now(),
      );

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'] as String,
        moodType: MoodType.values.firstWhere((m) => m.name == j['mood']),
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
      );

  final String id;
  final MoodType moodType;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mood': moodType.name,
        'ts': timestamp.millisecondsSinceEpoch,
      };
}
