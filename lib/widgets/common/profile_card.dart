import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';

/// Profile card showing user info and lead statistics
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // User info row
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 22 : 26,
                      backgroundColor: AppColors.lavenderMist,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(
                              Icons.person_rounded,
                              size: isMobile ? 22 : 26,
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.mediumGrey,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Divider(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.5)),
            SizedBox(height: isMobile ? 16 : 20),
            // Stats
            Consumer<LeadsProvider>(
              builder: (context, leadsProvider, _) {
                final stats = leadsProvider.userStats;
                return _buildStatsGrid(context, stats, isMobile);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic stats, bool isMobile) {
    final items = [
      _StatData('Total Leads', stats.totalLeads.toString(), AppColors.primaryPurple),
      _StatData('Unreached', stats.unreached.toString(), AppColors.mediumGrey),
      _StatData('Follow Ups', stats.followUps.toString(), AppColors.warningOrange),
      _StatData('No Response', stats.noResponse.toString(), AppColors.errorRed),
      _StatData('Accepted', stats.accepted.toString(), AppColors.successGreen),
      _StatData('Rate', '${stats.conversionRate.toStringAsFixed(1)}%', AppColors.infoBlue),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: isMobile ? 1.1 : 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StatItem(
          label: item.label,
          value: item.value,
          color: item.color,
          isMobile: isMobile,
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;

  _StatData(this.label, this.value, this.color);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isMobile;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: AppColors.mediumGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
