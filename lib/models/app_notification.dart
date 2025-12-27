class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data; // Navigation data
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.announcement,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.newVideo:
        return '新着動画';
      case NotificationType.newCourse:
        return '新着コース';
      case NotificationType.commentReply:
        return '返信';
      case NotificationType.like:
        return 'いいね';
      case NotificationType.announcement:
        return 'お知らせ';
      case NotificationType.liveSchedule:
        return 'ライブ配信';
    }
  }
}

enum NotificationType {
  newVideo,
  newCourse,
  commentReply,
  like,
  announcement,
  liveSchedule,
}
