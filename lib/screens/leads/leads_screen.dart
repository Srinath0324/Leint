import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/lead_file_model.dart';
import '../../providers/leads_provider.dart';
import '../../widgets/dialogs/upload_dialog.dart';
import '../lead_detail/lead_detail_screen.dart';

/// Screen showing all leads with real-time updates
class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  void _showNewLeadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => UploadDialog(
        onUpload: (file, title, source) async {
          Navigator.pop(dialogContext);
          
          final leadsProvider = context.read<LeadsProvider>();
          final success = await leadsProvider.uploadCsvFile(
            file: file,
            title: title,
            source: source,
          );

          if (context.mounted) {
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

  void _navigateToLeadDetail(BuildContext context, LeadFileModel leadFile) {
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

    return Consumer<LeadsProvider>(
      builder: (context, leadsProvider, _) {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: Responsive.padding(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Leads',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showNewLeadDialog(context),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('New'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 1,
                          color: AppColors.borderGrey.withValues(alpha: 0.5),
                        ),
                        // Table
                        if (leadsProvider.isLoadingLeadFiles)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (leadsProvider.leadFiles.isEmpty)
                          _buildEmptyState(context)
                        else if (isMobile)
                          _buildMobileList(context, leadsProvider.leadFiles)
                        else
                          _buildDesktopTable(context, leadsProvider.leadFiles),
                      ],
                    ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lavenderMist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: AppColors.primaryPurple.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No leads uploaded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkCharcoal,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "+ New" to upload your first CSV file',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<LeadFileModel> leadFiles) {
    return Column(
      children: [
        // Table header - Changed "Accepted" to "Follow Ups"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.softLavender,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderGrey.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildHeaderCell('#', flex: 1),
              _buildHeaderCell('Title', flex: 3),
              _buildHeaderCell('Platform', flex: 2),
              _buildHeaderCell('Total Leads', flex: 1, align: TextAlign.center),
              _buildHeaderCell('Unreached', flex: 1, align: TextAlign.center),
              _buildHeaderCell('Follow Ups', flex: 1, align: TextAlign.center), // Changed from "Accepted"
              _buildHeaderCell('Date', flex: 2, align: TextAlign.center),
            ],
          ),
        ),
        // Table rows
        ...List.generate(leadFiles.length, (index) {
          final file = leadFiles[index];
          return _buildTableRow(context, file, index);
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkCharcoal,
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, LeadFileModel file, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToLeadDetail(context, file),
        hoverColor: AppColors.lavenderWash,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderGrey.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mediumGrey,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  file.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  file.source,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  file.totalLeads.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
              // Unreached (real-time from Firestore)
              Expanded(
                flex: 1,
                child: Text(
                  file.unreached.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mediumGrey,
                  ),
                ),
              ),
              // Follow Ups (real-time from Firestore) - Changed from "Accepted"
              Expanded(
                flex: 1,
                child: Text(
                  file.followUps.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warningOrange,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(file.uploadDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<LeadFileModel> leadFiles) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: leadFiles.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.borderGrey.withValues(alpha: 0.3),
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final file = leadFiles[index];
        return ListTile(
          onTap: () => _navigateToLeadDetail(context, file),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lavenderMist,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
          title: Text(
            file.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryPurple,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                file.source,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildStatChip('Total: ${file.totalLeads}', AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  _buildStatChip('Unreached: ${file.unreached}', AppColors.mediumGrey),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd MMM').format(file.uploadDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.lightGrey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
