class Course {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? instructorId;
  final String? categoryId;
  final List<String> videoIds;
  final int totalDuration; // minutes
  final CourseDifficulty difficulty;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.instructorId,
    this.categoryId,
    required this.videoIds,
    required this.totalDuration,
    required this.difficulty,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      instructorId: map['instructorId'],
      categoryId: map['categoryId'],
      videoIds: List<String>.from(map['videoIds'] ?? []),
      totalDuration: map['totalDuration'] ?? 0,
      difficulty: CourseDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => CourseDifficulty.beginner,
      ),
      isPublished: map['isPublished'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'instructorId': instructorId,
      'categoryId': categoryId,
      'videoIds': videoIds,
      'totalDuration': totalDuration,
      'difficulty': difficulty.name,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? instructorId,
    String? categoryId,
    List<String>? videoIds,
    int? totalDuration,
    CourseDifficulty? difficulty,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructorId: instructorId ?? this.instructorId,
      categoryId: categoryId ?? this.categoryId,
      videoIds: videoIds ?? this.videoIds,
      totalDuration: totalDuration ?? this.totalDuration,
      difficulty: difficulty ?? this.difficulty,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get videoCount => videoIds.length;

  String get totalDurationFormatted {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0) {
      return '$hours時間${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分';
  }

  String get difficultyLabel {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return '初級';
      case CourseDifficulty.intermediate:
        return '中級';
      case CourseDifficulty.advanced:
        return '上級';
    }
  }
}

enum CourseDifficulty {
  beginner,
  intermediate,
  advanced,
}
