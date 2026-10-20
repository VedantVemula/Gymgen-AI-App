import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Web OAuth client from android/app/google-services.json (client_type: 3).
// Google Sign-In on Android uses this as the server client ID to return an ID token.
const String _googleServerClientId =
    '408023399527-upr2ccihst7av1dnj754qhptee3crbdn.apps.googleusercontent.com';

class DemoUser {
  final String uid;
  final String email;
  final String name;

  const DemoUser({
    required this.uid,
    required this.email,
    required this.name,
  });
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    final currentUser = _firebaseAuth.currentUser;
    _user = currentUser?.emailVerified == true ? _mapUser(currentUser) : null;
    if (currentUser != null && !currentUser.emailVerified) {
      unawaited(_firebaseAuth.signOut());
    }
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      // Login/signup methods handle an unverified user while loading. For an
      // unverified session restored after app startup, sign out before it can
      // reach the authenticated screens.
      if (!_loading && user != null && !user.emailVerified) {
        _user = null;
        unawaited(_firebaseAuth.signOut());
      } else if (user == null || user.emailVerified) {
        _user = _mapUser(user);
      }
      notifyListeners();
    });
  }

  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSubscription;

  DemoUser? _user;
  bool _loading = false;
  String? _error;
  String? _lastSignInErrorCode;
  bool _forgotPasswordSent = false;
  bool _verificationEmailSent = false;
  bool _googleSignUpRequired = false;
  Future<void>? _googleSignInInitialization;

  DemoUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get forgotPasswordSent => _forgotPasswordSent;
  bool get verificationEmailSent => _verificationEmailSent;
  bool get googleSignUpRequired => _googleSignUpRequired;
  String? get lastSignInErrorCode => _lastSignInErrorCode;
  bool get shouldOfferSignUp =>
      _lastSignInErrorCode == 'user-not-found' ||
      _lastSignInErrorCode == 'invalid-credential';

  String get userId => _user?.uid ?? '';
  String get userEmail => _user?.email ?? '';
  String get userName => _user?.name ?? 'Athlete';

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;
    _lastSignInErrorCode = null;

    try {
      if (!_isValidGmail(email)) {
        _error = 'Please enter a valid Gmail address ending in @gmail.com.';
        return;
      }

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final signedInUser = credential.user;
      if (signedInUser != null && !signedInUser.emailVerified) {
        try {
          await signedInUser.sendEmailVerification();
        } catch (_) {
          // Sign-in remains blocked even if Firebase cannot resend the link.
        }
        await _firebaseAuth.signOut();
        _user = null;
        _lastSignInErrorCode = 'email-not-verified';
        _error = 'Verify your Gmail address using the link sent to your inbox, then log in again.';
        return;
      }

      _user = _mapUser(signedInUser);
    } on FirebaseAuthException catch (exception) {
      _lastSignInErrorCode = exception.code;
      _error = _firebaseErrorMessage(exception);
    } catch (_) {
      _error = 'Unable to sign in. Check your connection and try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with Google. Returns true when Firebase has just created a new
  /// account so the UI can ask the user to complete GymGen onboarding.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    _googleSignUpRequired = false;

    try {
      late final UserCredential credential;

      if (kIsWeb) {
        credential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } else {
        _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
          serverClientId: _googleServerClientId,
        );
        await _googleSignInInitialization;

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          _error = 'Google sign-in is not supported on this platform.';
          return false;
        }

        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        if (googleAuth.idToken == null) {
          _error = 'Google did not return an ID token. Check that the web OAuth client ID in Firebase matches the one configured for this Android app.';
          return false;
        }
        final oauthCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        credential = await _firebaseAuth.signInWithCredential(oauthCredential);
      }

      final signedInUser = credential.user;
      if (signedInUser == null || signedInUser.email == null) {
        await _firebaseAuth.signOut();
        _error = 'Google did not return an email address. Please try again.';
        return false;
      }

      if (!_isValidGmail(signedInUser.email!)) {
        if (credential.additionalUserInfo?.isNewUser == true) {
          await signedInUser.delete();
        }
        await _firebaseAuth.signOut();
        _user = null;
        _error = 'Please use a Google account with a Gmail address ending in @gmail.com.';
        return false;
      }

      // Google has verified the identity and email. Firebase reports whether
      // this provider created the Firebase Auth account in this operation.
      _googleSignUpRequired = credential.additionalUserInfo?.isNewUser ?? false;
      _user = _mapUser(signedInUser);
      return _googleSignUpRequired;
    } on FirebaseAuthException catch (exception) {
      _error = switch (exception.code) {
        'account-exists-with-different-credential' =>
          'An account already exists with this email. Sign in with its original method first.',
        'popup-closed-by-user' || 'web-context-cancelled' => null,
        'operation-not-allowed' =>
          'Google sign-in is not enabled in Firebase Authentication.',
        'network-request-failed' =>
          'Network error. Check your internet connection and try again.',
        _ => exception.message ?? 'Google sign-in failed. Please try again.',
      };
      return false;
    } on GoogleSignInException catch (exception) {
      final details = exception.description;
      if (exception.code == GoogleSignInExceptionCode.canceled) {
        _error = 'Google sign-in did not complete. If this appeared after choosing an account, verify the Android package name and SHA-1/SHA-256 fingerprints in Firebase, then download the latest google-services.json. ${details ?? ''}'.trim();
      } else {
        _error = 'Google sign-in failed (${exception.code.name}). ${details ?? 'Check your Firebase Google sign-in configuration and try again.'}';
      }
      return false;
    } catch (exception) {
      _error = 'Google sign-in failed: $exception';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearGoogleSignUpRequired() {
    _googleSignUpRequired = false;
    notifyListeners();
  }

  /// Removes the just-created Firebase account if the user declines signup.
  Future<void> cancelGoogleSignUp() async {
    _setLoading(true);
    _error = null;
    try {
      if (_googleSignUpRequired) {
        await _firebaseAuth.currentUser?.delete();
      }
      await _firebaseAuth.signOut();
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      _user = null;
      _googleSignUpRequired = false;
    } on FirebaseAuthException catch (exception) {
      _error = exception.message ?? 'Could not cancel Google signup. Please try again.';
      await _firebaseAuth.signOut();
      _user = null;
    } catch (_) {
      _error = 'Could not cancel Google signup. Please try again.';
      await _firebaseAuth.signOut();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Kept as a compatibility alias. Login must never create an account;
  /// account creation happens only through the explicit signup flow.
  @Deprecated('Use signIn; account creation requires an explicit signup action.')
  Future<void> signInOrSignUp(String email, String password) async {
    await signIn(email, password);
  }

  Future<void> signUp(
    String email,
    String password, {
    String name = '',
  }) async {
    _setLoading(true);
    _error = null;
    _lastSignInErrorCode = null;
    _verificationEmailSent = false;
    var accountCreated = false;

    try {
      if (!_isValidGmail(email)) {
        _error = 'Please sign up with a valid Gmail address ending in @gmail.com.';
        return;
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      accountCreated = true;

      final user = credential.user;
      final cleanedName = name.trim();

      if (user != null && cleanedName.isNotEmpty) {
        await user.updateDisplayName(cleanedName);
        await user.reload();
        _user = _mapUser(_firebaseAuth.currentUser);
      } else {
        _user = _mapUser(user);
      }

      if (user == null) {
        _error = 'Account creation could not be completed. Please try again.';
        return;
      }

      await user.sendEmailVerification();
      await _firebaseAuth.signOut();
      _user = null;
      _googleSignUpRequired = false;
      _verificationEmailSent = true;
    } on FirebaseAuthException catch (exception) {
      if (exception.code == 'email-already-in-use') {
        _error = 'An account already exists with this Gmail. Please log in instead.';
      } else if (accountCreated) {
        _error = 'Your account was created, but Firebase could not send the verification email. Try logging in to request another link.';
        await _firebaseAuth.signOut();
        _user = null;
      } else {
        _error = _firebaseErrorMessage(exception);
      }
    } catch (_) {
      if (accountCreated) {
        _error = 'Your account was created, but the verification email could not be sent. Try logging in to request another link.';
        await _firebaseAuth.signOut();
        _user = null;
      } else {
        _error =
            'Unable to create your account. Check your connection and try again.';
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    _error = null;
    _forgotPasswordSent = false;

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      _forgotPasswordSent = true;
    } on FirebaseAuthException catch (exception) {
      _error = _firebaseErrorMessage(exception);
    } catch (_) {
      _error = 'Unable to send a password reset email. Try again.';
    } finally {
      _setLoading(false);
    }
  }

  void clearForgotPasswordState() {
    _forgotPasswordSent = false;
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);
    _error = null;

    try {
      await _firebaseAuth.signOut();
      _user = null;
    } on FirebaseAuthException catch (exception) {
      _error = _firebaseErrorMessage(exception);
    } catch (_) {
      _error = 'Unable to sign out. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  DemoUser? _mapUser(User? user) {
    if (user == null) return null;

    final email = user.email ?? '';
    final fallbackName = email.isEmpty ? 'Athlete' : email.split('@').first;

    return DemoUser(
      uid: user.uid,
      email: email,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : _titleCase(fallbackName),
    );
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  bool _isValidGmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return RegExp(r'^[^\s@]+@gmail\.com$').hasMatch(normalizedEmail);
  }

  String _firebaseErrorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account exists with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-credential':
        return 'Email or password is incorrect. Please check both and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please log in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
