import 'package:firebase_auth/firebase_auth.dart';

/// Centralized authentication service
/// Handles all Firebase Auth operations with proper error handling
class AuthService {
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Check if user's email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Sign in with email and password
  /// Throws custom exceptions with user-friendly messages
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign in failed: ${e.toString()}';
    }
  }

  /// Create user with email and password
  /// Returns credential after account creation
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Set display name
      await credential.user?.updateDisplayName(username.trim());

      // Send email verification
      await credential.user?.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign up failed: ${e.toString()}';
    }
  }

  /// Send email verification link
  /// Should be called after signup
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send verification email: ${e.toString()}';
    }
  }

  /// Check if email is verified
  /// Reloads user data from Firebase
  Future<bool> checkEmailVerified() async {
    try {
      await currentUser?.reload();
      return currentUser?.emailVerified ?? false;
    } catch (e) {
      throw 'Failed to check email verification: ${e.toString()}';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email: ${e.toString()}';
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Sign out failed: ${e.toString()}';
    }
  }

  /// Delete current user account
  /// User must have signed in recently
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account: ${e.toString()}';
    }
  }

  /// Reload user data from Firebase
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw 'Failed to reload user data: ${e.toString()}';
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with that email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'requires-recent-login':
        return 'Please sign in again before performing this action.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
