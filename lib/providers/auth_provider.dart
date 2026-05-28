import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Auth state provider
/// Manages authentication state and notifies listeners of changes
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailVerified = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _isEmailVerified;

  // Constructor - initialize and listen to auth state
  AuthProvider() {
    _initializeAuthState();
  }

  /// Initialize auth state listener
  void _initializeAuthState() {
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _isEmailVerified = user.emailVerified;
      } else {
        _isEmailVerified = false;
      }
      _errorMessage = null;
      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email, password and username
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    _setLoading(true);
    try {
      final isVerified = await _authService.checkEmailVerified();
      _isEmailVerified = isVerified;
      _errorMessage = null;
      notifyListeners();
      return isVerified;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    _setLoading(true);
    try {
      await _authService.sendEmailVerification();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _isEmailVerified = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
