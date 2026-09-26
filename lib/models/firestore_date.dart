import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore の日時フィールドを読む。
///
/// 同じフィールドに Timestamp と ISO 文字列が混ざっている。
/// tool/seed.js は Timestamp を書き、アプリ側は toIso8601String() で
/// 文字列を書き、管理画面 (site) は文字列に正規化している。
/// どれで書かれていても読めるようにする。
DateTime? parseDateOrNull(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

/// 必須の日時。読めなければ [fallback]、それも無ければ 1970-01-01。
///
/// 例外にしないのは、1件でも壊れたドキュメントがあると一覧全体が
/// 表示できなくなるため。実際にそれで全コンテンツが出ていなかった。
DateTime parseDate(Object? value, {DateTime? fallback}) {
  return parseDateOrNull(value) ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
