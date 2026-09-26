import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/try_loop/try_record.dart';

TryRecord _rec(DateTime at, {String? category, String target = 't'}) => TryRecord(
      id: 'x',
      userId: 'u1',
      kind: TryKind.video,
      targetId: target,
      categoryId: category,
      completedAt: at,
    );

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 12);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('ドキュメントID', () {
    test('同じ日の同じ対象は同じIDになる（二重に数えない）', () {
      final a = TryRecord.buildId(
          userId: 'u1',
          kind: TryKind.video,
          targetId: 'v1',
          on: DateTime(2026, 9, 26, 9));
      final b = TryRecord.buildId(
          userId: 'u1',
          kind: TryKind.video,
          targetId: 'v1',
          on: DateTime(2026, 9, 26, 22));
      expect(a, b);
      expect(a, 'u1_video_v1_20260926');
    });

    test('日が変われば別のIDになる', () {
      final a = TryRecord.buildId(
          userId: 'u1', kind: TryKind.video, targetId: 'v1',
          on: DateTime(2026, 9, 26));
      final b = TryRecord.buildId(
          userId: 'u1', kind: TryKind.video, targetId: 'v1',
          on: DateTime(2026, 9, 27));
      expect(a, isNot(b));
    });
  });

  group('集計', () {
    test('今月の回数を数える', () {
      final s = TrySummary([
        _rec(today),
        _rec(daysAgo(1)),
        _rec(DateTime(2020, 1, 1)),
      ]);
      expect(s.thisMonth, greaterThanOrEqualTo(1));
      expect(s.total, 3);
    });

    test('挑戦したジャンルを数える', () {
      final s = TrySummary([
        _rec(today, category: 'workout'),
        _rec(daysAgo(1), category: 'workout'),
        _rec(daysAgo(2), category: 'korean'),
        _rec(daysAgo(3)),
      ]);
      expect(s.categories, {'workout', 'korean'});
    });

    test('今日やったかどうか', () {
      expect(TrySummary([_rec(today)]).doneToday, isTrue);
      expect(TrySummary([_rec(daysAgo(1))]).doneToday, isFalse);
      expect(const TrySummary([]).doneToday, isFalse);
    });
  });

  group('連続日数', () {
    test('記録が無ければ0', () {
      expect(const TrySummary([]).streakDays, 0);
    });

    test('今日から3日続いていれば3', () {
      final s = TrySummary([_rec(today), _rec(daysAgo(1)), _rec(daysAgo(2))]);
      expect(s.streakDays, 3);
    });

    test('同じ日に複数あっても1日として数える', () {
      final s = TrySummary([
        _rec(today, target: 'a'),
        _rec(today, target: 'b'),
        _rec(daysAgo(1)),
      ]);
      expect(s.streakDays, 2);
    });

    test('今日まだでも昨日やっていれば途切れていない', () {
      final s = TrySummary([_rec(daysAgo(1)), _rec(daysAgo(2))]);
      expect(s.streakDays, 2);
    });

    test('2日以上空いていたら途切れている', () {
      final s = TrySummary([_rec(daysAgo(3)), _rec(daysAgo(4))]);
      expect(s.streakDays, 0);
    });

    test('途中で空いたらそこで止まる', () {
      final s = TrySummary([
        _rec(today),
        _rec(daysAgo(1)),
        _rec(daysAgo(5)),
        _rec(daysAgo(6)),
      ]);
      expect(s.streakDays, 2);
    });
  });
}
