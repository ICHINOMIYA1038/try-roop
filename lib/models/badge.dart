import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeCondition condition;
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.condition,
    required this.createdAt,
  });

  factory Badge.fromMap(Map<String, dynamic> map, String id) {
    return Badge(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      condition: BadgeCondition.fromMap(map['condition'] ?? {}),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'condition': condition.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class BadgeCondition {
  final BadgeConditionType type;
  final int threshold;
  final String? courseId; // For course completion badge

  BadgeCondition({
    required this.type,
    required this.threshold,
    this.courseId,
  });

  factory BadgeCondition.fromMap(Map<String, dynamic> map) {
    return BadgeCondition(
      type: BadgeConditionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BadgeConditionType.videosWatched,
      ),
      threshold: map['threshold'] ?? 0,
      courseId: map['courseId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'threshold': threshold,
      'courseId': courseId,
    };
  }
}

enum BadgeConditionType {
  videosWatched,      // Watch N videos
  coursesCompleted,   // Complete N courses
  specificCourse,     // Complete specific course
  consecutiveDays,    // Login N consecutive days
  postsCreated,       // Create N posts
  commentsCreated,    // Create N comments
  totalWatchTime,     // Watch for N minutes total
}
