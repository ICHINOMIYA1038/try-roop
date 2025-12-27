import 'package:cloud_firestore/cloud_firestore.dart';
import 'video.dart' show AccessLevel;

class TextLesson {
  final String id;
  final String title;
  final String description;
  final String? content; // マークダウン文字列（Firestore用）
  final String? assetPath; // ローカルアセットパス（後方互換用）
  final String? thumbnailUrl;
  final String categoryId;
  final int order;
  final int estimatedReadingMinutes;
  final AccessLevel accessLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TextLesson({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.assetPath,
    this.thumbnailUrl,
    required this.categoryId,
    required this.order,
    required this.estimatedReadingMinutes,
    required this.accessLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TextLesson.fromMap(Map<String, dynamic> map, String id) {
    return TextLesson(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      content: map['content'],
      assetPath: map['assetPath'],
      thumbnailUrl: map['thumbnailUrl'],
      categoryId: map['categoryId'] ?? '',
      order: map['order'] ?? 0,
      estimatedReadingMinutes: map['estimatedReadingMinutes'] ?? 5,
      accessLevel: AccessLevel.values.firstWhere(
        (e) => e.name == map['accessLevel'],
        orElse: () => AccessLevel.free,
      ),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'assetPath': assetPath,
      'thumbnailUrl': thumbnailUrl,
      'categoryId': categoryId,
      'order': order,
      'estimatedReadingMinutes': estimatedReadingMinutes,
      'accessLevel': accessLevel.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Firestoreにコンテンツがあるかどうか
  bool get hasFirestoreContent => content != null && content!.isNotEmpty;

  /// ローカルアセットを使うかどうか
  bool get usesLocalAsset => assetPath != null && assetPath!.isNotEmpty;

  bool get isFree => accessLevel == AccessLevel.free;
  bool get isPremium => accessLevel == AccessLevel.premium;

  TextLesson copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? assetPath,
    String? thumbnailUrl,
    String? categoryId,
    int? order,
    int? estimatedReadingMinutes,
    AccessLevel? accessLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TextLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      assetPath: assetPath ?? this.assetPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      categoryId: categoryId ?? this.categoryId,
      order: order ?? this.order,
      estimatedReadingMinutes: estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      accessLevel: accessLevel ?? this.accessLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
