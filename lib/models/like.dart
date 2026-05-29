import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class Like {
  final String id;
  final String userId;
  final LikeTargetType targetType;
  final String targetId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory Like.fromMap(Map<String, dynamic> map, String id) {
    return Like(
      id: id,
      userId: map['userId'] ?? '',
      targetType: LikeTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => LikeTargetType.post,
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
  static String generateId(String userId, LikeTargetType targetType, String targetId) {
    return '${userId}_${targetType.name}_$targetId';
  }
}

enum LikeTargetType {
  post,
  comment,
}
