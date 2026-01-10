import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workspace_model.dart';
import '../models/workspace_member_model.dart';
import '../models/workspace_invitation_model.dart';
import '../services/workspace_service.dart';

/// Provider for managing workspace state and operations
class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceService _workspaceService = WorkspaceService();

  String? _currentUserId;
  String? _currentWorkspaceId;
  WorkspaceModel? _currentWorkspace;
  List<WorkspaceModel> _userWorkspaces = [];
  List<WorkspaceMember> _currentWorkspaceMembers = [];
  
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<WorkspaceModel>>? _workspacesSubscription;
  StreamSubscription<WorkspaceModel?>? _currentWorkspaceSubscription;
  StreamSubscription<List<WorkspaceMember>>? _membersSubscription;

  // Getters
  String? get currentWorkspaceId => _currentWorkspaceId;
  WorkspaceModel? get currentWorkspace => _currentWorkspace;
  List<WorkspaceModel> get userWorkspaces => _userWorkspaces;
  List<WorkspaceMember> get currentWorkspaceMembers => _currentWorkspaceMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWorkspace => _currentWorkspace != null;

  /// Initialize provider with user ID
  void initialize(String userId) {
    if (_currentUserId == userId) return; // Already initialized
    
    _currentUserId = userId;
    _startListeners();
  }

  /// Start real-time listeners
  void _startListeners() {
    if (_currentUserId == null) return;

    // Listen to user's workspaces
    _workspacesSubscription?.cancel();
    _workspacesSubscription = _workspaceService
        .streamUserWorkspaces(_currentUserId!)
        .listen(
          (workspaces) {
            _userWorkspaces = workspaces;
            
            // If no current workspace set, use the first one
            if (_currentWorkspaceId == null && workspaces.isNotEmpty) {
              switchWorkspace(workspaces.first.id);
            }
            
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error streaming workspaces: $error');
            _error = 'Failed to load workspaces';
            notifyListeners();
          },
        );
  }

  /// Switch to a different workspace
  Future<void> switchWorkspace(String workspaceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentWorkspaceId = workspaceId;

      // Listen to current workspace
      _currentWorkspaceSubscription?.cancel();
      _currentWorkspaceSubscription = _workspaceService
          .streamWorkspace(workspaceId)
          .listen(
            (workspace) {
              _currentWorkspace = workspace;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error streaming workspace: $error');
            },
          );

      // Listen to workspace members
      _membersSubscription?.cancel();
      _membersSubscription = _workspaceService
          .streamMembers(workspaceId)
          .listen(
            (members) {
              _currentWorkspaceMembers = members;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error streaming members: $error');
            },
          );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to switch workspace: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new workspace
  Future<String?> createWorkspace(String name) async {
    if (_currentUserId == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final workspaceId = await _workspaceService.createWorkspace(
        name: name,
        ownerId: _currentUserId!,
      );

      // Switch to the new workspace
      await switchWorkspace(workspaceId);

      _isLoading = false;
      notifyListeners();
      return workspaceId;
    } catch (e) {
      _error = 'Failed to create workspace: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update workspace name
  Future<bool> updateWorkspaceName(String newName) async {
    if (_currentWorkspaceId == null) return false;

    try {
      await _workspaceService.updateWorkspace(_currentWorkspaceId!, {
        'name': newName,
      });
      return true;
    } catch (e) {
      _error = 'Failed to update workspace: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete current workspace
  Future<bool> deleteWorkspace() async {
    if (_currentWorkspaceId == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.deleteWorkspace(_currentWorkspaceId!);

      // Clear current workspace
      _currentWorkspaceId = null;
      _currentWorkspace = null;
      _currentWorkspaceMembers = [];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete workspace: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create an invitation
  Future<String?> createInvitation({int daysValid = 7, int maxUses = -1}) async {
    if (_currentWorkspaceId == null || _currentUserId == null) return null;

    try {
      final invitationId = await _workspaceService.createInvitation(
        workspaceId: _currentWorkspaceId!,
        createdBy: _currentUserId!,
        daysValid: daysValid,
        maxUses: maxUses,
      );

      // Get the invitation to return the code
      final invitations = await _workspaceService.getWorkspaceInvitations(_currentWorkspaceId!);
      final invitation = invitations.firstWhere((inv) => inv.id == invitationId);
      
      return invitation.inviteCode;
    } catch (e) {
      _error = 'Failed to create invitation: $e';
      notifyListeners();
      return null;
    }
  }

  /// Join workspace with code
  Future<bool> joinWorkspace(String inviteCode) async {
    if (_currentUserId == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _workspaceService.joinWorkspaceWithCode(
        _currentUserId!,
        inviteCode,
      );

      _isLoading = false;
      
      if (!success) {
        _error = 'Invalid or expired invite code';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to join workspace: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from current workspace
  Future<bool> removeMember(String userId) async {
    if (_currentWorkspaceId == null) return false;

    try {
      await _workspaceService.removeMember(_currentWorkspaceId!, userId);
      return true;
    } catch (e) {
      _error = 'Failed to remove member: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update member role
  Future<bool> updateMemberRole(String userId, WorkspaceRole newRole) async {
    if (_currentWorkspaceId == null) return false;

    try {
      await _workspaceService.updateMemberRole(_currentWorkspaceId!, userId, newRole);
      return true;
    } catch (e) {
      _error = 'Failed to update member role: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check if current user can edit
  Future<bool> canCurrentUserEdit() async {
    if (_currentUserId == null || _currentWorkspaceId == null) return false;
    return await _workspaceService.canUserEdit(_currentUserId!, _currentWorkspaceId!);
  }

  /// Check if current user can invite
  Future<bool> canCurrentUserInvite() async {
    if (_currentUserId == null || _currentWorkspaceId == null) return false;
    return await _workspaceService.canUserInvite(_currentUserId!, _currentWorkspaceId!);
  }

  /// Check if current user is owner
  bool get isCurrentUserOwner {
    if (_currentUserId == null || _currentWorkspace == null) return false;
    return _currentWorkspace!.isOwner(_currentUserId!);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _workspacesSubscription?.cancel();
    _currentWorkspaceSubscription?.cancel();
    _membersSubscription?.cancel();
    _currentUserId = null;
    super.dispose();
  }
}
