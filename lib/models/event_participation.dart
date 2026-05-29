import 'package:tryroop_campus_live_flutter/utils/firestore_helpers.dart';
enum ParticipationStatus {
  confirmed,
  waitlisted,
  cancelled,
}

class EventParticipation {
  final String id;
  final String userId;
  final String eventId;
  final ParticipationStatus status;
  final int waitlistPosition;
  final DateTime registeredAt;
  final DateTime? cancelledAt;

  EventParticipation({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.waitlistPosition,
    required this.registeredAt,
    this.cancelledAt,
  });

  factory EventParticipation.fromMap(Map<String, dynamic> map, String id) {
    return EventParticipation(
      id: id,
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      status: ParticipationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ParticipationStatus.confirmed,
      ),
      waitlistPosition: map['waitlistPosition'] ?? 0,
      registeredAt: parseDateTime(map['registeredAt']),
      cancelledAt: map['cancelledAt'] != null
          ? parseDateTime(map['cancelledAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status.name,
      'waitlistPosition': waitlistPosition,
      'registeredAt': registeredAt.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  EventParticipation copyWith({
    String? id,
    String? userId,
    String? eventId,
    ParticipationStatus? status,
    int? waitlistPosition,
    DateTime? registeredAt,
    DateTime? cancelledAt,
  }) {
    return EventParticipation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      waitlistPosition: waitlistPosition ?? this.waitlistPosition,
      registeredAt: registeredAt ?? this.registeredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  // Computed properties
  bool get isConfirmed => status == ParticipationStatus.confirmed;
  bool get isWaitlisted => status == ParticipationStatus.waitlisted;
  bool get isCancelled => status == ParticipationStatus.cancelled;

  String get statusLabel {
    switch (status) {
      case ParticipationStatus.confirmed:
        return '参加確定';
      case ParticipationStatus.waitlisted:
        return 'キャンセル待ち';
      case ParticipationStatus.cancelled:
        return 'キャンセル済み';
    }
  }

  // Generate unique document ID
  static String generateId(String userId, String eventId) {
    return '${userId}_$eventId';
  }
}
