import 'firestore_date.dart';

class LiveSchedule {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final int duration; // minutes
  final String? thumbnailUrl;
  final String? streamUrl;

  /// 配信が終わったあとのアーカイブ動画。見逃し配信で使う。
  final String? archiveVideoId;
  final LiveStatus status;
  final DateTime createdAt;

  LiveSchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.duration,
    this.thumbnailUrl,
    this.streamUrl,
    this.archiveVideoId,
    required this.status,
    required this.createdAt,
  });

  factory LiveSchedule.fromMap(Map<String, dynamic> map, String id) {
    return LiveSchedule(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledAt: parseDate(map['scheduledAt']),
      duration: map['duration'] ?? 60,
      thumbnailUrl: map['thumbnailUrl'],
      streamUrl: map['streamUrl'],
      archiveVideoId: map['archiveVideoId'],
      status: LiveStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LiveStatus.scheduled,
      ),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'archiveVideoId': archiveVideoId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isLive => status == LiveStatus.live;
  bool get isScheduled => status == LiveStatus.scheduled;
  bool get isEnded => status == LiveStatus.ended;

  /// 見逃し配信として見られるか。
  bool get hasArchive =>
      isEnded && archiveVideoId != null && archiveVideoId!.isNotEmpty;

  bool get isUpcoming {
    return status == LiveStatus.scheduled && scheduledAt.isAfter(DateTime.now());
  }

  String get statusLabel {
    switch (status) {
      case LiveStatus.scheduled:
        return '配信予定';
      case LiveStatus.live:
        return '配信中';
      case LiveStatus.ended:
        return '配信終了';
    }
  }

  /// 「12:00」
  String get formattedTime =>
      '${scheduledAt.hour.toString().padLeft(2, '0')}:'
      '${scheduledAt.minute.toString().padLeft(2, '0')}';

  /// 「10/1(水) 12:00」
  String get formattedDateTime {
    const week = ['月', '火', '水', '木', '金', '土', '日'];
    return '${scheduledAt.month}/${scheduledAt.day}'
        '(${week[scheduledAt.weekday - 1]}) $formattedTime';
  }

  String get durationFormatted {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return '$hours時間${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分';
  }
}

enum LiveStatus {
  scheduled,
  live,
  ended,
}
