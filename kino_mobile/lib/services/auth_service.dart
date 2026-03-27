import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _readableMessage(e);
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _readableMessage(e);
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null && displayName.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _readableMessage(e);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String getUserInitials(User user) {
    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((part) => part.trim().isNotEmpty)
          .take(2)
          .toList();
      if (parts.isNotEmpty) {
        return parts.map((part) => part[0].toUpperCase()).join();
      }
    }

    final String email = user.email ?? 'guest';
    final String fallback = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return fallback.substring(0, fallback.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _readableMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'invalid-email':
        return 'Invalid email or password';
      case 'user-not-found':
        return 'User not found';
      case 'too-many-requests':
        return 'Too many attempts, try later';
      case 'email-already-in-use':
        return 'That email is already in use';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
