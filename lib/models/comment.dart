import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class Comment {
  final String id;
  final CommentTargetType targetType;
  final String targetId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final int likeCount;
  final String? parentId; // For replies
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.likeCount,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      targetType: CommentTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => CommentTargetType.post,
      ),
      targetId: map['targetId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'],
      content: map['content'] ?? '',
      likeCount: map['likeCount'] ?? 0,
      parentId: map['parentId'],
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetType': targetType.name,
      'targetId': targetId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'likeCount': likeCount,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    CommentTargetType? targetType,
    String? targetId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    int? likeCount,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isReply => parentId != null;
}

enum CommentTargetType {
  video,
  post,
}
