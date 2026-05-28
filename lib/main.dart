import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/onboarding_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize onboarding service
  await OnboardingService().initialize();

  // Makes the status bar clean and transparent to match your exact mockup designs
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.dark, // Dark status bar icons on white BG
    ),
  );

  runApp(const UniSnackApp());
}

class UniSnackApp extends StatelessWidget {
  const UniSnackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'UniSnack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Set the primary seed color to your exact brand cyan
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D1B2),
            primary: const Color(0xFF00D1B2),
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
