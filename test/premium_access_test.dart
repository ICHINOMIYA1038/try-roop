import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/models/text_lesson.dart';
import 'package:tryroop_campus_live_flutter/models/video.dart';
import 'package:tryroop_campus_live_flutter/providers/providers.dart';

Video _video(AccessLevel level) {
  final now = DateTime(2026, 1, 1);
  return Video(
    id: 'v1',
    title: '受けの基本',
    description: '',
    youtubeVideoId: 'abc',
    duration: 600,
    accessLevel: level,
    order: 1,
    createdAt: now,
    updatedAt: now,
  );
}

TextLesson _lesson(AccessLevel level) {
  final now = DateTime(2026, 1, 1);
  return TextLesson(
    id: 'l1',
    title: '平安初段の流れ',
    description: '',
    content: null,
    assetPath: 'assets/lessons/karate/kata_heian_shodan.md',
    categoryId: 'karate',
    order: 1,
    estimatedReadingMinutes: 10,
    accessLevel: level,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container({required bool premium}) {
  final container = ProviderContainer(
    overrides: [
      isPremiumProvider.overrideWith((ref) => Stream.value(premium)),
      // 動画の判定は「どれかの講座の第1回か」も見るようになったので、
      // 講座も差し替えておく。ここでは第1回にあたる動画は無い。
      coursesProvider.overrideWith((ref) => Stream.value(const [])),
    ],
  );
  addTearDown(container.dispose);
  // StreamProvider は最初の値が流れるまで待つ。
  container.listen(isPremiumProvider, (_, __) {});
  return container;
}

void main() {
  group('有料コンテンツの判定', () {
    test('無料の動画は課金していなくても見られる', () async {
      final container = _container(premium: false);
      await container.read(isPremiumProvider.future);
      await container.read(coursesProvider.future);

      expect(
        container.read(canAccessVideoProvider(_video(AccessLevel.free))),
        isTrue,
      );
    });

    test('有料の動画は課金していないと見られない', () async {
      final container = _container(premium: false);
      await container.read(isPremiumProvider.future);
      await container.read(coursesProvider.future);

      expect(
        container.read(canAccessVideoProvider(_video(AccessLevel.premium))),
        isFalse,
      );
    });

    test('課金していれば有料の動画も見られる', () async {
      final container = _container(premium: true);
      await container.read(isPremiumProvider.future);
      await container.read(coursesProvider.future);

      expect(
        container.read(canAccessVideoProvider(_video(AccessLevel.premium))),
        isTrue,
      );
    });

    test('有料のレッスンは課金していないと読めない', () async {
      final container = _container(premium: false);
      await container.read(isPremiumProvider.future);
      await container.read(coursesProvider.future);

      expect(
        container.read(canAccessLessonProvider(_lesson(AccessLevel.premium))),
        isFalse,
      );
      expect(
        container.read(canAccessLessonProvider(_lesson(AccessLevel.free))),
        isTrue,
      );
    });

    test('課金状態が分からないうちは有料扱いにする', () {
      final container = ProviderContainer(
        overrides: [
          // 値が流れてこない = 読み込み中
          isPremiumProvider.overrideWith((ref) => const Stream<bool>.empty()),
          coursesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(canAccessVideoProvider(_video(AccessLevel.premium))),
        isFalse,
      );
    });
  });
}
