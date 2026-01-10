import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/member_avatar_list.dart';
import '../../models/workspace_member_model.dart';

/// Screen for managing workspace settings
class WorkspaceSettingsScreen extends StatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  State<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends State<WorkspaceSettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Settings'),
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.darkCharcoal,
        elevation: 0,
      ),
      body: Consumer<WorkspaceProvider>(
        builder: (context, workspaceProvider, _) {
          final workspace = workspaceProvider.currentWorkspace;
          final members = workspaceProvider.currentWorkspaceMembers;
          final isOwner = workspaceProvider.isCurrentUserOwner;

          if (workspace == null) {
            return const Center(
              child: Text('No workspace selected'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Name Section
                _buildSection(
                  title: 'Workspace Name',
                  child: _buildNameSection(workspace.name, isOwner, workspaceProvider),
                  isMobile: isMobile,
                ),
                
                const SizedBox(height: 24),
                
                // Members Section
                _buildSection(
                  title: 'Members (${members.length})',
                  child: _buildMembersSection(members, isOwner, workspaceProvider),
                  isMobile: isMobile,
                ),
                
                const SizedBox(height: 24),
                
                // Invite Section
                if (isOwner)
                  _buildSection(
                    title: 'Invite Members',
                    child: _buildInviteSection(workspaceProvider),
                    isMobile: isMobile,
                  ),
                
                const SizedBox(height: 24),
                
                // Danger Zone
                if (isOwner)
                  _buildSection(
                    title: 'Danger Zone',
                    child: _buildDangerZone(workspaceProvider),
                    isMobile: isMobile,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNameSection(String name, bool isOwner, WorkspaceProvider provider) {
    if (!_isEditing) {
      return Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkCharcoal,
              ),
            ),
          ),
          if (isOwner)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _nameController.text = name;
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Workspace name',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() => _isEditing = false);
          },
          icon: const Icon(Icons.close),
        ),
        IconButton(
          onPressed: () async {
            final success = await provider.updateWorkspaceName(_nameController.text.trim());
            if (success && mounted) {
              setState(() => _isEditing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workspace name updated')),
              );
            }
          },
          icon: const Icon(Icons.check, color: AppColors.successGreen),
        ),
      ],
    );
  }

  Widget _buildMembersSection(
    List<WorkspaceMember> members,
    bool isOwner,
    WorkspaceProvider provider,
  ) {
    if (members.isEmpty) {
      return const Text('No members yet');
    }

    return Column(
      children: members.map((member) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lavenderMist,
                backgroundImage: member.photoURL != null
                    ? NetworkImage(member.photoURL!)
                    : null,
                child: member.photoURL == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: AppColors.primaryPurple,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayNameOrEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    if (member.email != null && member.displayName != null)
                      Text(
                        member.email!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    Text(
                      member.role.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner && member.role != WorkspaceRole.owner)
                IconButton(
                  onPressed: () => _showRemoveMemberDialog(member, provider),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                  tooltip: 'Remove member',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInviteSection(WorkspaceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generate an invite code to add members to this workspace.',
          style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _generateInviteCode(provider),
          icon: const Icon(Icons.link),
          label: const Text('Generate Invite Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.pureWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(WorkspaceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Once you delete a workspace, there is no going back. Please be certain.',
          style: TextStyle(fontSize: 14, color: AppColors.errorRed),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showDeleteWorkspaceDialog(provider),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete Workspace'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorRed,
            side: const BorderSide(color: AppColors.errorRed),
          ),
        ),
      ],
    );
  }

  void _generateInviteCode(WorkspaceProvider provider) async {
    final code = await provider.createInvitation(daysValid: 7);
    
    if (code != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite Code Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with people you want to invite:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This code will expire in 7 days.',
                style: TextStyle(fontSize: 12, color: AppColors.mediumGrey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showRemoveMemberDialog(WorkspaceMember member, WorkspaceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.displayNameOrEmail} from this workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.removeMember(member.userId);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member removed')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkspaceDialog(WorkspaceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: const Text(
          'Are you sure you want to delete this workspace? This action cannot be undone and all data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.deleteWorkspace();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close settings screen
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workspace deleted')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
