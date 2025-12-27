class LiveSchedule {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final int duration; // minutes
  final String? thumbnailUrl;
  final String? streamUrl;
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
    required this.status,
    required this.createdAt,
  });

  factory LiveSchedule.fromMap(Map<String, dynamic> map, String id) {
    return LiveSchedule(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledAt: DateTime.parse(map['scheduledAt']),
      duration: map['duration'] ?? 60,
      thumbnailUrl: map['thumbnailUrl'],
      streamUrl: map['streamUrl'],
      status: LiveStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LiveStatus.scheduled,
      ),
      createdAt: DateTime.parse(map['createdAt']),
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
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isLive => status == LiveStatus.live;
  bool get isScheduled => status == LiveStatus.scheduled;
  bool get isEnded => status == LiveStatus.ended;

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
