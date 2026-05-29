import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class Bookmark {
  final String id;
  final String userId;
  final BookmarkTargetType targetType;
  final String targetId;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map, String id) {
    return Bookmark(
      id: id,
      userId: map['userId'] ?? '',
      targetType: BookmarkTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => BookmarkTargetType.video,
      ),
      targetId: map['targetId'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'targetType': targetType.name,
      'targetId': targetId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Generate document ID for uniqueness
  static String generateId(String userId, BookmarkTargetType targetType, String targetId) {
    return '${userId}_${targetType.name}_$targetId';
  }
}

enum BookmarkTargetType {
  video,
  course,
  post,
}
