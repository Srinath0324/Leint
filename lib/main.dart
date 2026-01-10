import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/leads_provider.dart';
import 'providers/workspace_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await _initializeFirebase();
  
  runApp(const LeintApp());
}

/// Initialize Firebase with appropriate options based on platform
Future<void> _initializeFirebase() async {
  if (kIsWeb) {
    // Web configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBKzp6b4MVgF-oWmw9KCQqh4fOCLmU2Z2A",
        authDomain: "leint-89ed4.firebaseapp.com",
        projectId: "leint-89ed4",
        storageBucket: "leint-89ed4.firebasestorage.app",
        messagingSenderId: "208495181492",
        appId: "1:208495181492:web:132a209d212c85ef12a1e1",
        measurementId: "G-G563X5KYZS",
      ),
    );
  } else {
    // Android/iOS - uses google-services.json / GoogleService-Info.plist
    // Firebase will auto-configure from native files
    await Firebase.initializeApp();
  }
}

class LeintApp extends StatelessWidget {
  const LeintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
      ],
      child: MaterialApp(
        title: 'Leint - Leads Interpreter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper widget that handles auth state and navigation
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WorkspaceProvider>(
      builder: (context, authProvider, workspaceProvider, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Navigate based on auth state
        if (authProvider.isAuthenticated) {
          final userId = authProvider.currentUser!.uid;
          
          // Initialize providers once
          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final leadsProvider = context.read<LeadsProvider>();
              
              // Initialize workspace provider
              workspaceProvider.initialize(userId);
              
              // Wait for workspace to be set, then initialize leads
              if (workspaceProvider.currentWorkspaceId != null) {
                leadsProvider.initialize(userId, workspaceId: workspaceProvider.currentWorkspaceId);
              }
              
              setState(() => _isInitialized = true);
            });
          }
          
          // Update leads when workspace changes
          if (_isInitialized && workspaceProvider.currentWorkspaceId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<LeadsProvider>().setWorkspace(workspaceProvider.currentWorkspaceId!);
            });
          }
          
          return const DashboardScreen();
        } else {
          // Reset initialization when logged out
          if (_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isInitialized = false);
              }
            });
          }
          return const LoginScreen();
        }
      },
    );
  }
}
