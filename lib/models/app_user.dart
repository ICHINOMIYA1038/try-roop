class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final MembershipType membershipType;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.membershipType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      membershipType: MembershipType.values.firstWhere(
        (e) => e.name == map['membershipType'],
        orElse: () => MembershipType.free,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'membershipType': membershipType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    MembershipType? membershipType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      membershipType: membershipType ?? this.membershipType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPremium => membershipType == MembershipType.premium;
}

enum MembershipType {
  free,
  premium,
}
