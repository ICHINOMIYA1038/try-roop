import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/try_loop/today_try.dart';

void main() {
  group('誘い文', () {
    test('題名だけを出す（分は前に付けない）', () {
      const t = TodayTry(
        title: '15分ボクササイズ',
        minutes: 15,
        targetId: 'x',
        isLive: true,
      );
      expect(t.invitation, '今日は「15分ボクササイズ」に挑戦！');
    });
  });

  group('所要時間の表示', () {
    test('題名にすでに分が入っていれば出さない', () {
      const t = TodayTry(
        title: '15分ボクササイズ',
        minutes: 15,
        targetId: 'x',
        isLive: true,
      );
      expect(t.durationLabel, isNull);
    });

    test('題名に入っていなければ出す', () {
      const t = TodayTry(
        title: 'はじめての韓国語',
        minutes: 15,
        targetId: 'x',
        isLive: false,
      );
      expect(t.durationLabel, '15分');
    });

    test('長さが分からなければ出さない', () {
      const t = TodayTry(
        title: 'はじめての韓国語',
        minutes: 0,
        targetId: 'x',
        isLive: false,
      );
      expect(t.durationLabel, isNull);
    });

    test('別の分数が題名に入っていても、自分の分数は出す', () {
      const t = TodayTry(
        title: '10分ストレッチ',
        minutes: 15,
        targetId: 'x',
        isLive: false,
      );
      expect(t.durationLabel, '15分');
    });
  });
}
