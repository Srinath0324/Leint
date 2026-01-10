import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/workspace_member_model.dart';

/// Widget to display a list of member avatars
class MemberAvatarList extends StatelessWidget {
  final List<WorkspaceMember> members;
  final int maxVisible;
  final double size;

  const MemberAvatarList({
    super.key,
    required this.members,
    this.maxVisible = 3,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount = members.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
            child: _MemberAvatar(
              member: member,
              size: size,
            ),
          );
        }),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _RemainingCountBadge(
              count: remainingCount,
              size: size,
            ),
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final WorkspaceMember member;
  final double size;

  const _MemberAvatar({
    required this.member,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${member.userId} (${member.role.displayName})',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getColorForRole(member.role),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pureWhite, width: 2),
        ),
        child: Center(
          child: Text(
            _getInitials(member.userId),
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String userId) {
    // Extract initials from user ID (email)
    final parts = userId.split('@');
    if (parts.isEmpty) return '?';
    
    final name = parts[0];
    if (name.isEmpty) return '?';
    
    return name.substring(0, 1).toUpperCase();
  }

  Color _getColorForRole(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner:
        return AppColors.primaryPurple;
      case WorkspaceRole.admin:
        return AppColors.successGreen;
      case WorkspaceRole.member:
        return AppColors.warningOrange;
      case WorkspaceRole.viewer:
        return AppColors.mediumGrey;
    }
  }
}

class _RemainingCountBadge extends StatelessWidget {
  final int count;
  final double size;

  const _RemainingCountBadge({
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pureWhite, width: 2),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: AppColors.darkCharcoal,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
