import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/lead_file_model.dart';

/// Table showing last 5 uploaded lead files - matches LeadStal design
class HistoryTable extends StatelessWidget {
  final List<LeadFileModel> leadFiles;
  final Function(LeadFileModel) onRowTap;
  final VoidCallback onViewAllPressed;
  final bool isLoading;

  const HistoryTable({
    super.key,
    required this.leadFiles,
    required this.onRowTap,
    required this.onViewAllPressed,
    this.isLoading = false,
  });

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
                  'Last History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
                TextButton.icon(
                  onPressed: onViewAllPressed,
                  icon: Text(
                    'View All Leads',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  label: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: AppColors.borderGrey.withValues(alpha: 0.5),
          ),
          // Content
          if (isLoading)
            _buildLoadingState()
          else if (leadFiles.isEmpty)
            _buildEmptyState(context)
          else if (isMobile)
            _buildMobileList(context)
          else
            _buildDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
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
                size: 40,
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
              'Upload a CSV file to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Column(
      children: [
        // Table header - Changed "Valid Leads" to "Unreached"
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
              _buildHeaderCell('Titles', flex: 3),
              _buildHeaderCell('Platforms', flex: 2),
              _buildHeaderCell('Total Leads', flex: 1, align: TextAlign.center),
              _buildHeaderCell('Unreached', flex: 1, align: TextAlign.center), // Changed from "Valid Leads"
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
        onTap: () => onRowTap(file),
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
              // Title with number
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                  ],
                ),
              ),
              // Platform
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
              // Total Leads
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
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
              // Date
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

  Widget _buildMobileList(BuildContext context) {
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
          onTap: () => onRowTap(file),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  file.source,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.lightGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${file.totalLeads} leads',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                ),
              ],
            ),
          ),
          trailing: Text(
            DateFormat('dd MMM').format(file.uploadDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      },
    );
  }
}
