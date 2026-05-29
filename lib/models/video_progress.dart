import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class VideoProgress {
  final String id;
  final String uid;
  final String videoId;
  final int currentTime; // seconds
  final bool completed;
  final DateTime updatedAt;

  VideoProgress({
    required this.id,
    required this.uid,
    required this.videoId,
    required this.currentTime,
    required this.completed,
    required this.updatedAt,
  });

  factory VideoProgress.fromMap(Map<String, dynamic> map, String id) {
    return VideoProgress(
      id: id,
      uid: map['uid'] ?? '',
      videoId: map['videoId'] ?? '',
      currentTime: map['currentTime'] ?? 0,
      completed: map['completed'] ?? false,
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'videoId': videoId,
      'currentTime': currentTime,
      'completed': completed,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  VideoProgress copyWith({
    String? id,
    String? uid,
    String? videoId,
    int? currentTime,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return VideoProgress(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      videoId: videoId ?? this.videoId,
      currentTime: currentTime ?? this.currentTime,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double progressPercent(int totalDuration) {
    if (totalDuration == 0) return 0;
    return (currentTime / totalDuration).clamp(0.0, 1.0);
  }
}
