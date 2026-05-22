import 'package:flutter/material.dart';
import 'auth_background.dart';
import 'verify_identity_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
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
              onPressed: () {
                // Navigate forward into your 6-digit verification code check screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerifyIdentityScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02B4D8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sign up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                onTap: () => Navigator.maybePop(context),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
