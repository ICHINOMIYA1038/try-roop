import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/form_check_controller.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/form_session.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/pose_metrics.dart';

/// 膝の角度が [angle] になるような骨格を作る。
/// 腰を真上、足首を真横に置くと、角度は 0〜180 の間で作れる。
PoseFrame squatFrame({required double leftAngle, required double rightAngle}) {
  PosePoint ankleFor(double angleDeg, double kneeX) {
    // 膝(kneeX,10) を頂点に、腰は(kneeX,0)。足首は角度ぶん回した位置に置く。
    final rad = angleDeg * math.pi / 180;
    // 腰方向のベクトルは (0,-1)。そこから angle だけ回した向きに足首を置く。
    final dx = -math.sin(rad);
    final dy = -math.cos(rad);
    return PosePoint(kneeX + dx * 10, 10 + dy * 10);
  }

  return PoseFrame({
    Joint.leftHip: const PosePoint(0, 0),
    Joint.leftKnee: const PosePoint(0, 10),
    Joint.leftAnkle: ankleFor(leftAngle, 0),
    Joint.rightHip: const PosePoint(30, 0),
    Joint.rightKnee: const PosePoint(30, 10),
    Joint.rightAnkle: ankleFor(rightAngle, 30),
  });
}

/// 蹴り足の高さが体幹比 [ratio] になる骨格。肩 y=0、腰 y=100。
PoseFrame kickFrame({double? left, double? right}) {
  final points = <Joint, PosePoint>{
    Joint.leftShoulder: const PosePoint(0, 0),
    Joint.rightShoulder: const PosePoint(20, 0),
    Joint.leftHip: const PosePoint(0, 100),
    Joint.rightHip: const PosePoint(20, 100),
  };
  if (left != null) {
    points[Joint.leftAnkle] = PosePoint(60, 100 - left * 100);
  }
  if (right != null) {
    points[Joint.rightAnkle] = PosePoint(60, 100 - right * 100);
  }
  return PoseFrame(points);
}

void main() {
  group('スクワット', () {
    test('しゃがんで立ったら1回', () {
      final c = FormCheckController(kind: ExerciseKind.squat);

      for (final a in [175.0, 140.0, 90.0, 140.0, 175.0]) {
        c.onFrame(squatFrame(leftAngle: a, rightAngle: a));
      }

      expect(c.reps, 1);
    });

    test('浅いと数えない', () {
      final c = FormCheckController(kind: ExerciseKind.squat);

      for (final a in [175.0, 150.0, 130.0, 175.0]) {
        c.onFrame(squatFrame(leftAngle: a, rightAngle: a));
      }

      expect(c.reps, 0);
    });

    test('いちばん深かった角度が残る', () {
      final c = FormCheckController(kind: ExerciseKind.squat);

      for (final a in [175.0, 120.0, 85.0, 120.0, 175.0]) {
        c.onFrame(squatFrame(leftAngle: a, rightAngle: a));
      }

      expect(c.bestValue!, closeTo(85, 2));
    });

    test('左右差が出る', () {
      final c = FormCheckController(kind: ExerciseKind.squat);

      // 右だけ深くしゃがめている
      for (final pair in [[175.0, 175.0], [110.0, 85.0], [175.0, 175.0]]) {
        c.onFrame(squatFrame(leftAngle: pair[0], rightAngle: pair[1]));
      }

      final s = c.symmetry!;
      expect(s.isBalanced, isFalse);
      // 角度が大きい = 浅い = 弱い側。weakerSide は値が小さい方を返すので、
      // スクワットでは「深い方」が返る点に注意して比較する。
      expect(c.bestLeft!, greaterThan(c.bestRight!));
    });
  });

  group('蹴り', () {
    test('足を上げて下ろしたら1回', () {
      final c = FormCheckController(kind: ExerciseKind.kick);

      for (final r in [-0.2, 0.1, 0.6, 1.1, 0.4, -0.2]) {
        c.onFrame(kickFrame(right: r));
      }

      expect(c.reps, 1);
      expect(c.bestValue!, closeTo(1.1, 0.001));
    });

    test('上がりきらなければ数えない', () {
      final c = FormCheckController(kind: ExerciseKind.kick);

      for (final r in [-0.2, 0.1, 0.2, -0.2]) {
        c.onFrame(kickFrame(right: r));
      }

      expect(c.reps, 0);
    });

    test('左右それぞれの最高到達点を覚える', () {
      final c = FormCheckController(kind: ExerciseKind.kick);

      c.onFrame(kickFrame(left: 0.9, right: 1.2));
      c.onFrame(kickFrame(left: 0.4, right: 0.3));

      expect(c.bestLeft!, closeTo(0.9, 0.001));
      expect(c.bestRight!, closeTo(1.2, 0.001));
      expect(c.symmetry!.weakerSide, Side.left);
    });
  });

  group('共通', () {
    test('骨格が取れないフレームでは計測中にならない', () {
      final c = FormCheckController(kind: ExerciseKind.squat);
      c.onFrame(const PoseFrame({}));

      expect(c.isTracking, isFalse);
      expect(c.reps, 0);
    });

    test('リセットで最初に戻る', () {
      final c = FormCheckController(kind: ExerciseKind.squat);
      for (final a in [175.0, 90.0, 175.0]) {
        c.onFrame(squatFrame(leftAngle: a, rightAngle: a));
      }
      expect(c.reps, 1);

      c.reset();

      expect(c.reps, 0);
      expect(c.bestValue, isNull);
      expect(c.isTracking, isFalse);
    });

    test('記録として保存できる形になる', () {
      final c = FormCheckController(kind: ExerciseKind.kick);
      c.onFrame(kickFrame(left: 0.8, right: 1.1));

      final session = c.buildSession('u1');

      expect(session.userId, 'u1');
      expect(session.kind, ExerciseKind.kick);
      expect(session.bestValue!, closeTo(1.1, 0.001));
      expect(session.symmetry!.weakerSide, Side.left);
    });
  });
}
