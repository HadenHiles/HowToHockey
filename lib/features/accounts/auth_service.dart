import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the player stands with sign-in.
sealed class AuthState {
  const AuthState();
}

class SignedOut extends AuthState {
  const SignedOut();
}

/// Using the app without an account. The ID is kept when the player later creates an account.
class GuestSession extends AuthState {
  const GuestSession(this.uid);

  final String uid;
}

class SignedInAccount extends AuthState {
  const SignedInAccount({required this.uid, required this.email, required this.emailVerified});

  final String uid;
  final String? email;
  final bool emailVerified;
}

/// A sign-in problem, worded so it is safe to show the player.
class AuthProblem implements Exception {
  const AuthProblem(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

const minPasswordLength = 8;

/// Basic shape check so obvious typos are caught before asking the server.
bool looksLikeEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(value.trim());

String? passwordProblem(String password) => password.length < minPasswordLength ? 'Use at least $minPasswordLength characters.' : null;

abstract class AuthService {
  AuthState get current;
  Stream<AuthState> get changes;

  /// Creates an account. A guest keeps their ID, so anything saved to it stays theirs.
  Future<void> createEmailAccount({required String email, required String password});

  Future<void> signInWithEmail({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

AuthProblem authProblemFor(FirebaseAuthException error) => switch (error.code) {
  'email-already-in-use' || 'credential-already-in-use' => const AuthProblem('An account with this email already exists. Try signing in instead.', code: 'email-already-in-use'),
  'weak-password' => const AuthProblem('That password is too easy to guess. Try a longer one.', code: 'weak-password'),
  'invalid-email' => const AuthProblem('That email doesn\'t look right.', code: 'invalid-email'),
  'wrong-password' || 'invalid-credential' || 'user-not-found' || 'invalid-login-credentials' => const AuthProblem('That email and password don\'t match.', code: 'invalid-credential'),
  'user-disabled' => const AuthProblem('This account has been turned off. Contact support for help.', code: 'user-disabled'),
  'too-many-requests' => const AuthProblem('Too many tries. Wait a few minutes and try again.', code: 'too-many-requests'),
  'network-request-failed' => const AuthProblem('We couldn\'t reach the server. Check your connection and try again.', code: 'network'),
  'operation-not-allowed' => const AuthProblem('Email sign-in isn\'t turned on yet.', code: 'operation-not-allowed'),
  _ => const AuthProblem('Something went wrong. Try again.'),
};

AuthState authStateOf(User? user) {
  if (user == null) return const SignedOut();
  if (user.isAnonymous) return GuestSession(user.uid);
  return SignedInAccount(uid: user.uid, email: user.email, emailVerified: user.emailVerified);
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  AuthState get current => authStateOf(_auth.currentUser);

  @override
  Stream<AuthState> get changes => _auth.userChanges().map(authStateOf);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw authProblemFor(error);
    }
  }

  @override
  Future<void> createEmailAccount({required String email, required String password}) => _guard(() async {
    final user = _auth.currentUser;
    final credential = EmailAuthProvider.credential(email: email.trim(), password: password);
    if (user != null && user.isAnonymous) {
      // Linking upgrades the guest in place, so the user ID (and anything tied to it) is kept.
      await user.linkWithCredential(credential);
    } else {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    }
    // Best effort: a missing verification email must not undo a created account.
    unawaited(_auth.currentUser?.sendEmailVerification().catchError((Object _) {}));
  });

  @override
  Future<void> signInWithEmail({required String email, required String password}) => _guard(() async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Keep the app usable as a guest after signing out.
    await _guard(() => _auth.signInAnonymously());
  }
}

final authServiceProvider = Provider<AuthService>((ref) => FirebaseAuthService());

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final service = ref.watch(authServiceProvider);
  yield service.current;
  yield* service.changes;
});
