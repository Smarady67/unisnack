import 'package:flutter/material.dart';
import 'signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboardingONE.png',
      'title': 'Get your snack!',
      'subtitle':
          'Buy, sell, and enjoy tasty campus\nsnacks anytime, anywhere.',
    },
    {
      'image': 'assets/images/onboardingTWO.png',
      'title': 'Your campus food\nmarketplace!',
      'subtitle': '',
    },
    {
      'image': 'assets/images/onboardingTHREE.png',
      'title': 'Post. Sell. Enjoy.',
      'subtitle': 'Get snacks quickly and enjoy',
    },
  ];

  void _goToSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Slider Content Panel
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.42,
                          width: double.infinity,
                          child: Image.asset(
                            page['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          page['title']!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (page['subtitle']!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            page['subtitle']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots (Using your new hex color for the active dot)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? const Color(0xFF02B4D8) // Updated Active Cyan
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Bottom Buttons Bar Container
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 'Skip' Button
                  SizedBox(
                    width: 105,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _goToSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 'Next' Button
                  SizedBox(
                    width: 105,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _goToSignIn();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF02B4D8,
                        ), // Exact matching hex color 02B4D8
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
