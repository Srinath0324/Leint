import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/workspace_model.dart';
import '../providers/workspace_provider.dart';
import '../core/utils/responsive.dart';
import '../screens/workspace/workspace_settings_screen.dart';

/// Dropdown widget for selecting workspaces
class WorkspaceDropdown extends StatelessWidget {
  const WorkspaceDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, workspaceProvider, _) {
        final currentWorkspace = workspaceProvider.currentWorkspace;
        final workspaces = workspaceProvider.userWorkspaces;

        if (workspaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final isMobile = Responsive.isMobile(context);

        return PopupMenuButton<String>(
          tooltip: 'Switch workspace',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspaces,
                  size: isMobile ? 18 : 20,
                  color: AppColors.primaryPurple,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Flexible(
                  child: Text(
                    currentWorkspace?.name ?? 'Select Workspace',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Icon(
                  Icons.arrow_drop_down,
                  size: isMobile ? 20 : 24,
                  color: AppColors.mediumGrey,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            // List all workspaces
            ...workspaces.map((workspace) {
              final isSelected = workspace.id == currentWorkspace?.id;
              return PopupMenuItem<String>(
                value: workspace.id,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                    if (isSelected) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workspace.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primaryPurple : AppColors.darkCharcoal,
                        ),
                      ),
                    ),
                    Text(
                      '${workspace.memberCount} ${workspace.memberCount == 1 ? 'member' : 'members'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const PopupMenuDivider(),
            // Workspace settings (for mobile)
            if (Responsive.isMobile(context))
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18, color: AppColors.mediumGrey),
                    SizedBox(width: 8),
                    Text(
                      'Workspace Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
            if (Responsive.isMobile(context))
              const PopupMenuDivider(),
            // Create new workspace
            const PopupMenuItem<String>(
              value: 'create',
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    'Create Workspace',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
            // Join workspace
            const PopupMenuItem<String>(
              value: 'join',
              child: Row(
                children: [
                  Icon(Icons.group_add, size: 18, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    'Join Workspace',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'create') {
              _showCreateWorkspaceDialog(context);
            } else if (value == 'join') {
              _showJoinWorkspaceDialog(context);
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkspaceSettingsScreen(),
                ),
              );
            } else {
              // Switch to selected workspace
              await workspaceProvider.switchWorkspace(value);
            }
          },
        );
      },
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Workspace Name',
              hintText: 'e.g., Sales Team, Marketing',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a workspace name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final workspaceProvider = context.read<WorkspaceProvider>();
                final workspaceId = await workspaceProvider.createWorkspace(
                  nameController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (workspaceId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workspace created successfully!')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinWorkspaceDialog(BuildContext context) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Workspace'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-character invite code to join a workspace.',
                style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  hintText: 'ABC123',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an invite code';
                  }
                  if (value.trim().length != 6) {
                    return 'Invite code must be 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final workspaceProvider = context.read<WorkspaceProvider>();
                final success = await workspaceProvider.joinWorkspace(
                  codeController.text.trim().toUpperCase(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined workspace successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(workspaceProvider.error ?? 'Failed to join workspace'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
