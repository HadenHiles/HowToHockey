import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/main.dart';

void main() {
  test('only unrecoverable session errors replace an anonymous user, never offline errors', () {
    expect(deadSessionErrorCodes, containsAll(['internal-error', 'user-token-expired', 'user-not-found']));
    expect(deadSessionErrorCodes, isNot(contains('network-request-failed')));
    expect(deadSessionErrorCodes, isNot(contains('too-many-requests')));
  });

  test('a signed-in user with a working token is kept and nobody new is created', () async {
    final auth = _FakeAuth(_FakeUser(anonymous: true));
    await ensureSignedIn(auth);
    expect(auth.signedOut, isFalse);
    expect(auth.signedInAnonymously, isFalse);
  });

  test('no user signs in anonymously', () async {
    final auth = _FakeAuth(null);
    await ensureSignedIn(auth);
    expect(auth.signedInAnonymously, isTrue);
  });

  test('a dead anonymous session is replaced', () async {
    final auth = _FakeAuth(_FakeUser(anonymous: true, tokenError: 'internal-error'));
    await ensureSignedIn(auth);
    expect(auth.signedOut, isTrue);
    expect(auth.signedInAnonymously, isTrue);
  });

  test('offline errors keep the anonymous user', () async {
    final auth = _FakeAuth(_FakeUser(anonymous: true, tokenError: 'network-request-failed'));
    await ensureSignedIn(auth);
    expect(auth.signedOut, isFalse);
    expect(auth.signedInAnonymously, isFalse);
  });

  test('a real account is never replaced automatically', () async {
    final auth = _FakeAuth(_FakeUser(anonymous: false, tokenError: 'internal-error'));
    await ensureSignedIn(auth);
    expect(auth.signedOut, isFalse);
    expect(auth.signedInAnonymously, isFalse);
  });
}

class _FakeUser implements User {
  _FakeUser({required this.anonymous, this.tokenError});

  final bool anonymous;
  final String? tokenError;

  @override
  bool get isAnonymous => anonymous;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (tokenError != null) throw FirebaseAuthException(code: tokenError!);
    return 'token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this.user);

  User? user;
  var signedOut = false;
  var signedInAnonymously = false;

  @override
  User? get currentUser => user;

  @override
  Future<void> signOut() async {
    signedOut = true;
    user = null;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    signedInAnonymously = true;
    return _FakeCredential();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
