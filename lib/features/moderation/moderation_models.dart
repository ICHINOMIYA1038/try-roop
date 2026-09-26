import '../../models/firestore_date.dart';

/// 通報の対象。
enum ReportTargetType { post, comment, user }

/// 通報の理由。App Store ガイドライン 1.2 が求める「不適切な内容を
/// 報告する手段」にあたる。選択式にして、書かずに送れるようにする。
enum ReportReason {
  spam,
  harassment,
  sexual,
  violence,
  misinformation,
  other,
}

extension ReportReasonLabel on ReportReason {
  String get label => switch (this) {
        ReportReason.spam => '迷惑・宣伝',
        ReportReason.harassment => '誹謗中傷・嫌がらせ',
        ReportReason.sexual => '性的な内容',
        ReportReason.violence => '暴力的な内容',
        ReportReason.misinformation => '誤った情報',
        ReportReason.other => 'その他',
      };
}

/// 対応状況。
enum ReportStatus { open, resolved, dismissed }

class Report {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;

  /// 通報された投稿の書き手。繰り返し通報される人を見つけるために持つ。
  final String? targetAuthorId;

  final ReportReason reason;
  final String? note;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    this.targetAuthorId,
    required this.reason,
    this.note,
    this.status = ReportStatus.open,
    required this.createdAt,
  });

  /// 同じ人が同じ対象を何度も通報しても1件にする。
  static String buildId({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
  }) =>
      '${reporterId}_${targetType.name}_$targetId';

  factory Report.fromMap(Map<String, dynamic> map, String id) {
    return Report(
      id: id,
      reporterId: map['reporterId'] ?? '',
      targetType: ReportTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => ReportTargetType.post,
      ),
      targetId: map['targetId'] ?? '',
      targetAuthorId: map['targetAuthorId'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      note: map['note'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.open,
      ),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'targetType': targetType.name,
        'targetId': targetId,
        'targetAuthorId': targetAuthorId,
        'reason': reason.name,
        'note': note,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// 利用者どうしのブロック。
///
/// ガイドライン 1.2 は「迷惑な利用者をブロックする手段」を求めている。
/// ドキュメント ID は `{userId}_{blockedUserId}`。
class BlockedUser {
  final String userId;
  final String blockedUserId;
  final DateTime createdAt;

  const BlockedUser({
    required this.userId,
    required this.blockedUserId,
    required this.createdAt,
  });

  static String buildId(String userId, String blockedUserId) =>
      '${userId}_$blockedUserId';

  factory BlockedUser.fromMap(Map<String, dynamic> map) => BlockedUser(
        userId: map['userId'] ?? '',
        blockedUserId: map['blockedUserId'] ?? '',
        createdAt: parseDate(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'blockedUserId': blockedUserId,
        'createdAt': createdAt.toIso8601String(),
      };
}
