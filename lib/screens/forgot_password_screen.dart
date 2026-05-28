import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _sendResetEmail(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    final success = await authProvider.sendPasswordResetEmail(email: email);

    if (!mounted) return;

    if (success) {
      _showMessage('Password reset link sent! Check your inbox.');
      // Auto-navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showMessage(
        authProvider.errorMessage ?? 'Something went wrong. Please try again.',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF02B4D8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 44),
            const Text(
              'Forgot Password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'No worries! we\'ll send you a\nlink to reset it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 6),
                  child: Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF02B4D8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14),
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return SizedBox(
                  width: 150,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _sendResetEmail(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02B4D8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      authProvider.isLoading ? 'Sending...' : 'Send Link',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
