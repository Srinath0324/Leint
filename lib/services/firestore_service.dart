import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lead_file_model.dart';
import '../models/lead_model.dart';
import '../models/user_model.dart';

/// Service for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _leadFilesCollection => _firestore.collection('lead_files');

  // ============ USER OPERATIONS ============

  /// Create or update user document
  Future<void> saveUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }

  /// Stream user data for real-time updates
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    });
  }

  /// Update user stats
  Future<void> updateUserStats(String uid, UserStats stats) async {
    await _usersCollection.doc(uid).update({
      'totalStats': stats.toMap(),
    });
  }

  // ============ LEAD FILE OPERATIONS ============

  /// Create a new lead file
  Future<String> createLeadFile(LeadFileModel leadFile) async {
    final docRef = await _leadFilesCollection.add(leadFile.toMap());
    return docRef.id;
  }

  /// Get all lead files for a user
  Future<List<LeadFileModel>> getLeadFiles(String userId) async {
    final snapshot = await _leadFilesCollection
        .where('userId', isEqualTo: userId)
        .get();

    final files = snapshot.docs
        .map((doc) => LeadFileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    
    // Sort by uploadDate in memory
    files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    
    return files;
  }

  /// Stream lead files for real-time updates
  /// Note: This uses client-side sorting to avoid needing Firestore composite indexes
  Stream<List<LeadFileModel>> streamLeadFiles(String userId) {
    return _leadFilesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final files = snapshot.docs
              .map((doc) => LeadFileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          
          // Sort by uploadDate in memory (descending)
          files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
          
          return files;
        });
  }

  /// Get recent lead files (limited)
  /// Note: This uses client-side sorting and limiting to avoid needing Firestore composite indexes
  Stream<List<LeadFileModel>> streamRecentLeadFiles(String userId, {int limit = 5}) {
    return _leadFilesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final files = snapshot.docs
              .map((doc) => LeadFileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          
          // Sort by uploadDate in memory (descending)
          files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
          
          // Take only the first 'limit' items
          return files.take(limit).toList();
        });
  }

  /// Update lead file stats
  Future<void> updateLeadFileStats(String fileId, {
    int? unreached,
    int? followUps,
    int? noResponse,
    int? accepted,
    int? rejected,
  }) async {
    final updates = <String, dynamic>{};
    if (unreached != null) updates['unreached'] = unreached;
    if (followUps != null) updates['followUps'] = followUps;
    if (noResponse != null) updates['noResponse'] = noResponse;
    if (accepted != null) updates['accepted'] = accepted;
    if (rejected != null) updates['rejected'] = rejected;

    if (updates.isNotEmpty) {
      await _leadFilesCollection.doc(fileId).update(updates);
    }
  }

  // ============ LEAD OPERATIONS ============

  /// Add leads to a lead file
  Future<void> addLeads(String fileId, List<LeadModel> leads) async {
    final batch = _firestore.batch();
    final leadsCollection = _leadFilesCollection.doc(fileId).collection('leads');

    for (final lead in leads) {
      final docRef = leadsCollection.doc();
      batch.set(docRef, lead.toMap());
    }

    await batch.commit();
  }

  /// Get leads for a file
  Future<List<LeadModel>> getLeads(String fileId) async {
    final snapshot = await _leadFilesCollection
        .doc(fileId)
        .collection('leads')
        .get();

    return snapshot.docs
        .map((doc) => LeadModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream leads for a file
  Stream<List<LeadModel>> streamLeads(String fileId) {
    return _leadFilesCollection
        .doc(fileId)
        .collection('leads')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeadModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update lead status
  Future<void> updateLeadStatus(String fileId, String leadId, LeadStatus status) async {
    await _leadFilesCollection
        .doc(fileId)
        .collection('leads')
        .doc(leadId)
        .update({'status': status.toFirestore()});
  }

  /// Delete a lead file and all its leads
  Future<void> deleteLeadFile(String fileId) async {
    // Delete all leads first
    final leadsSnapshot = await _leadFilesCollection
        .doc(fileId)
        .collection('leads')
        .get();

    final batch = _firestore.batch();
    for (final doc in leadsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_leadFilesCollection.doc(fileId));

    await batch.commit();
  }
}
