import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _user;
  bool _loading = false;
  String? _error;
  String? _rememberedEmail;

  AuthProvider() {
    _user = _firebaseAuth.currentUser;

    _firebaseAuth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });

    _loadRememberedEmail();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;

  bool get loading => _loading;

  String? get error => _error;

  String get userId => _user?.uid ?? '';

  String? get userEmail => _user?.email;

  String? get userName => _user?.displayName;

  String? get rememberedEmail => _rememberedEmail;

  bool get isLoggedIn => _user != null;

  // ============================================================
  // LOAD REMEMBERED EMAIL
  // ============================================================

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _rememberedEmail = prefs.getString('remembered_email');

      notifyListeners();
    } catch (e) {
      _rememberedEmail = null;
    }
  }

  // ============================================================
  // SAVE REMEMBERED EMAIL
  // ============================================================

  Future<void> _rememberEmail(String email) async {
    try {
      final cleanedEmail = email.trim();

      if (cleanedEmail.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('remembered_email', cleanedEmail);

      _rememberedEmail = cleanedEmail;

      notifyListeners();
    } catch (e) {
      _rememberedEmail = email.trim();
    }
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<void> signUp(String email, String password, {String? name}) async {
    _setLoading(true);
    _clearError();

    try {
      final cleanedEmail = email.trim();

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanedEmail,
        password: password,
      );

      final user = credential.user;

      if (user != null && name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());

        await user.reload();

        _user = _firebaseAuth.currentUser;
      }

      await _rememberEmail(cleanedEmail);
    } on FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final cleanedEmail = email.trim();

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanedEmail,
        password: password,
      );

      _user = credential.user;

      await _rememberEmail(cleanedEmail);
    } on FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final cleanedEmail = email.trim();

      await _firebaseAuth.sendPasswordResetEmail(email: cleanedEmail);

      await _rememberEmail(cleanedEmail);
    } on FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
    } catch (e) {
      _error = 'Unable to send password reset email.';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseAuth.signOut();

      _user = null;

      // Remembered email is intentionally kept.
    } on FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
    } catch (e) {
      _error = 'Unable to sign out. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account exists with this email. Please sign up first.';

      case 'wrong-password':
        return 'Incorrect email or password.';

      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email. Please login.';

      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled in Firebase.';

      case 'requires-recent-login':
        return 'Please login again to perform this action.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
