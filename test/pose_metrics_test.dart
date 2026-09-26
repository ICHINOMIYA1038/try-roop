import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/pose_metrics.dart';

PoseFrame _frame(Map<Joint, PosePoint> points) => PoseFrame(points);

void main() {
  group('角度', () {
    test('まっすぐ伸びていれば180度', () {
      final f = _frame({
        Joint.leftHip: const PosePoint(0, 0),
        Joint.leftKnee: const PosePoint(0, 10),
        Joint.leftAnkle: const PosePoint(0, 20),
      });
      expect(f.kneeAngle(Side.left), closeTo(180, 0.001));
    });

    test('直角に曲がっていれば90度', () {
      final f = _frame({
        Joint.leftHip: const PosePoint(0, 0),
        Joint.leftKnee: const PosePoint(0, 10),
        Joint.leftAnkle: const PosePoint(10, 10),
      });
      expect(f.kneeAngle(Side.left), closeTo(90, 0.001));
    });

    test('点が足りなければ null', () {
      final f = _frame({Joint.leftHip: const PosePoint(0, 0)});
      expect(f.kneeAngle(Side.left), isNull);
    });

    test('確からしさが低い点は無いものとして扱う', () {
      final f = _frame({
        Joint.leftHip: const PosePoint(0, 0),
        Joint.leftKnee: const PosePoint(0, 10, likelihood: 0.2),
        Joint.leftAnkle: const PosePoint(0, 20),
      });
      expect(f.kneeAngle(Side.left), isNull);
    });
  });

  group('蹴りの高さ', () {
    // 肩 y=0、腰 y=100 なので体幹の長さは 100。
    Map<Joint, PosePoint> base() => {
          Joint.leftShoulder: const PosePoint(0, 0),
          Joint.rightShoulder: const PosePoint(20, 0),
          Joint.leftHip: const PosePoint(0, 100),
          Joint.rightHip: const PosePoint(20, 100),
        };

    test('腰と同じ高さなら比率は0', () {
      final f = _frame({...base(), Joint.rightAnkle: const PosePoint(60, 100)});
      expect(f.kickHeightRatio(Side.right), closeTo(0, 0.001));
    });

    test('肩と同じ高さなら比率は1', () {
      final f = _frame({...base(), Joint.rightAnkle: const PosePoint(60, 0)});
      expect(f.kickHeightRatio(Side.right), closeTo(1, 0.001));
    });

    test('腰より下なら比率は負', () {
      final f = _frame({...base(), Joint.rightAnkle: const PosePoint(60, 150)});
      expect(f.kickHeightRatio(Side.right)!, lessThan(0));
    });

    test('段の判定', () {
      expect(classifyKickHeight(-0.3), KickLevel.gedan);
      expect(classifyKickHeight(0.5), KickLevel.chudan);
      expect(classifyKickHeight(1.2), KickLevel.jodan);
    });

    test('段の表示名', () {
      expect(KickLevel.jodan.label, '上段');
    });
  });

  group('回数を数える', () {
    RepCounter counter() =>
        RepCounter(downThreshold: 100, upThreshold: 160);

    test('下がって戻って1回', () {
      final c = counter();
      for (final v in [170.0, 140.0, 95.0, 130.0, 165.0]) {
        c.add(v);
      }
      expect(c.count, 1);
    });

    test('下がりきらなければ数えない', () {
      final c = counter();
      for (final v in [170.0, 140.0, 120.0, 170.0]) {
        c.add(v);
      }
      expect(c.count, 0);
    });

    test('しきい値の境目で震えても二重に数えない', () {
      final c = counter();
      // 下のしきい値のまわりを何度も行き来させる
      for (final v in [170.0, 99.0, 101.0, 98.0, 102.0, 97.0]) {
        c.add(v);
      }
      expect(c.count, 0);
      expect(c.isDown, isTrue);

      c.add(165.0);
      expect(c.count, 1);
    });

    test('各回のいちばん深いところを残す', () {
      final c = counter();
      for (final v in [170.0, 90.0, 75.0, 88.0, 165.0]) {
        c.add(v);
      }
      for (final v in [140.0, 99.0, 165.0]) {
        c.add(v);
      }
      expect(c.count, 2);
      expect(c.depths[0], 75.0);
      expect(c.depths[1], 99.0);
    });

    test('骨格が取れなかったフレームは無視する', () {
      final c = counter();
      c.add(170.0);
      c.add(null);
      c.add(90.0);
      c.add(null);
      c.add(165.0);
      expect(c.count, 1);
    });

    test('リセットで元に戻る', () {
      final c = counter();
      for (final v in [170.0, 90.0, 165.0]) {
        c.add(v);
      }
      c.reset();
      expect(c.count, 0);
      expect(c.depths, isEmpty);
      expect(c.isDown, isFalse);
    });
  });

  group('左右差', () {
    test('同じなら偏っていない', () {
      const s = Symmetry(left: 1.0, right: 1.0);
      expect(s.isBalanced, isTrue);
      expect(s.difference, 0);
    });

    test('2割ちがえば偏っている', () {
      const s = Symmetry(left: 0.8, right: 1.0);
      expect(s.isBalanced, isFalse);
      expect(s.imbalanceRatio, closeTo(0.2, 0.001));
      expect(s.weakerSide, Side.left);
    });

    test('どちらも0なら割り算で落ちない', () {
      const s = Symmetry(left: 0, right: 0);
      expect(s.imbalanceRatio, 0);
      expect(s.isBalanced, isTrue);
    });
  });
}
