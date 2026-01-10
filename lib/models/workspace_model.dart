import 'package:cloud_firestore/cloud_firestore.dart';

/// Workspace model representing a team or personal workspace
class WorkspaceModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final WorkspaceSettings settings;
  final WorkspaceStats stats; // NEW: Workspace-level stats

  WorkspaceModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.memberIds = const [],
    required this.createdAt,
    WorkspaceSettings? settings,
    WorkspaceStats? stats,
  })  : settings = settings ?? WorkspaceSettings(),
        stats = stats ?? WorkspaceStats();

  factory WorkspaceModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkspaceModel(
      id: id,
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: map['settings'] != null
          ? WorkspaceSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : WorkspaceSettings(),
      stats: map['stats'] != null
          ? WorkspaceStats.fromMap(map['stats'] as Map<String, dynamic>)
          : WorkspaceStats(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings.toMap(),
      'stats': stats.toMap(),
    };
  }

  WorkspaceModel copyWith({
    String? name,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    WorkspaceSettings? settings,
    WorkspaceStats? stats,
  }) {
    return WorkspaceModel(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Check if user is owner
  bool isOwner(String userId) => ownerId == userId;

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId);
}

/// Workspace settings for permissions and preferences
class WorkspaceSettings {
  final bool allowMemberInvites;
  final bool allowMemberEdit;
  final String defaultView;

  WorkspaceSettings({
    this.allowMemberInvites = true,
    this.allowMemberEdit = true,
    this.defaultView = 'list',
  });

  factory WorkspaceSettings.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettings(
      allowMemberInvites: map['allowMemberInvites'] ?? true,
      allowMemberEdit: map['allowMemberEdit'] ?? true,
      defaultView: map['defaultView'] ?? 'list',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowMemberInvites': allowMemberInvites,
      'allowMemberEdit': allowMemberEdit,
      'defaultView': defaultView,
    };
  }

  WorkspaceSettings copyWith({
    bool? allowMemberInvites,
    bool? allowMemberEdit,
    String? defaultView,
  }) {
    return WorkspaceSettings(
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      allowMemberEdit: allowMemberEdit ?? this.allowMemberEdit,
      defaultView: defaultView ?? this.defaultView,
    );
  }
}

/// Workspace statistics - shared by all members
class WorkspaceStats {
  final int totalLeads;
  final int unreached;
  final int followUps;
  final int noResponse;
  final int accepted;
  final int rejected;
  final int selected;

  WorkspaceStats({
    this.totalLeads = 0,
    this.unreached = 0,
    this.followUps = 0,
    this.noResponse = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.selected = 0,
  });

  factory WorkspaceStats.fromMap(Map<String, dynamic> map) {
    return WorkspaceStats(
      totalLeads: map['totalLeads'] ?? 0,
      unreached: map['unreached'] ?? 0,
      followUps: map['followUps'] ?? 0,
      noResponse: map['noResponse'] ?? 0,
      accepted: map['accepted'] ?? 0,
      rejected: map['rejected'] ?? 0,
      selected: map['selected'] ?? 0,
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
      'selected': selected,
    };
  }

  WorkspaceStats copyWith({
    int? totalLeads,
    int? unreached,
    int? followUps,
    int? noResponse,
    int? accepted,
    int? rejected,
    int? selected,
  }) {
    return WorkspaceStats(
      totalLeads: totalLeads ?? this.totalLeads,
      unreached: unreached ?? this.unreached,
      followUps: followUps ?? this.followUps,
      noResponse: noResponse ?? this.noResponse,
      accepted: accepted ?? this.accepted,
      rejected: rejected ?? this.rejected,
      selected: selected ?? this.selected,
    );
  }
}
