import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return MaterialApp(
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
    );
  }
}
