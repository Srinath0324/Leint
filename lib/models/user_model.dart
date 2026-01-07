/// User model for storing authenticated user data
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final UserStats totalStats;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    UserStats? totalStats,
  }) : totalStats = totalStats ?? UserStats();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      totalStats: map['totalStats'] != null
          ? UserStats.fromMap(map['totalStats'] as Map<String, dynamic>)
          : UserStats(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'totalStats': totalStats.toMap(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    UserStats? totalStats,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      totalStats: totalStats ?? this.totalStats,
    );
  }
}

/// User statistics for lead tracking
class UserStats {
  final int totalLeads;
  final int unreached;
  final int followUps;
  final int noResponse;
  final int accepted;
  final int rejected;

  UserStats({
    this.totalLeads = 0,
    this.unreached = 0,
    this.followUps = 0,
    this.noResponse = 0,
    this.accepted = 0,
    this.rejected = 0,
  });

  double get conversionRate {
    if (totalLeads == 0) return 0.0;
    return (accepted / totalLeads) * 100;
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalLeads: map['totalLeads'] ?? 0,
      unreached: map['unreached'] ?? 0,
      followUps: map['followUps'] ?? 0,
      noResponse: map['noResponse'] ?? 0,
      accepted: map['accepted'] ?? 0,
      rejected: map['rejected'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalLeads': totalLeads,
      'unreached': unreached,
      'followUps': followUps,
      'noResponse': noResponse,
      'accepted': accepted,
      'rejected': rejected,
    };
  }
}
