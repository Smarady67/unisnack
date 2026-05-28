import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  /// Navigate based on auth state
  /// Uses Provider to listen to auth changes instead of hardcoded delay
  void _navigate() {
    // Check auth state using Provider
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      final hasSeenOnboarding = OnboardingService().hasSeenOnboarding;

      // If authenticated and email is verified, go to home
      if (authProvider.isAuthenticated && authProvider.isEmailVerified) {
        _goToHome();
      }
      // If authenticated but email NOT verified, sign out (security measure)
      else if (authProvider.isAuthenticated && !authProvider.isEmailVerified) {
        authProvider.signOut().then((_) {
          if (mounted) _goToOnboarding();
        });
      }
      // Not authenticated: show onboarding if not seen, else sign in
      else {
        if (hasSeenOnboarding) {
          _goToSignIn();
        } else {
          _goToOnboarding();
        }
      }
    });
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  void _goToSignIn() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo with a smooth border radius
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/images/unisnack_logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            // App Brand Name
            const Text(
              'UniSnack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005691),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            // The small teal accent line underneath the logo name
            Container(
              width: 45,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF02B4D8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
