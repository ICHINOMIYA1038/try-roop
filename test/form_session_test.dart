import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/form_session.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/pose_metrics.dart';

FormSession _session(
  ExerciseKind kind, {
  double? best,
  double? left,
  double? right,
  int reps = 10,
}) {
  return FormSession(
    id: 's',
    userId: 'u1',
    kind: kind,
    reps: reps,
    bestValue: best,
    leftValue: left,
    rightValue: right,
    recordedAt: DateTime(2026, 9, 26),
  );
}

void main() {
  group('記録の保存と読み直し', () {
    test('往復しても値が変わらない', () {
      final s = _session(ExerciseKind.kick, best: 1.2, left: 1.1, right: 1.2);
      final restored = FormSession.fromMap(s.toMap(), 's');

      expect(restored.kind, ExerciseKind.kick);
      expect(restored.reps, 10);
      expect(restored.bestValue, 1.2);
      expect(restored.leftValue, 1.1);
      expect(restored.rightValue, 1.2);
    });

    test('種目が読めなければスクワット扱いにする', () {
      final restored = FormSession.fromMap({
        'userId': 'u1',
        'kind': 'unknown_kind',
        'reps': 3,
        'recordedAt': DateTime(2026, 1, 1).toIso8601String(),
      }, 's');
      expect(restored.kind, ExerciseKind.squat);
    });
  });

  group('前回との比較', () {
    test('スクワットは角度が小さくなったら改善', () {
      final now = _session(ExerciseKind.squat, best: 80);
      final before = _session(ExerciseKind.squat, best: 95);
      expect(now.improvementOver(before), closeTo(15, 0.001));
    });

    test('蹴りは高くなったら改善', () {
      final now = _session(ExerciseKind.kick, best: 1.2);
      final before = _session(ExerciseKind.kick, best: 0.9);
      expect(now.improvementOver(before), closeTo(0.3, 0.001));
    });

    test('前回が無ければ比較しない', () {
      final now = _session(ExerciseKind.squat, best: 80);
      expect(now.improvementOver(null), isNull);
    });
  });

  group('左右差', () {
    test('片側しか測っていなければ出さない', () {
      final s = _session(ExerciseKind.kick, left: 1.0);
      expect(s.symmetry, isNull);
    });

    test('両側あれば弱い方が分かる', () {
      final s = _session(ExerciseKind.kick, left: 0.8, right: 1.1);
      expect(s.symmetry!.isBalanced, isFalse);
      expect(s.symmetry!.weakerSide, Side.left);
    });
  });
}
