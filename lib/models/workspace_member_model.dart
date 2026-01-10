import 'package:cloud_firestore/cloud_firestore.dart';

/// Workspace member with role and user information
class WorkspaceMember {
  final String id; // Composite: userId_workspaceId
  final String userId;
  final String workspaceId;
  final WorkspaceRole role;
  final DateTime joinedAt;
  final String invitedBy;
  
  // Cached user info for display
  final String? displayName;
  final String? email;
  final String? photoURL;

  WorkspaceMember({
    required this.id,
    required this.userId,
    required this.workspaceId,
    required this.role,
    required this.joinedAt,
    required this.invitedBy,
    this.displayName,
    this.email,
    this.photoURL,
  });

  factory WorkspaceMember.fromMap(Map<String, dynamic> map, String id) {
    return WorkspaceMember(
      id: id,
      userId: map['userId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      role: WorkspaceRole.fromFirestore(map['role'] ?? 'member'),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: map['invitedBy'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      photoURL: map['photoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workspaceId': workspaceId,
      'role': role.toFirestore(),
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedBy': invitedBy,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoURL != null) 'photoURL': photoURL,
    };
  }

  WorkspaceMember copyWith({
    WorkspaceRole? role,
    String? displayName,
    String? email,
    String? photoURL,
  }) {
    return WorkspaceMember(
      id: id,
      userId: userId,
      workspaceId: workspaceId,
      role: role ?? this.role,
      joinedAt: joinedAt,
      invitedBy: invitedBy,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
    );
  }

  /// Generate composite ID
  static String generateId(String userId, String workspaceId) {
    return '${userId}_$workspaceId';
  }

  /// Get display name or fallback to email/userId
  String get displayNameOrEmail => displayName ?? email ?? userId;
}

/// Workspace roles with permissions
enum WorkspaceRole {
  owner,
  admin,
  member,
  viewer;

  String get displayName {
    switch (this) {
      case WorkspaceRole.owner:
        return 'Owner';
      case WorkspaceRole.admin:
        return 'Admin';
      case WorkspaceRole.member:
        return 'Member';
      case WorkspaceRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case WorkspaceRole.owner:
        return 'Full control of workspace';
      case WorkspaceRole.admin:
        return 'Can manage members and edit data';
      case WorkspaceRole.member:
        return 'Can edit data';
      case WorkspaceRole.viewer:
        return 'Read-only access';
    }
  }

  bool get canEdit {
    return this == WorkspaceRole.owner ||
        this == WorkspaceRole.admin ||
        this == WorkspaceRole.member;
  }

  bool get canManageMembers {
    return this == WorkspaceRole.owner || this == WorkspaceRole.admin;
  }

  bool get canDeleteWorkspace {
    return this == WorkspaceRole.owner;
  }

  String toFirestore() {
    return name;
  }

  static WorkspaceRole fromFirestore(String value) {
    return WorkspaceRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => WorkspaceRole.member,
    );
  }
}
