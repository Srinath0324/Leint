import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';
import '../../widgets/common/profile_card.dart';
import '../../widgets/common/responsive_navbar.dart';
import '../../widgets/dialogs/upload_dialog.dart';
import '../../widgets/tables/history_table.dart';
import '../leads/leads_screen.dart';
import '../lead_detail/lead_detail_screen.dart';

/// Main Dashboard/Home screen with real-time updates
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentNavIndex = 0;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeProvider();
      _isInitialized = true;
    }
  }

  void _initializeProvider() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<LeadsProvider>().initialize(authProvider.currentUser!.uid);
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _showUploadDialog([PlatformFile? preSelectedFile]) {
    showDialog(
      context: context,
      builder: (dialogContext) => UploadDialog(
        preSelectedFile: preSelectedFile,
        onUpload: (file, title, source) async {
          Navigator.pop(dialogContext);
          
          final leadsProvider = context.read<LeadsProvider>();
          final success = await leadsProvider.uploadCsvFile(
            file: file,
            title: title,
            source: source,
          );

          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ CSV uploaded successfully! Data will appear shortly.'),
                  backgroundColor: AppColors.successGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(leadsProvider.error ?? 'Upload failed'),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _navigateToLeadDetail(leadFile) {
    final leadsProvider = context.read<LeadsProvider>();
    leadsProvider.selectLeadFile(leadFile);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeadDetailScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.softLavender,
      drawer: isMobile
          ? NavigationDrawerWidget(
              currentIndex: _currentNavIndex,
              onDestinationSelected: _onDestinationSelected,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Navbar
            ResponsiveNavbar(
              currentIndex: _currentNavIndex,
              onDestinationSelected: _onDestinationSelected,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            // Content
            Expanded(
              child: _currentNavIndex == 0
                  ? _buildDashboardContent()
                  : const LeadsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final isMobile = Responsive.isMobile(context);

    return Consumer<LeadsProvider>(
      builder: (context, leadsProvider, _) {
        // Show uploading overlay
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload section
                      _buildUploadSection(isMobile),
                      SizedBox(height: isMobile ? 16 : 24),

                      // Profile and History section
                      if (isMobile) ...[
                        const ProfileCard(),
                        const SizedBox(height: 16),
                        _buildHistorySection(leadsProvider),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Card
                            const SizedBox(
                              width: 320,
                              child: ProfileCard(),
                            ),
                            const SizedBox(width: 24),
                            // History Table
                            Expanded(child: _buildHistorySection(leadsProvider)),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Uploading overlay
            if (leadsProvider.isUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Uploading CSV...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUploadSection(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lavenderWash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUploadDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 24 : 36,
              horizontal: isMobile ? 16 : 24,
            ),
            child: isMobile
                ? _buildMobileUploadContent()
                : _buildDesktopUploadContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUploadContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_rounded,
            size: 28,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Upload CSV File',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to browse your leads file',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDesktopUploadContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_rounded,
            size: 32,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload CSV File',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click to browse or drop your leads file here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection(LeadsProvider leadsProvider) {
    return HistoryTable(
      leadFiles: leadsProvider.recentLeadFiles,
      isLoading: leadsProvider.isLoadingLeadFiles,
      onRowTap: _navigateToLeadDetail,
      onViewAllPressed: () {
        setState(() {
          _currentNavIndex = 1;
        });
      },
    );
  }
}
