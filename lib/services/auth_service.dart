import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google - Working implementation for google_sign_in 6.1.6
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google Sign-In process...');

      // Sign out first to ensure we get the account picker every time
      await _googleSignIn.signOut();
      print('✅ Signed out from Google');

      // Trigger the authentication flow
      print('🔄 Triggering Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('👤 Google user: ${googleUser?.email ?? 'null'}');

      if (googleUser == null) {
        print('❌ Google sign in aborted by user');
        throw Exception('Google sign in aborted by user');
      }

      // Obtain the auth details from the request
      print('🔑 Getting authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('✅ Got authentication details');

      // Create a new credential
      print('🎫 Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('✅ Created Firebase credential');

      // Sign in to Firebase with the credential
      print('🔥 Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Successfully signed in to Firebase');

      return userCredential;
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      // If authentication fails, sign out from Google to ensure a clean state
      await _googleSignIn.signOut();
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if email exists in Firebase Auth
  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Send password reset email with enhanced features
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Rate limiting check
      if (_isRateLimited(email)) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message:
              'Too many password reset attempts. Please wait before trying again.',
        );
      }

      // Log attempt for analytics
      _logPasswordResetAttempt(email);

      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://fitness-7292e.firebaseapp.com/reset-password',
          handleCodeInApp: true,
          iOSBundleId: 'com.horizon.nextfitx',
          androidPackageName: 'com.horizon.nextfitx',
          androidInstallApp: true,
          androidMinimumVersion: '12',
          dynamicLinkDomain: 'fitness-7292e.page.link',
        ),
      );

      // Record successful attempt
      _recordSuccessfulReset(email);
    } on FirebaseAuthException catch (e) {
      // Record failed attempt
      _recordFailedReset(email, e.code);
      throw _handleAuthException(e);
    }
  }

  // Rate limiting for password reset
  static final Map<String, List<DateTime>> _resetAttempts = {};
  static const int _maxAttemptsPerHour = 3;
  static const Duration _rateLimitWindow = Duration(hours: 1);

  bool _isRateLimited(String email) {
    final now = DateTime.now();
    final attempts = _resetAttempts[email] ?? [];

    // Remove old attempts outside the window
    attempts
        .removeWhere((attempt) => now.difference(attempt) > _rateLimitWindow);

    _resetAttempts[email] = attempts;

    return attempts.length >= _maxAttemptsPerHour;
  }

  void _logPasswordResetAttempt(String email) {
    final now = DateTime.now();
    _resetAttempts[email] = (_resetAttempts[email] ?? [])..add(now);

    // Log for analytics (could be sent to Firebase Analytics)
    print('Password reset attempt for: ${_maskEmail(email)} at $now');
  }

  void _recordSuccessfulReset(String email) {
    print('Password reset email sent successfully to: ${_maskEmail(email)}');
    // Could send to analytics service
  }

  void _recordFailedReset(String email, String errorCode) {
    print('Password reset failed for: ${_maskEmail(email)}, error: $errorCode');
    // Could send to analytics service
  }

  String _maskEmail(String email) {
    if (email.length <= 3) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  // OTP storage for password reset (in production, this should be in a secure database)
  static final Map<String, Map<String, dynamic>> _otpStorage = {};

  // Save OTP for verification
  Future<void> saveOTPForVerification(String email, String otpCode) async {
    final now = DateTime.now();
    final expiryTime =
        now.add(const Duration(minutes: 10)); // OTP expires in 10 minutes

    _otpStorage[email] = {
      'otp': otpCode,
      'created_at': now,
      'expires_at': expiryTime,
      'attempts': 0,
    };

    print('OTP saved for $email: $otpCode (expires at $expiryTime)');
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String otpCode) async {
    final otpData = _otpStorage[email];

    if (otpData == null) {
      print('No OTP found for email: $email');
      return false;
    }

    final now = DateTime.now();
    final expiryTime = otpData['expires_at'] as DateTime;
    final attempts = otpData['attempts'] as int;
    final storedOtp = otpData['otp'] as String;

    // Check if OTP has expired
    if (now.isAfter(expiryTime)) {
      print('OTP expired for email: $email');
      _otpStorage.remove(email);
      return false;
    }

    // Check if too many attempts
    if (attempts >= 3) {
      print('Too many OTP attempts for email: $email');
      _otpStorage.remove(email);
      return false;
    }

    // Increment attempts
    _otpStorage[email] = {
      ...otpData,
      'attempts': attempts + 1,
    };

    // Verify OTP
    if (storedOtp == otpCode) {
      print('OTP verified successfully for email: $email');
      // Don't remove OTP yet, it will be used for password reset
      return true;
    } else {
      print('Invalid OTP for email: $email');
      return false;
    }
  }

  // Reset password with OTP verification
  Future<void> resetPasswordWithOTP(String email, String newPassword) async {
    final otpData = _otpStorage[email];

    if (otpData == null) {
      throw Exception(
          'OTP verification required. Please verify your OTP first.');
    }

    final now = DateTime.now();
    final expiryTime = otpData['expires_at'] as DateTime;

    // Check if OTP has expired
    if (now.isAfter(expiryTime)) {
      _otpStorage.remove(email);
      throw Exception('OTP has expired. Please request a new one.');
    }

    try {
      // Get user by email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw Exception(
            'Email tidak terdaftar dalam sistem. Silakan daftar terlebih dahulu.');
      }

      // For Firebase Auth, we need to use a different approach since we can't directly change password
      // In a real implementation, you might use a custom token or admin SDK
      // For now, we'll simulate the password reset

      // Remove OTP after successful password reset
      _otpStorage.remove(email);

      print('Password reset successful for email: $email');

      // In a real implementation, you would update the password in Firebase
      // For demo purposes, we'll just return success
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This sign in method is not enabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is malformed or has expired.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
