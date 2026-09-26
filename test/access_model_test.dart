import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/models/course.dart';
import 'package:tryroop_campus_live_flutter/models/video.dart';
import 'package:tryroop_campus_live_flutter/providers/providers.dart';

final _now = DateTime(2026, 9, 26);

Video _video(String id, AccessLevel level) => Video(
      id: id,
      title: id,
      description: '',
      youtubeVideoId: 'yt_$id',
      duration: 900,
      accessLevel: level,
      order: 1,
      createdAt: _now,
      updatedAt: _now,
    );

Course _course(String id, List<String> videoIds) => Course(
      id: id,
      title: id,
      description: '',
      videoIds: videoIds,
      totalDuration: 45,
      difficulty: CourseDifficulty.beginner,
      isPublished: true,
      createdAt: _now,
      updatedAt: _now,
    );

ProviderContainer _container({required bool premium}) {
  final container = ProviderContainer(overrides: [
    isPremiumProvider.overrideWith((ref) => Stream.value(premium)),
    coursesProvider.overrideWith(
      (ref) => Stream.value([
        // 韓国語初心者コース: 第1回〜第3回
        _course('korean', ['ko_1', 'ko_2', 'ko_3']),
        _course('boxing', ['bx_1', 'bx_2']),
      ]),
    ),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('各講座の第1回のみ無料', () {
    test('第1回は課金していなくても見られる', () async {
      final c = _container(premium: false);
      await c.read(isPremiumProvider.future);
      await c.read(coursesProvider.future);

      expect(c.read(canAccessVideoProvider(_video('ko_1', AccessLevel.premium))),
          isTrue);
      expect(c.read(canAccessVideoProvider(_video('bx_1', AccessLevel.premium))),
          isTrue);
    });

    test('第2回以降は課金していないと見られない', () async {
      final c = _container(premium: false);
      await c.read(isPremiumProvider.future);
      await c.read(coursesProvider.future);

      expect(c.read(canAccessVideoProvider(_video('ko_2', AccessLevel.premium))),
          isFalse);
      expect(c.read(canAccessVideoProvider(_video('ko_3', AccessLevel.premium))),
          isFalse);
    });

    test('課金すれば全部見られる', () async {
      final c = _container(premium: true);
      await c.read(isPremiumProvider.future);
      await c.read(coursesProvider.future);

      expect(c.read(canAccessVideoProvider(_video('ko_3', AccessLevel.premium))),
          isTrue);
    });

    test('無料指定の動画は講座に入っていなくても見られる', () async {
      final c = _container(premium: false);
      await c.read(isPremiumProvider.future);
      await c.read(coursesProvider.future);

      expect(c.read(canAccessVideoProvider(_video('single', AccessLevel.free))),
          isTrue);
    });

    test('講座に入っていない有料の単発動画は見られない', () async {
      final c = _container(premium: false);
      await c.read(isPremiumProvider.future);
      await c.read(coursesProvider.future);

      expect(
          c.read(canAccessVideoProvider(_video('single', AccessLevel.premium))),
          isFalse);
    });
  });
}
