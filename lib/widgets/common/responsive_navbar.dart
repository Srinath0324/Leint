import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/workspace_dropdown.dart';
import '../../screens/workspace/workspace_settings_screen.dart';

/// Responsive navigation bar with hamburger menu for mobile
class ResponsiveNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback? onMenuPressed;

  const ResponsiveNavbar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
          ),
          child: Row(
            children: [
              // Hamburger menu for mobile
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 24),
                  onPressed: onMenuPressed,
                  color: AppColors.darkCharcoal,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Logo - Clickable to navigate to Dashboard
              InkWell(
                onTap: () => onDestinationSelected(0), // Navigate to Dashboard
                borderRadius: BorderRadius.circular(8),
                child: _buildLogo(context, isMobile),
              ),

              const Spacer(),

              // Navigation items (desktop only)
              if (!isMobile) ...[
                _buildNavItem(
                  context: context,
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                const SizedBox(width: 8),
                _buildNavItem(
                  context: context,
                  label: 'Leads',
                  icon: Icons.people_rounded,
                  isSelected: currentIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                const SizedBox(width: 16),
              ],

              // Workspace dropdown (flexible to prevent overflow)
              if (!isMobile)
                _buildWorkspaceSection(context, isMobile)
              else
                Expanded(
                  child: _buildWorkspaceSection(context, isMobile),
                ),
              
              SizedBox(width: isMobile ? 4 : 12),

              // Profile/Logout button
              _buildProfileButton(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo image - INCREASED SIZE
          Image.asset(
            'assets/leint_logo.png',
            width: isMobile ? 44 : 48,  // Increased from 32/36 to 44/48
            height: isMobile ? 44 : 48, // Increased from 32/36 to 44/48
            errorBuilder: (context, error, stackTrace) {
              // Fallback to gradient container if image fails
              return Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: isMobile ? 24 : 28,
                  color: AppColors.pureWhite,
                ),
              );
            },
          ),

          RichText(
  text: TextSpan(
    style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
    children: [
      TextSpan(
        text: 'Le',
        style: TextStyle(
          color: AppColors.primaryPurple,
        ),
      ),
      TextSpan(
        text: 'Int',
        style: TextStyle(
          color: AppColors.infoBlue,
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryPurple.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? AppColors.primaryPurple 
                    : AppColors.mediumGrey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected 
                      ? AppColors.primaryPurple 
                      : AppColors.mediumGrey,
                  fontWeight: isSelected 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceSection(BuildContext context, bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Workspace dropdown (flexible on mobile)
        if (isMobile)
          const Flexible(
            child: WorkspaceDropdown(),
          )
        else
          const WorkspaceDropdown(),
        // Settings button (desktop only - mobile has it in dropdown)
        if (!isMobile) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkspaceSettingsScreen(),
                ),
              );
            },
            tooltip: 'Workspace Settings',
            color: AppColors.mediumGrey,
          ),
        ],
      ],
    );
  }

  Widget _buildProfileButton(BuildContext context, bool isMobile) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: isMobile ? 14 : 16,
              backgroundColor: AppColors.lavenderMist,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(
                      Icons.person_rounded,
                      size: isMobile ? 16 : 18,
                      color: AppColors.primaryPurple,
                    )
                  : null,
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              authProvider.signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.errorRed),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: AppColors.errorRed)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Navigation drawer for mobile
class NavigationDrawerWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const NavigationDrawerWidget({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.pureWhite,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            Image.asset(
              'assets/leint_logo.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    size: 40,
                    color: AppColors.pureWhite,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'LeInt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Leads Interpreter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Nav items
            _buildDrawerItem(
              context: context,
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isSelected: currentIndex == 0,
              onTap: () {
                onDestinationSelected(0);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.people_rounded,
              label: 'Leads',
              isSelected: currentIndex == 1,
              onTap: () {
                onDestinationSelected(1);
                Navigator.pop(context);
              },
            ),
            // Workspace Settings
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              label: 'Workspace Settings',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkspaceSettingsScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            // Profile section
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                return Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.lavenderMist,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
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
                                  user?.displayName ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? '',
                                  style: const TextStyle(
                                    color: AppColors.mediumGrey,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            authProvider.signOut();
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: const BorderSide(color: AppColors.errorRed),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected 
            ? AppColors.primaryPurple.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppColors.primaryPurple : AppColors.mediumGrey,
            size: 22,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryPurple : AppColors.darkCharcoal,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
