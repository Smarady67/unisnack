import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state
/// Tracks whether user has seen onboarding screen
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  static const String _key = 'has_seen_onboarding';

  late SharedPreferences _prefs;

  factory OnboardingService() {
    return _instance;
  }

  OnboardingService._internal();

  /// Initialize the service (call once at app startup)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if user has seen onboarding
  bool get hasSeenOnboarding => _prefs.getBool(_key) ?? false;

  /// Mark onboarding as seen
  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(_key, true);
  }

  /// Reset onboarding state (for testing or when user explicitly wants to see it again)
  Future<void> resetOnboarding() async {
    await _prefs.remove(_key);
  }
}
