import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/form_result_sheet.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/form_session.dart';

FormSession _session({
  ExerciseKind kind = ExerciseKind.kick,
  int reps = 10,
  double? best,
  double? left,
  double? right,
  DateTime? at,
}) {
  return FormSession(
    id: 's',
    userId: 'u1',
    kind: kind,
    reps: reps,
    bestValue: best,
    leftValue: left,
    rightValue: right,
    recordedAt: at ?? DateTime(2026, 9, 26),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('回数と到達点が出る', (tester) async {
    await _pump(
      tester,
      FormResultSheet(session: _session(reps: 12, best: 1.2)),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('上段'), findsOneWidget);
    expect(find.text('結果を共有する'), findsOneWidget);
  });

  testWidgets('スクワットは角度で出る', (tester) async {
    await _pump(
      tester,
      FormResultSheet(
        session: _session(kind: ExerciseKind.squat, reps: 8, best: 84.4),
      ),
    );

    expect(find.text('8'), findsOneWidget);
    expect(find.text('84度'), findsOneWidget);
  });

  testWidgets('前回より良くなったら伝える', (tester) async {
    await _pump(
      tester,
      FormResultSheet(
        session: _session(best: 1.2),
        previous: _session(best: 0.8),
      ),
    );

    expect(find.text('前回より良くなっています'), findsOneWidget);
  });

  testWidgets('前回が無ければ比較を出さない', (tester) async {
    await _pump(tester, FormResultSheet(session: _session(best: 1.2)));

    expect(find.textContaining('前回より'), findsNothing);
  });

  testWidgets('左右差があれば知らせる', (tester) async {
    await _pump(
      tester,
      FormResultSheet(session: _session(best: 1.2, left: 0.9, right: 1.2)),
    );

    expect(find.textContaining('左が'), findsOneWidget);
  });

  testWidgets('左右が揃っていれば何も言わない', (tester) async {
    await _pump(
      tester,
      FormResultSheet(session: _session(best: 1.2, left: 1.2, right: 1.2)),
    );

    expect(find.textContaining('届いていません'), findsNothing);
  });

  testWidgets('値が取れていなくても落ちない', (tester) async {
    await _pump(tester, FormResultSheet(session: _session(reps: 3)));

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsOneWidget);
  });
}
