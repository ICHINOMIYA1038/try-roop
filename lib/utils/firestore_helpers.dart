import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore の Timestamp または ISO8601 文字列から DateTime に変換する。
/// デモモードでは String、本番モードでは Timestamp が来る。
DateTime parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  } else if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}
