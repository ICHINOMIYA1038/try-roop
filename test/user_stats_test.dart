import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/models/user_stats.dart';

void main() {
  group('UserStats', () {
    test('読了したレッスンが保存して読み直しても残る', () {
      final stats = UserStats.empty('u1').copyWith(
        completedLessonIds: ['lesson_karate_5', 'lesson_karate_7'],
      );

      final restored = UserStats.fromMap(stats.toMap(), 'u1');

      expect(restored.completedLessonIds,
          ['lesson_karate_5', 'lesson_karate_7']);
    });

    test('古いデータに completedLessonIds が無くても読める', () {
      final restored = UserStats.fromMap({
        'totalWatchTime': 30,
        'completedCourses': 1,
        'completedVideos': 2,
        'badgeIds': <String>[],
        'consecutiveDays': 3,
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      }, 'u1');

      expect(restored.completedLessonIds, isEmpty);
      expect(restored.completedVideos, 2);
    });
  });
}
