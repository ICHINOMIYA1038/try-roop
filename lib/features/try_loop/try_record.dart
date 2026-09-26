import '../../models/firestore_date.dart';

/// 何に挑戦したか。
enum TryKind {
  /// LIVE に参加した
  live,

  /// 動画を見終えた
  video,

  /// テキストレッスンを読み終えた
  lesson,
}

extension TryKindLabel on TryKind {
  String get label => switch (this) {
        TryKind.live => 'LIVE',
        TryKind.video => '動画',
        TryKind.lesson => 'レッスン',
      };
}

/// 1回ぶんの TRY。
///
/// Try Loop の軸は「挑戦する → 続ける → 次に挑戦する」なので、
/// 視聴の記録とは別に「挑戦した回数」として数える。
///
/// ドキュメント ID は `{userId}_{kind}_{targetId}_{yyyyMMdd}`。
/// 同じものを同じ日に何度開いても1回だが、日をまたげばまた1回になる。
class TryRecord {
  final String id;
  final String userId;
  final TryKind kind;
  final String targetId;

  /// ジャンル。新しいジャンルへの挑戦を数えるために持つ。
  final String? categoryId;

  final DateTime completedAt;

  const TryRecord({
    required this.id,
    required this.userId,
    required this.kind,
    required this.targetId,
    this.categoryId,
    required this.completedAt,
  });

  static String buildId({
    required String userId,
    required TryKind kind,
    required String targetId,
    required DateTime on,
  }) {
    final day = '${on.year}'
        '${on.month.toString().padLeft(2, '0')}'
        '${on.day.toString().padLeft(2, '0')}';
    return '${userId}_${kind.name}_${targetId}_$day';
  }

  factory TryRecord.fromMap(Map<String, dynamic> map, String id) {
    return TryRecord(
      id: id,
      userId: map['userId'] ?? '',
      kind: TryKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => TryKind.video,
      ),
      targetId: map['targetId'] ?? '',
      categoryId: map['categoryId'],
      completedAt: parseDate(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'kind': kind.name,
      'targetId': targetId,
      'categoryId': categoryId,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

/// TRY の集計。プロフィールに出す。
class TrySummary {
  final List<TryRecord> records;

  const TrySummary(this.records);

  /// 今月の回数。
  int get thisMonth {
    final now = DateTime.now();
    return records
        .where((r) =>
            r.completedAt.year == now.year && r.completedAt.month == now.month)
        .length;
  }

  int get total => records.length;

  /// 挑戦したことのあるジャンル。
  Set<String> get categories =>
      records.map((r) => r.categoryId).whereType<String>().toSet();

  /// 今日すでに TRY したか。
  bool get doneToday {
    final now = DateTime.now();
    return records.any((r) =>
        r.completedAt.year == now.year &&
        r.completedAt.month == now.month &&
        r.completedAt.day == now.day);
  }

  /// 連続して TRY した日数。今日か昨日から遡って数える。
  int get streakDays {
    if (records.isEmpty) return 0;

    final days = records
        .map((r) => DateTime(
            r.completedAt.year, r.completedAt.month, r.completedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 今日まだでも、昨日やっていれば連続は途切れていない。
    if (days.first != today && days.first != yesterday) return 0;

    var streak = 1;
    for (var i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
