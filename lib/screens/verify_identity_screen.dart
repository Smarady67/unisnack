import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_background.dart';
import 'signin_screen.dart';

class VerifyIdentityScreen extends StatefulWidget {
  final String email;

  const VerifyIdentityScreen({super.key, required this.email});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
  }

  Future<void> _checkVerification(AuthProvider authProvider) async {
    final isVerified = await authProvider.checkEmailVerification();

    if (!mounted) return;

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! You can now sign in.'),
          backgroundColor: Color(0xFF02B4D8),
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate to sign in
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet. Please check your inbox and click the link.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resendVerification(AuthProvider authProvider) async {
    final success = await authProvider.resendEmailVerification();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email resent to ${widget.email}'),
          backgroundColor: const Color(0xFF02B4D8),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ??
              'Could not resend email. Please try again.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF02B4D8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Identity',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'A verification link was sent to',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF02B4D8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Click the link in your email to verify your\naccount, then press "Done" below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the email? ",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  GestureDetector(
                    onTap: authProvider.isLoading
                        ? null
                        : () => _resendVerification(authProvider),
                    child: Text(
                      authProvider.isLoading ? 'Sending...' : 'Resend',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF02B4D8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 140,
                height: 44,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _checkVerification(authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02B4D8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    authProvider.isLoading ? 'Checking...' : 'Done',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
