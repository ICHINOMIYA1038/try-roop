import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class Announcement {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isPublished;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.isPublished,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String id) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      isPublished: map['isPublished'] ?? false,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}
