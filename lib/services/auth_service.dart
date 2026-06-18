import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Wraps FirebaseAuth so the rest of the app never touches the SDK
/// directly. Converts FirebaseAuthException codes into readable
/// messages for display in the UI.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // The serverClientId (web client ID) is required on Android so that
  // GoogleSignIn can return an idToken that Firebase Auth can verify.
  // On iOS and Web it is optional but harmless to include.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '750499933497-fii0h4v4f8gd7nv5fo8ulvq1nm1b09nn.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The Firebase ID token to send as `Authorization: Bearer <token>`
  /// on every backend request. Firebase auto-refreshes this under the
  /// hood, so always fetch it fresh rather than caching it yourself.
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<User> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Web uses Firebase's built-in popup flow; mobile uses the
      // google_sign_in package which opens the native account chooser.
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(provider);
        return userCredential.user;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;

      // googleAuth.idToken can be null on Android when serverClientId is
      // missing from the GoogleSignIn constructor — that is now fixed above.
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw AuthException(
            'Google sign-in returned no credentials. '
            'Ensure SHA-1 is registered in Firebase Console.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    } catch (e) {
      // Catches PlatformException (e.g. sign_in_failed, network_error)
      // and any other unexpected errors so they surface as readable UI messages.
      final msg = e.toString().toLowerCase();
      if (msg.contains('sign_in_canceled') || msg.contains('canceled')) {
        return null; // user cancelled — treat same as dismissing the sheet
      }
      if (msg.contains('network')) {
        throw AuthException('Network error. Check your connection.');
      }
      if (msg.contains('sha') ||
          msg.contains('developer_error') ||
          msg.contains('10:')) {
        throw AuthException(
            'Google Sign-In misconfiguration: add your SHA-1 fingerprint '
            'to the Firebase Console and re-download google-services.json.');
      }
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
