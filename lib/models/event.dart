enum EventType {
  online,
  offline,
}

enum EventStatus {
  draft,
  scheduled,
  ongoing,
  completed,
  cancelled,
}

class Event {
  final String id;
  final String title;
  final String description;
  final EventType eventType;
  final DateTime startAt;
  final DateTime endAt;
  final int capacity;
  final int currentParticipants;
  final String? location;
  final String? meetingUrl;
  final String? imageUrl;
  final EventStatus status;
  final bool requiresRegistration;
  final DateTime? registrationDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.currentParticipants,
    this.location,
    this.meetingUrl,
    this.imageUrl,
    required this.status,
    required this.requiresRegistration,
    this.registrationDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventType: EventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => EventType.offline,
      ),
      startAt: DateTime.parse(map['startAt']),
      endAt: DateTime.parse(map['endAt']),
      capacity: map['capacity'] ?? 0,
      currentParticipants: map['currentParticipants'] ?? 0,
      location: map['location'],
      meetingUrl: map['meetingUrl'],
      imageUrl: map['imageUrl'],
      status: EventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EventStatus.scheduled,
      ),
      requiresRegistration: map['requiresRegistration'] ?? true,
      registrationDeadline: map['registrationDeadline'] != null
          ? DateTime.parse(map['registrationDeadline'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventType': eventType.name,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'capacity': capacity,
      'currentParticipants': currentParticipants,
      'location': location,
      'meetingUrl': meetingUrl,
      'imageUrl': imageUrl,
      'status': status.name,
      'requiresRegistration': requiresRegistration,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventType? eventType,
    DateTime? startAt,
    DateTime? endAt,
    int? capacity,
    int? currentParticipants,
    String? location,
    String? meetingUrl,
    String? imageUrl,
    EventStatus? status,
    bool? requiresRegistration,
    DateTime? registrationDeadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      capacity: capacity ?? this.capacity,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      location: location ?? this.location,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get isOnline => eventType == EventType.online;
  bool get isOffline => eventType == EventType.offline;
  bool get isFull => currentParticipants >= capacity;
  bool get isUpcoming =>
      startAt.isAfter(DateTime.now()) && status == EventStatus.scheduled;
  bool get isOngoing =>
      DateTime.now().isAfter(startAt) && DateTime.now().isBefore(endAt);
  bool get isPast => endAt.isBefore(DateTime.now());

  bool get canRegister {
    if (!isUpcoming) return false;
    if (isFull) return false;
    if (registrationDeadline != null &&
        DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return true;
  }

  bool get canJoinWaitlist {
    if (!isUpcoming) return false;
    if (!isFull) return false;
    if (registrationDeadline != null &&
        DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return true;
  }

  int get availableSpots => capacity - currentParticipants;

  String get eventTypeLabel => eventType == EventType.online ? 'オンライン' : 'オフライン';

  String get statusLabel {
    switch (status) {
      case EventStatus.draft:
        return '下書き';
      case EventStatus.scheduled:
        return '予定';
      case EventStatus.ongoing:
        return '開催中';
      case EventStatus.completed:
        return '終了';
      case EventStatus.cancelled:
        return 'キャンセル';
    }
  }

  String get durationFormatted {
    final duration = endAt.difference(startAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours時間${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分';
  }

  String get dateFormatted {
    return '${startAt.month}/${startAt.day}(${_weekdayLabel(startAt.weekday)})';
  }

  String get timeFormatted {
    final startHour = startAt.hour.toString().padLeft(2, '0');
    final startMinute = startAt.minute.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMinute = endAt.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute〜$endHour:$endMinute';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[weekday - 1];
  }
}
