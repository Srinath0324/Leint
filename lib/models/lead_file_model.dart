import 'package:cloud_firestore/cloud_firestore.dart';

/// Lead file model representing an uploaded CSV file
class LeadFileModel {
  final String id;
  final String userId;
  final String title;
  final String source;
  final int totalLeads;
  final int unreached;
  final int followUps;
  final int noResponse;
  final int accepted;
  final int rejected;
  final DateTime uploadDate;

  LeadFileModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.source,
    this.totalLeads = 0,
    this.unreached = 0,
    this.followUps = 0,
    this.noResponse = 0,
    this.accepted = 0,
    this.rejected = 0,
    required this.uploadDate,
  });

  factory LeadFileModel.fromMap(Map<String, dynamic> map, String id) {
    return LeadFileModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      source: map['source'] ?? '',
      totalLeads: map['totalLeads'] ?? 0,
      unreached: map['unreached'] ?? 0,
      followUps: map['followUps'] ?? 0,
      noResponse: map['noResponse'] ?? 0,
      accepted: map['accepted'] ?? 0,
      rejected: map['rejected'] ?? 0,
      uploadDate: (map['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'source': source,
      'totalLeads': totalLeads,
      'unreached': unreached,
      'followUps': followUps,
      'noResponse': noResponse,
      'accepted': accepted,
      'rejected': rejected,
      'uploadDate': Timestamp.fromDate(uploadDate),
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
  }) {
    return LeadFileModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      source: source ?? this.source,
      totalLeads: totalLeads ?? this.totalLeads,
      unreached: unreached ?? this.unreached,
      followUps: followUps ?? this.followUps,
      noResponse: noResponse ?? this.noResponse,
      accepted: accepted ?? this.accepted,
      rejected: rejected ?? this.rejected,
      uploadDate: uploadDate,
    );
  }
}
