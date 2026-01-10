import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/workspace_service.dart';

/// Authentication provider for managing user auth state
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  late final GoogleSignIn _googleSignIn;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    // Configure GoogleSignIn based on platform
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    } else {
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    }
    _initializeAuth();
  }

  /// Initialize auth state on app start
  Future<void> _initializeAuth() async {
    try {
      // Check for existing auth session
      final user = _auth.currentUser;
      if (user != null) {
        await _setCurrentUser(user);
      }

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _setCurrentUser(user);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _setCurrentUser(userCredential.user!);
        
        // Create/update user document in Firestore
        await _createOrUpdateUserDocument(userCredential.user!);
        
        await _saveLoginState(true);
        return true;
      }

      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User firebaseUser) async {
    try {
      // Check if user document exists
      final existingUser = await _firestoreService.getUser(firebaseUser.uid);
      
      if (existingUser == null) {
        // NEW USER - Create workspace first
        final workspaceService = WorkspaceService();
        final workspaceId = await workspaceService.createWorkspace(
          name: 'My Workspace',
          ownerId: firebaseUser.uid,
        );
        
        // Create new user document with initial workspace
        final newUser = UserModel(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          currentWorkspaceId: workspaceId,
          workspaceIds: [workspaceId],
        );
        
        await _firestoreService.saveUser(newUser);
        debugPrint('Created new user document and default workspace for ${firebaseUser.uid}');
      } else {
        // Update existing user info (in case profile changed)
        final updatedUser = existingUser.copyWith(
          displayName: firebaseUser.displayName ?? existingUser.displayName,
          email: firebaseUser.email ?? existingUser.email,
          photoURL: firebaseUser.photoURL ?? existingUser.photoURL,
        );
        
        await _firestoreService.saveUser(updatedUser);
        debugPrint('Updated user document for ${firebaseUser.uid}');
      }
    } catch (e) {
      debugPrint('Error creating/updating user document: $e');
    }
  }

  /// Set current user from Firebase user
  Future<void> _setCurrentUser(User user) async {
    _currentUser = UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      photoURL: user.photoURL,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _googleSignIn.signOut();
      await _auth.signOut();
      await _saveLoginState(false);

      _currentUser = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Sign out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save login state to shared preferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
