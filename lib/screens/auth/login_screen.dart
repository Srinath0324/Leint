import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';

/// Login/Signup Screen with Google Sign-In
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softLavender,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const _LoginCard(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Image - UPDATED to use leint_logo.png
            Image.asset(
              'assets/leint_logo.png',
              width: 140,  // Increased from 80 to 120
              height: 140, // Increased from 80 to 120
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient container if image fails
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryPurpleLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    size: 60,
                    color: AppColors.pureWhite,
                  ),
                );
              },
            ),

            // App Name - UPDATED to "LeInt" with primary purple color
            RichText(
  text: TextSpan(
    style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
    children: [
      TextSpan(
        text: 'Le',
        style: TextStyle(
          color: AppColors.primaryPurple,
        ),
      ),
      TextSpan(
        text: 'Int',
        style: TextStyle(
          color: AppColors.infoBlue,
        ),
      ),
    ],
  ),
),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Leads Interpreter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize and manage your leads effortlessly',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightGrey,
                  ),
            ),
            const SizedBox(height: 40),

            // Google Sign In Button
            const _GoogleSignInButton(),

            const SizedBox(height: 24),

            // Terms text
            Text(
              'By signing in, you agree to our Terms of Service\nand Privacy Policy',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightGrey,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () async {
                    final success = await authProvider.signInWithGoogle();
                    if (!success && context.mounted) {
                      final error = authProvider.error;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sign in failed: $error'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                        authProvider.clearError();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pureWhite,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
              side: const BorderSide(
                color: AppColors.borderGrey,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.network(
                                          'https://www.google.com/favicon.ico',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.login),
                                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign in with Google',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkCharcoal,
                            ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
