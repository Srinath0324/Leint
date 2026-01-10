import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workspace_model.dart';
import '../models/workspace_member_model.dart';
import '../models/workspace_invitation_model.dart';

/// Service for managing workspace operations
class WorkspaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _workspacesCollection => _firestore.collection('workspaces');
  CollectionReference get _membersCollection => _firestore.collection('workspace_members');
  CollectionReference get _invitationsCollection => _firestore.collection('workspace_invitations');

  // ============ WORKSPACE CRUD ============

  /// Create a new workspace
  Future<String> createWorkspace({
    required String name,
    required String ownerId,
  }) async {
    try {
      final workspace = WorkspaceModel(
        id: '', // Will be set by Firestore
        name: name,
        ownerId: ownerId,
        memberIds: [ownerId],
        createdAt: DateTime.now(),
        settings: WorkspaceSettings(),
      );

      final docRef = await _workspacesCollection.add(workspace.toMap());
      
      // Create workspace member entry for owner
      await addMember(
        workspaceId: docRef.id,
        userId: ownerId,
        role: WorkspaceRole.owner,
        invitedBy: ownerId,
      );

      debugPrint('Created workspace: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating workspace: $e');
      rethrow;
    }
  }

  /// Get a workspace by ID
  Future<WorkspaceModel?> getWorkspace(String workspaceId) async {
    try {
      final doc = await _workspacesCollection.doc(workspaceId).get();
      if (doc.exists) {
        return WorkspaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting workspace: $e');
      return null;
    }
  }

  /// Stream a workspace for real-time updates
  Stream<WorkspaceModel?> streamWorkspace(String workspaceId) {
    return _workspacesCollection.doc(workspaceId).snapshots().map((doc) {
      if (doc.exists) {
        return WorkspaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Get all workspaces for a user
  Future<List<WorkspaceModel>> getUserWorkspaces(String userId) async {
    try {
      // Get all workspace memberships for this user
      final memberDocs = await _membersCollection
          .where('userId', isEqualTo: userId)
          .get();

      final workspaceIds = memberDocs.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['workspaceId'] as String)
          .toList();

      if (workspaceIds.isEmpty) return [];

      // Get all workspaces
      final workspaces = <WorkspaceModel>[];
      for (final workspaceId in workspaceIds) {
        final workspace = await getWorkspace(workspaceId);
        if (workspace != null) {
          workspaces.add(workspace);
        }
      }

      return workspaces;
    } catch (e) {
      debugPrint('Error getting user workspaces: $e');
      return [];
    }
  }

  /// Stream all workspaces for a user
  Stream<List<WorkspaceModel>> streamUserWorkspaces(String userId) {
    return _membersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final workspaceIds = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['workspaceId'] as String)
          .toList();

      if (workspaceIds.isEmpty) return <WorkspaceModel>[];

      final workspaces = <WorkspaceModel>[];
      for (final workspaceId in workspaceIds) {
        final workspace = await getWorkspace(workspaceId);
        if (workspace != null) {
          workspaces.add(workspace);
        }
      }

      return workspaces;
    });
  }

  /// Update workspace
  Future<void> updateWorkspace(String workspaceId, Map<String, dynamic> updates) async {
    try {
      await _workspacesCollection.doc(workspaceId).update(updates);
      debugPrint('Updated workspace: $workspaceId');
    } catch (e) {
      debugPrint('Error updating workspace: $e');
      rethrow;
    }
  }

  /// Delete workspace and all related data
  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      final batch = _firestore.batch();

      // Delete all members
      final memberDocs = await _membersCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();
      for (final doc in memberDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all invitations
      final inviteDocs = await _invitationsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();
      for (final doc in inviteDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete workspace
      batch.delete(_workspacesCollection.doc(workspaceId));

      await batch.commit();
      debugPrint('Deleted workspace: $workspaceId');
    } catch (e) {
      debugPrint('Error deleting workspace: $e');
      rethrow;
    }
  }

  // ============ MEMBER MANAGEMENT ============

  /// Add a member to workspace
  Future<void> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceRole role,
    required String invitedBy,
  }) async {
    try {
      // Fetch user info from Firestore to cache in member document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      String? displayName;
      String? email;
      String? photoURL;
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        displayName = userData['displayName'];
        email = userData['email'];
        photoURL = userData['photoURL'];
      }

      final memberId = WorkspaceMember.generateId(userId, workspaceId);
      final member = WorkspaceMember(
        id: memberId,
        userId: userId,
        workspaceId: workspaceId,
        role: role,
        joinedAt: DateTime.now(),
        invitedBy: invitedBy,
        displayName: displayName,
        email: email,
        photoURL: photoURL,
      );

      await _membersCollection.doc(memberId).set(member.toMap());

      // Update workspace memberIds array
      await _workspacesCollection.doc(workspaceId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      debugPrint('Added member $userId to workspace $workspaceId');
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  /// Remove a member from workspace
  Future<void> removeMember(String workspaceId, String userId) async {
    try {
      final memberId = WorkspaceMember.generateId(userId, workspaceId);
      await _membersCollection.doc(memberId).delete();

      // Update workspace memberIds array
      await _workspacesCollection.doc(workspaceId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      debugPrint('Removed member $userId from workspace $workspaceId');
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  /// Update member role
  Future<void> updateMemberRole(String workspaceId, String userId, WorkspaceRole newRole) async {
    try {
      final memberId = WorkspaceMember.generateId(userId, workspaceId);
      await _membersCollection.doc(memberId).update({
        'role': newRole.toFirestore(),
      });
      debugPrint('Updated role for $userId in workspace $workspaceId to $newRole');
    } catch (e) {
      debugPrint('Error updating member role: $e');
      rethrow;
    }
  }

  /// Get all members of a workspace
  Future<List<WorkspaceMember>> getMembers(String workspaceId) async {
    try {
      final snapshot = await _membersCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      return snapshot.docs
          .map((doc) => WorkspaceMember.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting members: $e');
      return [];
    }
  }

  /// Stream workspace members
  Stream<List<WorkspaceMember>> streamMembers(String workspaceId) {
    return _membersCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkspaceMember.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ============ INVITATIONS ============

  /// Create an invitation
  Future<String> createInvitation({
    required String workspaceId,
    required String createdBy,
    int daysValid = 7,
    int maxUses = -1,
  }) async {
    try {
      final invitation = WorkspaceInvitation.create(
        workspaceId: workspaceId,
        createdBy: createdBy,
        daysValid: daysValid,
        maxUses: maxUses,
      );

      final docRef = await _invitationsCollection.add(invitation.toMap());
      debugPrint('Created invitation: ${invitation.inviteCode}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating invitation: $e');
      rethrow;
    }
  }

  /// Get invitation by code
  Future<WorkspaceInvitation?> getInvitationByCode(String code) async {
    try {
      final snapshot = await _invitationsCollection
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return WorkspaceInvitation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Error getting invitation by code: $e');
      return null;
    }
  }

  /// Join workspace with invite code
  Future<bool> joinWorkspaceWithCode(String userId, String inviteCode) async {
    try {
      final invitation = await getInvitationByCode(inviteCode);
      
      if (invitation == null || !invitation.isValid) {
        debugPrint('Invalid or expired invitation');
        return false;
      }

      // Check if user is already a member
      final memberId = WorkspaceMember.generateId(userId, invitation.workspaceId);
      final existingMember = await _membersCollection.doc(memberId).get();
      if (existingMember.exists) {
        debugPrint('User is already a member');
        return false;
      }

      // Add user as member
      await addMember(
        workspaceId: invitation.workspaceId,
        userId: userId,
        role: WorkspaceRole.member,
        invitedBy: invitation.createdBy,
      );

      // Increment usage count
      await _invitationsCollection.doc(invitation.id).update({
        'usedCount': FieldValue.increment(1),
      });

      debugPrint('User $userId joined workspace ${invitation.workspaceId}');
      return true;
    } catch (e) {
      debugPrint('Error joining workspace: $e');
      return false;
    }
  }

  /// Revoke an invitation
  Future<void> revokeInvitation(String invitationId) async {
    try {
      await _invitationsCollection.doc(invitationId).update({
        'isActive': false,
      });
      debugPrint('Revoked invitation: $invitationId');
    } catch (e) {
      debugPrint('Error revoking invitation: $e');
      rethrow;
    }
  }

  /// Get all invitations for a workspace
  Future<List<WorkspaceInvitation>> getWorkspaceInvitations(String workspaceId) async {
    try {
      final snapshot = await _invitationsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkspaceInvitation.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting workspace invitations: $e');
      return [];
    }
  }

  // ============ PERMISSIONS ============

  /// Get user's role in workspace
  Future<WorkspaceRole?> getUserRole(String userId, String workspaceId) async {
    try {
      final memberId = WorkspaceMember.generateId(userId, workspaceId);
      final doc = await _membersCollection.doc(memberId).get();
      
      if (!doc.exists) return null;
      
      final member = WorkspaceMember.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      return member.role;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Check if user can edit in workspace
  Future<bool> canUserEdit(String userId, String workspaceId) async {
    final role = await getUserRole(userId, workspaceId);
    return role?.canEdit ?? false;
  }

  /// Check if user can invite members
  Future<bool> canUserInvite(String userId, String workspaceId) async {
    final role = await getUserRole(userId, workspaceId);
    if (role == null) return false;

    // Check role permission
    if (!role.canManageMembers) return false;

    // Check workspace settings
    final workspace = await getWorkspace(workspaceId);
    return workspace?.settings.allowMemberInvites ?? false;
  }

  /// Check if user is workspace owner
  Future<bool> isWorkspaceOwner(String userId, String workspaceId) async {
    final workspace = await getWorkspace(workspaceId);
    return workspace?.ownerId == userId;
  }
}
