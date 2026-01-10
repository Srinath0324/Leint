import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Workspace invitation model for inviting users to join a workspace
class WorkspaceInvitation {
  final String id;
  final String workspaceId;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final bool isActive;

  WorkspaceInvitation({
    required this.id,
    required this.workspaceId,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = -1, // -1 means unlimited
    this.usedCount = 0,
    this.isActive = true,
  });

  factory WorkspaceInvitation.fromMap(Map<String, dynamic> map, String id) {
    return WorkspaceInvitation(
      id: id,
      workspaceId: map['workspaceId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      maxUses: map['maxUses'] ?? -1,
      usedCount: map['usedCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'usedCount': usedCount,
      'isActive': isActive,
    };
  }

  WorkspaceInvitation copyWith({
    String? workspaceId,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    bool? isActive,
  }) {
    return WorkspaceInvitation(
      id: id,
      workspaceId: workspaceId ?? this.workspaceId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if invitation is still valid
  bool get isValid {
    if (!isActive) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    if (maxUses != -1 && usedCount >= maxUses) return false;
    return true;
  }

  /// Check if invitation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation has reached max uses
  bool get hasReachedMaxUses => maxUses != -1 && usedCount >= maxUses;

  /// Generate a random 6-character invite code
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Create a new invitation with default values
  static WorkspaceInvitation create({
    required String workspaceId,
    required String createdBy,
    int daysValid = 7,
    int maxUses = -1,
  }) {
    final now = DateTime.now();
    return WorkspaceInvitation(
      id: '', // Will be set by Firestore
      workspaceId: workspaceId,
      inviteCode: generateInviteCode(),
      createdBy: createdBy,
      createdAt: now,
      expiresAt: now.add(Duration(days: daysValid)),
      maxUses: maxUses,
      usedCount: 0,
      isActive: true,
    );
  }
}
