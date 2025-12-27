class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final List<String> completedVideoIds;
  final double progressPercent;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime updatedAt;

  CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.completedVideoIds,
    required this.progressPercent,
    required this.isCompleted,
    this.completedAt,
    required this.updatedAt,
  });

  factory CourseProgress.fromMap(Map<String, dynamic> map, String id) {
    return CourseProgress(
      id: id,
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      completedVideoIds: List<String>.from(map['completedVideoIds'] ?? []),
      progressPercent: (map['progressPercent'] ?? 0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'completedVideoIds': completedVideoIds,
      'progressPercent': progressPercent,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CourseProgress copyWith({
    String? id,
    String? userId,
    String? courseId,
    List<String>? completedVideoIds,
    double? progressPercent,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return CourseProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      completedVideoIds: completedVideoIds ?? this.completedVideoIds,
      progressPercent: progressPercent ?? this.progressPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedCount => completedVideoIds.length;
}
