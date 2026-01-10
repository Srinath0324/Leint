import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for storing authenticated user data
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? currentWorkspaceId;    // Currently active workspace
  final List<String> workspaceIds;     // All workspaces user belongs to
  final DateTime lastActiveAt;         // Last time user was active

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.currentWorkspaceId,
    List<String>? workspaceIds,
    DateTime? lastActiveAt,
  }) : workspaceIds = workspaceIds ?? [],
       lastActiveAt = lastActiveAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      currentWorkspaceId: map['currentWorkspaceId'],
      workspaceIds: List<String>.from(map['workspaceIds'] ?? []),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'currentWorkspaceId': currentWorkspaceId,
      'workspaceIds': workspaceIds,
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? currentWorkspaceId,
    List<String>? workspaceIds,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      currentWorkspaceId: currentWorkspaceId ?? this.currentWorkspaceId,
      workspaceIds: workspaceIds ?? this.workspaceIds,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
