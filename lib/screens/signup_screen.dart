import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_background.dart';
import 'verify_identity_screen.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user!.updateDisplayName(username);
      await credential.user!.sendEmailVerification();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyIdentityScreen(email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }
      if (mounted) _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'Sign up',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome to UniSnack!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          _buildInputField(label: 'Username', controller: _usernameController),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Email Address',
            controller: _emailController,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Password',
            controller: _passwordController,
            isObscure: true,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            isObscure: true,
            isRequired: true,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 140,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02B4D8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isLoading ? 'Creating...' : 'Sign up',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF02B4D8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isObscure = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF02B4D8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
