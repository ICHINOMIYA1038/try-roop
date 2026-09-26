import 'pose_metrics.dart';

/// 測定した種目。
enum ExerciseKind {
  /// スクワット。膝の角度で深さを測る。
  squat,

  /// 蹴り。足の高さを測る。
  kick,
}

extension ExerciseKindLabel on ExerciseKind {
  String get label => switch (this) {
        ExerciseKind.squat => 'スクワット',
        ExerciseKind.kick => '蹴り',
      };

  /// 記録の単位。画面に出すときに使う。
  String get unit => switch (this) {
        ExerciseKind.squat => '度',
        ExerciseKind.kick => '',
      };
}

/// 1 回の測定の記録。
///
/// 「測って終わり」だと次に開く理由が無いので、必ず残して前回と比べられる
/// ようにする。
class FormSession {
  final String id;
  final String userId;
  final ExerciseKind kind;
  final int reps;

  /// 種目ごとの代表値。スクワットなら最も深かった膝の角度（小さいほど深い）、
  /// 蹴りなら最も高かった比率（大きいほど高い）。
  final double? bestValue;

  /// 左右それぞれの代表値。片側しか測っていなければ null。
  final double? leftValue;
  final double? rightValue;

  final DateTime recordedAt;

  const FormSession({
    required this.id,
    required this.userId,
    required this.kind,
    required this.reps,
    this.bestValue,
    this.leftValue,
    this.rightValue,
    required this.recordedAt,
  });

  Symmetry? get symmetry {
    final l = leftValue;
    final r = rightValue;
    if (l == null || r == null) return null;
    return Symmetry(left: l, right: r);
  }

  factory FormSession.fromMap(Map<String, dynamic> map, String id) {
    return FormSession(
      id: id,
      userId: map['userId'] ?? '',
      kind: ExerciseKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => ExerciseKind.squat,
      ),
      reps: map['reps'] ?? 0,
      bestValue: (map['bestValue'] as num?)?.toDouble(),
      leftValue: (map['leftValue'] as num?)?.toDouble(),
      rightValue: (map['rightValue'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(map['recordedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'kind': kind.name,
      'reps': reps,
      'bestValue': bestValue,
      'leftValue': leftValue,
      'rightValue': rightValue,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  /// 前回と比べてどう変わったか。履歴の画面で出す。
  ///
  /// スクワットは角度が小さいほど深いので、向きが逆になる点に注意。
  double? improvementOver(FormSession? previous) {
    final mine = bestValue;
    final theirs = previous?.bestValue;
    if (mine == null || theirs == null) return null;

    return switch (kind) {
      ExerciseKind.squat => theirs - mine,
      ExerciseKind.kick => mine - theirs,
    };
  }
}
