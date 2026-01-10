import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/lead_file_model.dart';
import '../models/lead_model.dart';
import '../models/workspace_model.dart';
import '../services/csv_service.dart';
import '../services/firestore_service.dart';

/// Provider for managing leads data with real-time Firestore updates
class LeadsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _currentUserId;
  String? _currentWorkspaceId;
  
  // Real-time data from Firestore
  List<LeadFileModel> _leadFiles = [];
  List<LeadFileModel> _recentLeadFiles = [];
  
  // Loading states
  bool _isUploading = false;
  bool _isLoadingLeadFiles = true;
  String? _error;

  // Selected file for detail view
  LeadFileModel? _selectedFile;
  List<LeadModel> _selectedFileLeads = [];
  bool _isLoadingLeads = false;

  // Stream subscriptions
  StreamSubscription<List<LeadFileModel>>? _leadFilesSubscription;
  StreamSubscription<List<LeadFileModel>>? _recentLeadFilesSubscription;

  // Getters
  List<LeadFileModel> get leadFiles => _leadFiles;
  List<LeadFileModel> get recentLeadFiles => _recentLeadFiles;
  bool get isUploading => _isUploading;
  bool get isLoadingLeadFiles => _isLoadingLeadFiles;
  bool get isLoadingLeads => _isLoadingLeads;
  String? get error => _error;
  LeadFileModel? get selectedFile => _selectedFile;
  List<LeadModel> get selectedFileLeads => _selectedFileLeads;

  /// Initialize provider with user ID and start real-time listeners
  void initialize(String userId, {String? workspaceId}) {
    if (_currentUserId == userId && _currentWorkspaceId == workspaceId) return; // Already initialized
    
    _currentUserId = userId;
    _currentWorkspaceId = workspaceId;
    _startListeners();
  }

  /// Update workspace and restart listeners
  void setWorkspace(String workspaceId) {
    if (_currentWorkspaceId == workspaceId) return;
    
    _currentWorkspaceId = workspaceId;
    _startListeners();
  }

  /// Start all real-time Firestore listeners
  void _startListeners() {
    if (_currentUserId == null || _currentWorkspaceId == null) return;

    // Listen to all lead files for current workspace
    _leadFilesSubscription?.cancel();
    _leadFilesSubscription = _firestoreService
        .streamLeadFiles(_currentWorkspaceId!, isWorkspace: true)
        .listen(
          (files) {
            _leadFiles = files;
            _isLoadingLeadFiles = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error streaming lead files: $error');
            _error = 'Failed to load lead files';
            _isLoadingLeadFiles = false;
            notifyListeners();
          },
        );

    // Listen to recent lead files (last 5)
    _recentLeadFilesSubscription?.cancel();
    _recentLeadFilesSubscription = _firestoreService
        .streamRecentLeadFiles(_currentWorkspaceId!, limit: 5, isWorkspace: true)
        .listen(
          (files) {
            _recentLeadFiles = files;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error streaming recent lead files: $error');
          },
        );
  }

  /// Pick a CSV file
  Future<PlatformFile?> pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      _error = 'Failed to pick file: $e';
      debugPrint(_error);
      notifyListeners();
      return null;
    }
  }

  /// Upload CSV file with title and source
  Future<bool> uploadCsvFile({
    required PlatformFile file,
    required String title,
    required String source,
  }) async {
    if (_currentUserId == null || _currentWorkspaceId == null) {
      _error = 'User not authenticated or no workspace selected';
      notifyListeners();
      return false;
    }

    try {
      _isUploading = true;
      _error = null;
      notifyListeners();

      // Read file content
      String csvContent;
      if (file.bytes != null) {
        csvContent = String.fromCharCodes(file.bytes!);
      } else {
        _error = 'Failed to read file content';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // Parse CSV with duplicate detection
      final leads = CsvService.parseCsv(csvContent);
      
      if (leads.isEmpty) {
        _error = 'No valid leads found in CSV';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // Create lead file model with correct workspaceId
      final leadFile = LeadFileModel(
        id: '', // Will be set by Firestore
        userId: _currentUserId!,
        workspaceId: _currentWorkspaceId!, // Use current workspace
        createdBy: _currentUserId!,
        title: title,
        source: source,
        totalLeads: leads.length,
        unreached: leads.length, // All start as unreached
        followUps: 0,
        noResponse: 0,
        accepted: 0,
        rejected: 0,
        uploadDate: DateTime.now(),
      );

      // Save to Firestore - this will trigger real-time listeners
      final fileId = await _firestoreService.createLeadFile(leadFile);
      debugPrint('Created lead file with ID: $fileId');
      
      // Add leads to subcollection
      await _firestoreService.addLeads(fileId, leads);
      debugPrint('Added ${leads.length} leads to file $fileId');

      // Update workspace stats
      await _updateWorkspaceStatsAfterUpload(leads.length);

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to upload: $e';
      debugPrint(_error);
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update workspace stats after upload
  Future<void> _updateWorkspaceStatsAfterUpload(int newLeadsCount) async {
    if (_currentWorkspaceId == null) return;

    try {
      // Recalculate workspace stats from all lead files
      await _recalculateAndUpdateWorkspaceStats();
    } catch (e) {
      debugPrint('Error updating workspace stats: $e');
    }
  }

  /// Select a lead file for detail view
  Future<void> selectLeadFile(LeadFileModel file) async {
    _selectedFile = file;
    _isLoadingLeads = true;
    notifyListeners();

    try {
      _selectedFileLeads = await _firestoreService.getLeads(file.id);
      debugPrint('Loaded ${_selectedFileLeads.length} leads for file ${file.id}');
    } catch (e) {
      _error = 'Failed to load leads: $e';
      debugPrint(_error);
    }

    _isLoadingLeads = false;
    notifyListeners();
  }

  /// Update lead status
  Future<void> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    if (_selectedFile == null) return;

    try {
      // Find the lead
      final index = _selectedFileLeads.indexWhere((l) => l.id == leadId);
      if (index == -1) return;

      final oldStatus = _selectedFileLeads[index].status;
      
      // Update in Firestore
      await _firestoreService.updateLeadStatus(_selectedFile!.id, leadId, newStatus);
      
      // Update local list
      _selectedFileLeads[index] = _selectedFileLeads[index].copyWith(status: newStatus);
      
      // Update file and workspace stats
      await _updateStatsForStatusChange(oldStatus, newStatus);
      
      notifyListeners();
      debugPrint('Updated lead $leadId status from $oldStatus to $newStatus');
    } catch (e) {
      _error = 'Failed to update status: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Update stats when status changes
  Future<void> _updateStatsForStatusChange(LeadStatus oldStatus, LeadStatus newStatus) async {
    if (_currentWorkspaceId == null || _selectedFile == null) return;

    try {
      // Recalculate file stats by counting actual lead statuses
      final stats = _calculateFileStats(_selectedFileLeads);
      
      // Update file stats in Firestore
      await _firestoreService.updateLeadFileStats(
        _selectedFile!.id,
        unreached: stats['unreached']!,
        selected: stats['selected']!,
        followUps: stats['followUps']!,
        noResponse: stats['noResponse']!,
        accepted: stats['accepted']!,
        rejected: stats['rejected']!,
      );

      // Recalculate workspace stats by counting all leads from all files
      await _recalculateAndUpdateWorkspaceStats();
    } catch (e) {
      debugPrint('Error updating stats: $e');
    }
  }

  /// Calculate file stats by counting lead statuses
  Map<String, int> _calculateFileStats(List<LeadModel> leads) {
    final stats = {
      'unreached': 0,
      'selected': 0,
      'followUps': 0,
      'noResponse': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (final lead in leads) {
      switch (lead.status) {
        case LeadStatus.unreached:
          stats['unreached'] = stats['unreached']! + 1;
          break;
        case LeadStatus.selected:
          stats['selected'] = stats['selected']! + 1;
          break;
        case LeadStatus.followUp:
          stats['followUps'] = stats['followUps']! + 1;
          break;
        case LeadStatus.noResponse:
          stats['noResponse'] = stats['noResponse']! + 1;
          break;
        case LeadStatus.accepted:
          stats['accepted'] = stats['accepted']! + 1;
          break;
        case LeadStatus.rejected:
          stats['rejected'] = stats['rejected']! + 1;
          break;
      }
    }

    return stats;
  }

  /// Recalculate workspace stats from all lead files
  Future<void> _recalculateAndUpdateWorkspaceStats() async {
    if (_currentWorkspaceId == null) return;

    try {
      // Get all lead files for this workspace
      final allFiles = await _firestoreService.getLeadFiles(_currentWorkspaceId!, isWorkspace: true);
      
      int totalLeads = 0;
      int selected = 0;
      int unreached = 0;
      int followUps = 0;
      int noResponse = 0;
      int accepted = 0;
      int rejected = 0;

      // Sum up stats from all files
      for (final file in allFiles) {
        totalLeads += file.totalLeads;
        unreached += file.unreached;
        selected += file.selected;
        followUps += file.followUps;
        noResponse += file.noResponse;
        accepted += file.accepted;
        rejected += file.rejected;
      }

      final newWorkspaceStats = {
        'totalLeads': totalLeads,
        'unreached': unreached,
        'selected': selected,
        'followUps': followUps,
        'noResponse': noResponse,
        'accepted': accepted,
        'rejected': rejected,
      };

      await _firestoreService.updateWorkspaceStats(_currentWorkspaceId!, newWorkspaceStats);
      debugPrint('Recalculated workspace stats: total=$totalLeads, unreached=$unreached, followUps=$followUps, accepted=$accepted, selected=$selected');
    } catch (e) {
      debugPrint('Error recalculating workspace stats: $e');
    }
  }

  /// Clear selected file
  void clearSelectedFile() {
    _selectedFile = null;
    _selectedFileLeads = [];
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _leadFilesSubscription?.cancel();
    _recentLeadFilesSubscription?.cancel();
    _currentUserId = null;
    _currentWorkspaceId = null;
    super.dispose();
  }
}
