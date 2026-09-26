import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/models/live_schedule.dart';

LiveSchedule _live({
  required DateTime at,
  int duration = 15,
  LiveStatus status = LiveStatus.scheduled,
  bool isFree = false,
}) =>
    LiveSchedule(
      id: 'l1',
      title: '15分ボクササイズ',
      description: '',
      scheduledAt: at,
      duration: duration,
      status: status,
      isFree: isFree,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final now = DateTime.now();

  group('いま配信中かの判定', () {
    test('開始時刻を過ぎていれば、状態を切り替えていなくても配信中', () {
      final s = _live(at: now.subtract(const Duration(minutes: 5)));
      expect(s.isLiveNow, isTrue);
    });

    test('開始5分前から入れる', () {
      expect(_live(at: now.add(const Duration(minutes: 3))).isLiveNow, isTrue);
      expect(_live(at: now.add(const Duration(minutes: 30))).isLiveNow, isFalse);
    });

    test('終了予定を過ぎたら配信中ではない', () {
      final s = _live(at: now.subtract(const Duration(minutes: 30)));
      expect(s.isLiveNow, isFalse);
    });

    test('状態が「配信中」なら時刻に関係なく配信中（延びた場合）', () {
      final s = _live(
        at: now.subtract(const Duration(hours: 2)),
        status: LiveStatus.live,
      );
      expect(s.isLiveNow, isTrue);
    });

    test('状態が「終了」なら時刻内でも配信中ではない', () {
      final s = _live(at: now, status: LiveStatus.ended);
      expect(s.isLiveNow, isFalse);
    });

    test('長い配信は終了予定まで配信中のまま', () {
      final s = _live(
        at: now.subtract(const Duration(minutes: 40)),
        duration: 60,
      );
      expect(s.isLiveNow, isTrue);
    });
  });

  group('公開範囲', () {
    test('既定は有料', () {
      expect(_live(at: now).isFree, isFalse);
    });

    test('保存して読み直しても残る', () {
      final s = _live(at: now, isFree: true);
      final back = LiveSchedule.fromMap(s.toMap(), 'l1');
      expect(back.isFree, isTrue);
    });

    test('古いデータに isFree が無ければ有料扱い', () {
      final back = LiveSchedule.fromMap({
        'title': 'x',
        'description': '',
        'scheduledAt': now.toIso8601String(),
        'duration': 15,
        'status': 'scheduled',
        'createdAt': now.toIso8601String(),
      }, 'l1');
      expect(back.isFree, isFalse);
    });
  });
}
