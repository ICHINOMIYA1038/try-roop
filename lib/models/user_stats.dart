import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
class UserStats {
  final String id;
  final String? bio;
  final int totalWatchTime; // minutes
  final int completedCourses;
  final int completedVideos;
  final List<String> badgeIds;
  final int consecutiveDays;
  final DateTime? lastActiveAt;
  final DateTime updatedAt;

  UserStats({
    required this.id,
    this.bio,
    required this.totalWatchTime,
    required this.completedCourses,
    required this.completedVideos,
    required this.badgeIds,
    required this.consecutiveDays,
    this.lastActiveAt,
    required this.updatedAt,
  });

  factory UserStats.fromMap(Map<String, dynamic> map, String id) {
    return UserStats(
      id: id,
      bio: map['bio'],
      totalWatchTime: map['totalWatchTime'] ?? 0,
      completedCourses: map['completedCourses'] ?? 0,
      completedVideos: map['completedVideos'] ?? 0,
      badgeIds: List<String>.from(map['badgeIds'] ?? []),
      consecutiveDays: map['consecutiveDays'] ?? 0,
      lastActiveAt: map['lastActiveAt'] != null
          ? parseDateTime(map['lastActiveAt'])
          : null,
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bio': bio,
      'totalWatchTime': totalWatchTime,
      'completedCourses': completedCourses,
      'completedVideos': completedVideos,
      'badgeIds': badgeIds,
      'consecutiveDays': consecutiveDays,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserStats copyWith({
    String? id,
    String? bio,
    int? totalWatchTime,
    int? completedCourses,
    int? completedVideos,
    List<String>? badgeIds,
    int? consecutiveDays,
    DateTime? lastActiveAt,
    DateTime? updatedAt,
  }) {
    return UserStats(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      completedCourses: completedCourses ?? this.completedCourses,
      completedVideos: completedVideos ?? this.completedVideos,
      badgeIds: badgeIds ?? this.badgeIds,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get totalWatchTimeFormatted {
    final hours = totalWatchTime ~/ 60;
    final minutes = totalWatchTime % 60;
    if (hours > 0) {
      return '$hours時間${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分';
  }

  static UserStats empty(String userId) {
    return UserStats(
      id: userId,
      totalWatchTime: 0,
      completedCourses: 0,
      completedVideos: 0,
      badgeIds: [],
      consecutiveDays: 0,
      updatedAt: DateTime.now(),
    );
  }
}
