import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/lead_model.dart';
import '../../providers/leads_provider.dart';

/// Lead Detail Screen with table, filters, and pagination
class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({super.key});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  // Filter states
  final Set<LeadStatus> _statusFilters = {};
  bool _showFilterDialog = false;
  
  // Filter toggles for Show Filter dialog
  bool _filterSocialMedia = false;
  bool _filterWebsite = false;
  bool _filterPhoneNumber = false;
  bool _filterEmails = false;
  bool _filterReview = false;
  bool _filterRatings = false;

  // Pagination
  int _currentPage = 1;
  final int _rowsPerPage = 20;

  List<LeadModel> get _filteredLeads {
    final leadsProvider = context.read<LeadsProvider>();
    var leads = List<LeadModel>.from(leadsProvider.selectedFileLeads);

    // Apply status filters
    if (_statusFilters.isNotEmpty) {
      leads = leads.where((lead) => _statusFilters.contains(lead.status)).toList();
    }

    // Apply field filters from Show Filter dialog
    if (_filterSocialMedia) {
      leads = leads.where((lead) => lead.socialMedias.isNotEmpty).toList();
    }
    if (_filterWebsite) {
      leads = leads.where((lead) => lead.website != 'Not Found').toList();
    }
    if (_filterPhoneNumber) {
      leads = leads.where((lead) => lead.phone != 'Not Found').toList();
    }
    if (_filterEmails) {
      leads = leads.where((lead) => lead.email != 'Not Found').toList();
    }
    if (_filterReview) {
      leads = leads.where((lead) => lead.reviews != 'Not Found').toList();
    }
    if (_filterRatings) {
      leads = leads.where((lead) => lead.ratings != 'Not Found').toList();
    }

    return leads;
  }

  List<LeadModel> get _paginatedLeads {
    final filtered = _filteredLeads;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get _totalPages {
    final total = _filteredLeads.length;
    return (total / _rowsPerPage).ceil();
  }

  void _toggleStatusFilter(LeadStatus status) {
    setState(() {
      // Single-select: clear all filters first, then add the new one
      if (_statusFilters.contains(status)) {
        // If clicking the same filter, deselect it
        _statusFilters.remove(status);
      } else {
        // Clear all filters and add only the new one
        _statusFilters.clear();
        _statusFilters.add(status);
      }
      _currentPage = 1; // Reset to first page
    });
  }

  void _openGoogleMaps(String url) async {
    if (url == 'Not Found') return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFilterDialogPopup() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        filterSocialMedia: _filterSocialMedia,
        filterWebsite: _filterWebsite,
        filterPhoneNumber: _filterPhoneNumber,
        filterEmails: _filterEmails,
        filterReview: _filterReview,
        filterRatings: _filterRatings,
        onApply: (socialMedia, website, phone, email, review, ratings) {
          setState(() {
            _filterSocialMedia = socialMedia;
            _filterWebsite = website;
            _filterPhoneNumber = phone;
            _filterEmails = email;
            _filterReview = review;
            _filterRatings = ratings;
            _currentPage = 1;
          });
        },
        onReset: () {
          setState(() {
            _filterSocialMedia = false;
            _filterWebsite = false;
            _filterPhoneNumber = false;
            _filterEmails = false;
            _filterReview = false;
            _filterRatings = false;
            _currentPage = 1;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softLavender,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<LeadsProvider>(
          builder: (context, provider, _) {
            final file = provider.selectedFile;
            return Text(
              file?.title ?? 'Lead Details',
              style: const TextStyle(
                color: AppColors.darkCharcoal,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      body: Consumer<LeadsProvider>(
        builder: (context, leadsProvider, _) {
          if (leadsProvider.isLoadingLeads) {
            return const Center(child: CircularProgressIndicator());
          }

          final file = leadsProvider.selectedFile;
          if (file == null) {
            return const Center(child: Text('No file selected'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<LeadsProvider>(
              builder: (context, provider, _) {
                // Get the latest file data from provider for real-time updates
                final latestFile = provider.leadFiles.firstWhere(
                  (f) => f.id == file.id,
                  orElse: () => file,
                );
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(latestFile), // Use latest file data
                    const SizedBox(height: 24),
                    _buildFiltersAndCount(),
                    const SizedBox(height: 16),
                    _buildLeadsTable(),
                    const SizedBox(height: 16),
                    _buildPagination(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(file) {
    final isMobile = Responsive.isMobile(context);
    
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
            file.title,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            file.source,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mediumGrey,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: 8,
            children: [
              _buildStatItem('Total', '${file.totalLeads} Leads', AppColors.primaryPurple),
              _buildStatItem('Unreached', '${file.unreached}', AppColors.mediumGrey),
              _buildStatItem('Accepted', '${file.accepted}', AppColors.successGreen),
              _buildStatItem('Date', _formatDate(file.uploadDate), AppColors.darkCharcoal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: AppColors.darkCharcoal),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildFiltersAndCount() {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter count
          Text(
            'Filter results: Total ${_filteredLeads.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          // Filter buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Unreached', LeadStatus.unreached),
              _buildFilterChip('Follow Up', LeadStatus.followUp),
              _buildFilterChip('No Response', LeadStatus.noResponse),
              _buildFilterChip('Status', null, isStatusMenu: true),
              _buildShowFilterButton(),
            ],
          ),
        ],
      );
    }
    
    return Row(
      children: [
        // Filter count
        Text(
          'Filter results: Total ${_filteredLeads.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkCharcoal,
          ),
        ),
        const Spacer(),
        // Filter buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('Unreached', LeadStatus.unreached),
            _buildFilterChip('Follow Up', LeadStatus.followUp),
            _buildFilterChip('No Response', LeadStatus.noResponse),
            _buildFilterChip('Status', null, isStatusMenu: true),
            _buildShowFilterButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, LeadStatus? status, {bool isStatusMenu = false}) {
    if (isStatusMenu) {
      return PopupMenuButton<LeadStatus>(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _statusFilters.contains(LeadStatus.accepted) || _statusFilters.contains(LeadStatus.rejected)
                ? AppColors.primaryPurple.withValues(alpha: 0.1)
                : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _statusFilters.contains(LeadStatus.accepted) || _statusFilters.contains(LeadStatus.rejected)
                      ? AppColors.primaryPurple
                      : AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: LeadStatus.accepted,
            child: Row(
              children: [
                if (_statusFilters.contains(LeadStatus.accepted))
                  const Icon(Icons.check, size: 16, color: AppColors.successGreen),
                if (_statusFilters.contains(LeadStatus.accepted)) const SizedBox(width: 8),
                const Text('Accepted'),
              ],
            ),
          ),
          PopupMenuItem(
            value: LeadStatus.rejected,
            child: Row(
              children: [
                if (_statusFilters.contains(LeadStatus.rejected))
                  const Icon(Icons.check, size: 16, color: AppColors.errorRed),
                if (_statusFilters.contains(LeadStatus.rejected)) const SizedBox(width: 8),
                const Text('Rejected'),
              ],
            ),
          ),
        ],
        onSelected: _toggleStatusFilter,
      );
    }

    final isActive = status != null && _statusFilters.contains(status);
    return InkWell(
      onTap: () => status != null ? _toggleStatusFilter(status) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPurple.withValues(alpha: 0.1) : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.primaryPurple : AppColors.borderGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primaryPurple : AppColors.darkCharcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildShowFilterButton() {
    final hasActiveFilters = _filterSocialMedia || _filterWebsite || _filterPhoneNumber || 
                             _filterEmails || _filterReview || _filterRatings;
    
    return InkWell(
      onTap: _showFilterDialogPopup,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.primaryPurple.withValues(alpha: 0.1) : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasActiveFilters ? AppColors.primaryPurple : AppColors.borderGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: hasActiveFilters ? AppColors.primaryPurple : AppColors.darkCharcoal,
            ),
            const SizedBox(width: 6),
            Text(
              'Show Filter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasActiveFilters ? AppColors.primaryPurple : AppColors.darkCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsTable() {
    if (_paginatedLeads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No leads match the current filters'),
        ),
      );
    }

    return Container(
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
        children: _paginatedLeads.map((lead) => _buildLeadCard(lead)).toList(),
      ),
    );
  }

  Widget _buildLeadCard(LeadModel lead) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name (clickable)
          InkWell(
            onTap: () => _openGoogleMaps(lead.googleMapsUrl),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (lead.googleMapsUrl != 'Not Found')
                  const Icon(Icons.open_in_new, size: 16, color: AppColors.primaryPurple),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Data grid
          isMobile ? _buildMobileDataLayout(lead) : _buildDataGrid(lead),
        ],
      ),
    );
  }

  // Mobile-friendly vertical layout
  Widget _buildMobileDataLayout(LeadModel lead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic info
        _buildMobileSection('Basic Info', [
          _buildField('Category', lead.categories),
          _buildField('Address', lead.address),
        ]),
        const SizedBox(height: 12),
        
        // Contact
        _buildMobileSection('Contact', [
          _buildField('Phone', lead.phone),
          _buildField('Email', lead.email),
          _buildField('Website', lead.website),
        ]),
        const SizedBox(height: 12),
        
        // Reviews & Social
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMobileSection('Reviews', [
                _buildField('Rating', lead.ratings),
                _buildField('Reviews', lead.reviews),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lead.socialMedias.isEmpty ? 'Not Found' : lead.socialMedias.values.first,
                    style: const TextStyle(fontSize: 11, color: AppColors.mediumGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Action
        Row(
          children: [
            const Text(
              'Status: ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Expanded(child: _buildStatusDropdown(lead)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ...fields,
      ],
    );
  }

  Widget _buildDataGrid(LeadModel lead) {
    final allFields = <String, dynamic>{
      'Category': lead.categories,
      'Type': lead.extraFields['type'] ?? 'Not Found',
      'Address': lead.address,
      'Latitude': lead.latitude?.toString() ?? 'Not Found',
      'Longitude': lead.longitude?.toString() ?? 'Not Found',
    };

    // Add extra fields
    lead.extraFields.forEach((key, value) {
      if (key != 'type') {
        allFields[key] = value;
      }
    });

    return Column(
      children: [
        // Main sections row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...allFields.entries.map((e) => _buildField(e.key, e.value.toString())),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // BingMap Reviews section
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BingMap Reviews',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildField('Ratings', lead.ratings),
                  _buildField('Total review', lead.reviews),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Website section
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Website',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lead.website,
                    style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Contact Info section
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Info',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildField('Phone', lead.phone),
                  _buildField('Email', lead.email),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Social Media section
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social Media',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lead.socialMedias.isEmpty ? 'Not Found' : lead.socialMedias.values.first,
                    style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Action section
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Action',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusDropdown(lead),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(LeadModel lead) {
    return PopupMenuButton<LeadStatus>(
      initialValue: lead.status,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(lead.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _getStatusColor(lead.status)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _getStatusLabel(lead.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(lead.status),
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => LeadStatus.values.map((status) {
        return PopupMenuItem(
          value: status,
          child: Text(_getStatusLabel(status)),
        );
      }).toList(),
      onSelected: (status) {
        context.read<LeadsProvider>().updateLeadStatus(lead.id, status);
      },
    );
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.unreached:
        return 'Unreached';
      case LeadStatus.followUp:
        return 'Follow Up';
      case LeadStatus.noResponse:
        return 'No Response';
      case LeadStatus.accepted:
        return 'Accepted';
      case LeadStatus.rejected:
        return 'Rejected';
    }
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.unreached:
        return AppColors.mediumGrey;
      case LeadStatus.followUp:
        return AppColors.warningOrange;
      case LeadStatus.noResponse:
        return AppColors.errorRed;
      case LeadStatus.accepted:
        return AppColors.successGreen;
      case LeadStatus.rejected:
        return AppColors.errorRed;
    }
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final isMobile = Responsive.isMobile(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: isMobile ? 20 : 24),
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
        ),
        ...List.generate(
          _totalPages > 5 ? 5 : _totalPages,
          (index) {
            final page = index + 1;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
              child: InkWell(
                onTap: () => setState(() => _currentPage = page),
                child: Container(
                  width: isMobile ? 28 : 32,
                  height: isMobile ? 28 : 32,
                  decoration: BoxDecoration(
                    color: _currentPage == page
                        ? AppColors.primaryPurple
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _currentPage == page
                          ? AppColors.primaryPurple
                          : AppColors.borderGrey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      page.toString(),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: _currentPage == page
                            ? AppColors.pureWhite
                            : AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: isMobile ? 20 : 24),
          onPressed: _currentPage < _totalPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }
}

// Filter Dialog
class _FilterDialog extends StatefulWidget {
  final bool filterSocialMedia;
  final bool filterWebsite;
  final bool filterPhoneNumber;
  final bool filterEmails;
  final bool filterReview;
  final bool filterRatings;
  final Function(bool, bool, bool, bool, bool, bool) onApply;
  final VoidCallback onReset;

  const _FilterDialog({
    required this.filterSocialMedia,
    required this.filterWebsite,
    required this.filterPhoneNumber,
    required this.filterEmails,
    required this.filterReview,
    required this.filterRatings,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late bool _socialMedia;
  late bool _website;
  late bool _phoneNumber;
  late bool _emails;
  late bool _review;
  late bool _ratings;

  @override
  void initState() {
    super.initState();
    _socialMedia = widget.filterSocialMedia;
    _website = widget.filterWebsite;
    _phoneNumber = widget.filterPhoneNumber;
    _emails = widget.filterEmails;
    _review = widget.filterReview;
    _ratings = widget.filterRatings;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildToggleRow('Social Media', _socialMedia, (v) => setState(() => _socialMedia = v)),
            _buildToggleRow('Website', _website, (v) => setState(() => _website = v)),
            _buildToggleRow('Phone Number', _phoneNumber, (v) => setState(() => _phoneNumber = v)),
            _buildToggleRow('Emails', _emails, (v) => setState(() => _emails = v)),
            _buildToggleRow('Review', _review, (v) => setState(() => _review = v)),
            _buildToggleRow('Ratings', _ratings, (v) => setState(() => _ratings = v)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_socialMedia, _website, _phoneNumber, _emails, _review, _ratings);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}
