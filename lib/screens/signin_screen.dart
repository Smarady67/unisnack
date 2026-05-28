import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_background.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign in failed. Please try again.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Sign in',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 36),
          _buildInputField(
            label: 'Email Address',
            controller: _emailController,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Password',
            controller: _passwordController,
            isObscure: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02B4D8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isLoading ? 'Signing in...' : 'Sign in',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                child: const Text(
                  'Sign up',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
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
