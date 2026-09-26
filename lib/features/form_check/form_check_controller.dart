import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'form_session.dart';
import 'pose_metrics.dart';

/// 測定中の状態。
///
/// カメラから切り離してあるので、骨格の列を流し込むだけで検証できる。
class FormCheckController extends ChangeNotifier {
  final ExerciseKind kind;

  late RepCounter _counter = _counterFor(kind);

  /// いまの値。画面に出す。
  double? _current;

  /// 左右それぞれの、いちばん良かった値。
  double? _bestLeft;
  double? _bestRight;

  /// 骨格が取れているか。取れていなければ「全身が映るように離れてください」
  /// と促す。
  bool _tracking = false;

  FormCheckController({required this.kind});

  int get reps => _counter.count;
  double? get currentValue => _current;
  bool get isTracking => _tracking;
  bool get isDown => _counter.isDown;

  /// これまででいちばん良かった値。種目によって「良い」の向きが違う。
  double? get bestValue {
    final values = [_bestLeft, _bestRight].whereType<double>();
    if (values.isEmpty) return null;
    return switch (kind) {
      ExerciseKind.squat => values.reduce(math.min),
      ExerciseKind.kick => values.reduce(math.max),
    };
  }

  double? get bestLeft => _bestLeft;
  double? get bestRight => _bestRight;

  Symmetry? get symmetry {
    final l = _bestLeft;
    final r = _bestRight;
    if (l == null || r == null) return null;
    return Symmetry(left: l, right: r);
  }

  /// 1 フレームぶんの骨格を入れる。
  void onFrame(PoseFrame frame) {
    final left = _measure(frame, Side.left);
    final right = _measure(frame, Side.right);

    _tracking = left != null || right != null;
    if (!_tracking) {
      notifyListeners();
      return;
    }

    _current = _representative(left, right);
    _counter.add(_toCounterValue(_current));

    // いちばん良かった値は、動作の最中だけ拾う。構えている間や測り終えた
    // あとの姿勢まで含めると、しゃがんで待っているだけで記録が伸びてしまう。
    if (_counter.isDown) {
      _updateBest(left, right);
    }

    notifyListeners();
  }

  void reset() {
    _counter = _counterFor(kind);
    _current = null;
    _bestLeft = null;
    _bestRight = null;
    _tracking = false;
    notifyListeners();
  }

  FormSession buildSession(String userId) {
    return FormSession(
      id: '',
      userId: userId,
      kind: kind,
      reps: reps,
      bestValue: bestValue,
      leftValue: _bestLeft,
      rightValue: _bestRight,
      recordedAt: DateTime.now(),
    );
  }

  double? _measure(PoseFrame frame, Side side) => switch (kind) {
        ExerciseKind.squat => frame.kneeAngle(side),
        ExerciseKind.kick => frame.kickHeightRatio(side),
      };

  void _updateBest(double? left, double? right) {
    if (left != null) _bestLeft = _better(_bestLeft, left);
    if (right != null) _bestRight = _better(_bestRight, right);
  }

  /// スクワットは角度が小さいほど深く、蹴りは比率が大きいほど高い。
  double _better(double? current, double candidate) {
    if (current == null) return candidate;
    return switch (kind) {
      ExerciseKind.squat => math.min(current, candidate),
      ExerciseKind.kick => math.max(current, candidate),
    };
  }

  /// 左右のうち、そのフレームを代表する値。
  /// スクワットは深い方、蹴りは上がっている方を見る。
  double? _representative(double? left, double? right) {
    if (left == null) return right;
    if (right == null) return left;
    return switch (kind) {
      ExerciseKind.squat => math.min(left, right),
      ExerciseKind.kick => math.max(left, right),
    };
  }

  /// [RepCounter] は「値が下がってから戻る」のを1回と数える。
  /// 蹴りは足が上がったら1回なので、符号を反転させて同じ仕組みに乗せる。
  double? _toCounterValue(double? value) {
    if (value == null) return null;
    return kind == ExerciseKind.kick ? -value : value;
  }

  static RepCounter _counterFor(ExerciseKind kind) => switch (kind) {
        // 膝が 100 度より深く曲がったら下がりきった、160 度より伸びたら戻った。
        ExerciseKind.squat =>
          RepCounter(downThreshold: 100, upThreshold: 160),
        // 腰から体幹の 3 割ぶん以上まで上がったら1回。足を下ろしたら次を待つ。
        ExerciseKind.kick =>
          RepCounter(downThreshold: -0.3, upThreshold: -0.05),
      };
}
