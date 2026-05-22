import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBackPress;

  const AuthBackground({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.onBackPress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Elements: Top Right Big Circle
          const Positioned(
            top: -40,
            right: -50,
            child: CircleAvatar(radius: 90, backgroundColor: Color(0xFF02B4D8)),
          ),
          // Top Left Floating Circles
          // Top Left Floating Circles
          Positioned(
            top: 140,
            left: -20,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF02B4D8).withOpacity(0.85),
            ),
          ),
          Positioned(
            top: 155,
            left: 50,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFF02B4D8).withOpacity(0.9),
            ),
          ),
          // Middle Right Floating Circle
          Positioned(
            top: 240,
            right: 40,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF02B4D8).withOpacity(0.9),
            ),
          ),

          // Custom Capsule Back Button
          // Custom Capsule Back Button
          if (showBackButton)
            Positioned(
              top: 50,
              left: 20,
              child: InkWell(
                onTap: onBackPress ?? () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEAEAEAFF).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 14, color: Colors.black54),
                      SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main Screen Content Box
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Perfectly Centered Rounded App Logo
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/unisnack_logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
