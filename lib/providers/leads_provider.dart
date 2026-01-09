import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/lead_file_model.dart';
import '../models/lead_model.dart';
import '../models/user_model.dart';
import '../services/csv_service.dart';
import '../services/firestore_service.dart';

/// Provider for managing leads data with real-time Firestore updates
class LeadsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _currentUserId;
  
  // Real-time data from Firestore
  List<LeadFileModel> _leadFiles = [];
  List<LeadFileModel> _recentLeadFiles = [];
  UserStats _userStats = UserStats();
  
  // Loading states
  bool _isUploading = false;
  bool _isLoadingLeadFiles = true;
  bool _isLoadingUserStats = true;
  String? _error;

  // Selected file for detail view
  LeadFileModel? _selectedFile;
  List<LeadModel> _selectedFileLeads = [];
  bool _isLoadingLeads = false;

  // Stream subscriptions
  StreamSubscription<List<LeadFileModel>>? _leadFilesSubscription;
  StreamSubscription<List<LeadFileModel>>? _recentLeadFilesSubscription;
  StreamSubscription<UserModel?>? _userStatsSubscription;

  // Getters
  List<LeadFileModel> get leadFiles => _leadFiles;
  List<LeadFileModel> get recentLeadFiles => _recentLeadFiles;
  UserStats get userStats => _userStats;
  bool get isUploading => _isUploading;
  bool get isLoadingLeadFiles => _isLoadingLeadFiles;
  bool get isLoadingUserStats => _isLoadingUserStats;
  bool get isLoadingLeads => _isLoadingLeads;
  String? get error => _error;
  LeadFileModel? get selectedFile => _selectedFile;
  List<LeadModel> get selectedFileLeads => _selectedFileLeads;

  /// Initialize provider with user ID and start real-time listeners
  void initialize(String userId) {
    if (_currentUserId == userId) return; // Already initialized
    
    _currentUserId = userId;
    _startListeners();
  }

  /// Start all real-time Firestore listeners
  void _startListeners() {
    if (_currentUserId == null) return;

    // Listen to all lead files
    _leadFilesSubscription?.cancel();
    _leadFilesSubscription = _firestoreService
        .streamLeadFiles(_currentUserId!)
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
        .streamRecentLeadFiles(_currentUserId!, limit: 5)
        .listen(
          (files) {
            _recentLeadFiles = files;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error streaming recent lead files: $error');
          },
        );

    // Listen to user stats
    _userStatsSubscription?.cancel();
    _userStatsSubscription = _firestoreService
        .streamUser(_currentUserId!)
        .listen(
          (user) {
            if (user != null) {
              _userStats = user.totalStats;
              _isLoadingUserStats = false;
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('Error streaming user stats: $error');
            _isLoadingUserStats = false;
            notifyListeners();
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
    if (_currentUserId == null) {
      _error = 'User not authenticated';
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

      // Create lead file model
      final leadFile = LeadFileModel(
        id: '', // Will be set by Firestore
        userId: _currentUserId!,
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

      // Update user stats
      await _updateUserStatsAfterUpload(leads.length);

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

  /// Update user stats after upload
  Future<void> _updateUserStatsAfterUpload(int newLeadsCount) async {
    if (_currentUserId == null) return;

    try {
      final newStats = UserStats(
        totalLeads: _userStats.totalLeads + newLeadsCount,
        unreached: _userStats.unreached + newLeadsCount,
        selected: _userStats.selected,
        followUps: _userStats.followUps,
        noResponse: _userStats.noResponse,
        accepted: _userStats.accepted,
        rejected: _userStats.rejected,
        
      );

      await _firestoreService.updateUserStats(_currentUserId!, newStats);
      debugPrint('Updated user stats: total=${newStats.totalLeads}');
    } catch (e) {
      debugPrint('Error updating user stats: $e');
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
      
      // Update file and user stats
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
    if (_currentUserId == null || _selectedFile == null) return;

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

      // Recalculate user stats by counting all leads from all files
      await _recalculateAndUpdateUserStats();
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

  /// Recalculate user stats from all lead files
  Future<void> _recalculateAndUpdateUserStats() async {
    if (_currentUserId == null) return;

    try {
      // Get all lead files
      final allFiles = await _firestoreService.getLeadFiles(_currentUserId!);
      
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

      final newUserStats = UserStats(
        totalLeads: totalLeads,
        unreached: unreached,
        selected: selected,
        followUps: followUps,
        noResponse: noResponse,
        accepted: accepted,
        rejected: rejected,
      );

      await _firestoreService.updateUserStats(_currentUserId!, newUserStats);
      debugPrint('Recalculated user stats: total=$totalLeads, unreached=$unreached, followUps=$followUps, accepted=$accepted, selected=$selected');
    } catch (e) {
      debugPrint('Error recalculating user stats: $e');
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
    _userStatsSubscription?.cancel();
    _currentUserId = null;
    super.dispose();
  }
}
