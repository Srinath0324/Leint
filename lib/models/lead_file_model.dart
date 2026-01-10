import 'package:cloud_firestore/cloud_firestore.dart';

/// Lead file model representing an uploaded CSV file
class LeadFileModel {
  final String id;
  final String userId;
  final String workspaceId;        // NEW: Which workspace owns this file
  final String createdBy;          // NEW: User who uploaded this file
  final String title;
  final String source;
  final int totalLeads;
  final int unreached;
  final int followUps;
  final int noResponse;
  final int accepted;
  final int rejected;
  final int selected;
  final DateTime uploadDate;
  final DateTime lastModifiedAt;   // NEW: When was this file last modified
  final String lastModifiedBy;     // NEW: Who last modified this file

  LeadFileModel({
    required this.id,
    required this.userId,
    required this.workspaceId,
    required this.createdBy,
    required this.title,
    required this.source,
    this.totalLeads = 0,
    this.unreached = 0,
    this.followUps = 0,
    this.noResponse = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.selected = 0,
    required this.uploadDate,
    DateTime? lastModifiedAt,
    String? lastModifiedBy,
  }) : lastModifiedAt = lastModifiedAt ?? uploadDate,
       lastModifiedBy = lastModifiedBy ?? createdBy;

  factory LeadFileModel.fromMap(Map<String, dynamic> map, String id) {
    return LeadFileModel(
      id: id,
      userId: map['userId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdBy: map['createdBy'] ?? map['userId'] ?? '',  // Fallback to userId for backward compatibility
      title: map['title'] ?? '',
      source: map['source'] ?? '',
      totalLeads: map['totalLeads'] ?? 0,
      unreached: map['unreached'] ?? 0,
      followUps: map['followUps'] ?? 0,
      noResponse: map['noResponse'] ?? 0,
      accepted: map['accepted'] ?? 0,
      rejected: map['rejected'] ?? 0,
      selected: map['selected'] ?? 0,
      uploadDate: (map['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModifiedAt: (map['lastModifiedAt'] as Timestamp?)?.toDate(),
      lastModifiedBy: map['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workspaceId': workspaceId,
      'createdBy': createdBy,
      'title': title,
      'source': source,
      'totalLeads': totalLeads,
      'unreached': unreached,
      'followUps': followUps,
      'noResponse': noResponse,
      'accepted': accepted,
      'rejected': rejected,
      'selected': selected,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'lastModifiedAt': Timestamp.fromDate(lastModifiedAt),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  LeadFileModel copyWith({
    String? title,
    String? source,
    int? totalLeads,
    int? unreached,
    int? followUps,
    int? noResponse,
    int? accepted,
    int? rejected,
    int? selected,
    DateTime? lastModifiedAt,
    String? lastModifiedBy,
  }) {
    return LeadFileModel(
      id: id,
      userId: userId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      title: title ?? this.title,
      source: source ?? this.source,
      totalLeads: totalLeads ?? this.totalLeads,
      unreached: unreached ?? this.unreached,
      followUps: followUps ?? this.followUps,
      noResponse: noResponse ?? this.noResponse,
      accepted: accepted ?? this.accepted,
      rejected: rejected ?? this.rejected,
      selected: selected ?? this.selected,
      uploadDate: uploadDate,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
