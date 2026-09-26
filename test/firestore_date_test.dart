import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/models/firestore_date.dart';
import 'package:tryroop_campus_live_flutter/models/video.dart';

void main() {
  group('Firestore の日時を読む', () {
    final expected = DateTime.utc(2026, 9, 26, 4, 30);

    test('Timestamp で入っていても読める', () {
      // 本番のデータはすべてこの形。以前はここで例外になり、
      // 動画もコースもレッスンも1件も表示できなかった。
      final value = Timestamp.fromDate(expected);
      expect(parseDate(value).toUtc(), expected);
    });

    test('ISO 文字列でも読める', () {
      expect(parseDate(expected.toIso8601String()).toUtc(), expected);
    });

    test('DateTime がそのまま入っていても読める', () {
      expect(parseDate(expected).toUtc(), expected);
    });

    test('ミリ秒の数値でも読める', () {
      expect(
        parseDate(expected.millisecondsSinceEpoch).toUtc(),
        expected,
      );
    });

    test('読めない値でも例外にしない', () {
      // 1件壊れていただけで一覧全体が出なくなるのを避ける。
      expect(parseDate(null), DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseDate('これは日付ではない'),
          DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseDate(const {'a': 1}),
          DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('省略可能な日時は null を返す', () {
      expect(parseDateOrNull(null), isNull);
      expect(parseDateOrNull('でたらめ'), isNull);
      expect(parseDateOrNull(Timestamp.fromDate(expected))!.toUtc(), expected);
    });
  });

  group('本番の形のデータを読む', () {
    test('Timestamp で書かれた動画が読める', () {
      final now = DateTime.utc(2026, 9, 26);

      final video = Video.fromMap({
        'title': '受けの基本',
        'description': '',
        'youtubeVideoId': 'abc',
        'duration': 600,
        'accessLevel': 'free',
        'order': 1,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, 'v1');

      expect(video.title, '受けの基本');
      expect(video.createdAt.toUtc(), now);
    });

    test('日時が抜けていても読める', () {
      final video = Video.fromMap({
        'title': '型の基本',
        'description': '',
        'youtubeVideoId': 'abc',
        'duration': 0,
        'accessLevel': 'free',
        'order': 1,
      }, 'v2');

      expect(video.title, '型の基本');
    });
  });
}
