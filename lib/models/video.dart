class Video {
  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String? thumbnailUrl;
  final int duration; // seconds
  final AccessLevel accessLevel;
  final String? categoryId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    this.thumbnailUrl,
    required this.duration,
    required this.accessLevel,
    this.categoryId,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromMap(Map<String, dynamic> map, String id) {
    return Video(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      youtubeVideoId: map['youtubeVideoId'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      duration: map['duration'] ?? 0,
      accessLevel: AccessLevel.values.firstWhere(
        (e) => e.name == map['accessLevel'],
        orElse: () => AccessLevel.free,
      ),
      categoryId: map['categoryId'],
      order: map['order'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'youtubeVideoId': youtubeVideoId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'accessLevel': accessLevel.name,
      'categoryId': categoryId,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get youtubeThumbnail =>
      thumbnailUrl ?? 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';

  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isFree => accessLevel == AccessLevel.free;
  bool get isPremium => accessLevel == AccessLevel.premium;
}

enum AccessLevel {
  free,
  premium,
}
