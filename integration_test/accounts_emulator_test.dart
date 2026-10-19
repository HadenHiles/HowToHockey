import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';

/// Runs the whole account flow against the local Auth, Firestore and Functions emulators:
///   npm --prefix functions run build
///   firebase emulators:start --only auth,functions,firestore --project how-to-hockey
///   flutter test integration_test/accounts_emulator_test.dart -d <android-or-ios-emulator> --dart-define=USE_EMULATORS=true
/// It prints `E2E ...` lines and fails if any `UNEXPECTED` line appears.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('accounts end to end against the emulators', (tester) async {
    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    await tester.pumpAndSettle();
    final auth = FirebaseAuthService();
    final profiles = ProfileRepository();
    final now = DateTime.now();
    final unexpected = <String>[];
    void log(String s) {
      debugPrint('E2E $s');
      if (s.startsWith('UNEXPECTED')) unexpected.add(s);
    }

    final guest = FirebaseAuth.instance.currentUser!;
    log('guest anon=${guest.isAnonymous}');

    // A guest cannot create profiles.
    try {
      await profiles.createOwnProfile(displayName: 'Pat H.', birthYear: now.year - 30, now: now);
      log('UNEXPECTED guest profile ok');
    } on ProfileException catch (e) {
      log('guestBlocked="${e.message}"');
    }

    final email = 'pat${now.millisecondsSinceEpoch}@example.com';
    await auth.createEmailAccount(email: email, password: 'correct horse battery');
    final account = FirebaseAuth.instance.currentUser!;
    log('upgraded sameUid=${account.uid == guest.uid} anon=${account.isAnonymous} state=${auth.current.runtimeType}');

    final ownId = await profiles.createOwnProfile(displayName: ' pat  h ', birthYear: now.year - 30, now: now);
    final profileDoc = await FirebaseFirestore.instance.doc('profiles/$ownId').get();
    log('ownProfile id==uid=${ownId == account.uid} name=${profileDoc.data()?['displayName']} isChild=${profileDoc.data()?['isChild']}');
    final userDoc = await FirebaseFirestore.instance.doc('users/${account.uid}').get();
    log('roles=${userDoc.data()?['roles']} email=${userDoc.data()?['email']}');

    try {
      await profiles.createOwnProfile(displayName: 'Pat H.', birthYear: now.year - 30, now: now);
      log('UNEXPECTED duplicate ok');
    } on ProfileException catch (e) {
      log('duplicateBlocked="${e.message}"');
    }

    for (var i = 0; i < 3; i++) {
      await profiles.createChildProfile(displayName: 'Kid ${String.fromCharCode(65 + i)}', birthYear: now.year - 9, now: now);
    }
    try {
      await profiles.createChildProfile(displayName: 'Kid D', birthYear: now.year - 9, now: now);
      log('UNEXPECTED fourth child ok');
    } on ProfileException catch (e) {
      log('capBlocked="${e.message}"');
    }
    final kids = await FirebaseFirestore.instance.collection('profiles').where('ownerUid', isEqualTo: account.uid).where('isChild', isEqualTo: true).get();
    log('childrenStored=${kids.size}');

    // Rules: the client cannot write profiles or roles directly.
    try {
      await FirebaseFirestore.instance.doc('users/${account.uid}').set({
        'roles': ['coach'],
      });
      log('UNEXPECTED client wrote roles');
    } on FirebaseException catch (e) {
      log('rolesWriteBlocked=${e.code}');
    }
    try {
      await FirebaseFirestore.instance.doc('profiles/${kids.docs.first.id}').update({'displayName': 'Hacked H.'});
      log('UNEXPECTED client edited profile');
    } on FirebaseException catch (e) {
      log('profileEditBlocked=${e.code}');
    }

    await auth.signOut();
    log('afterSignOut=${auth.current.runtimeType} differentUid=${FirebaseAuth.instance.currentUser!.uid != account.uid}');
    try {
      await auth.signInWithEmail(email: email, password: 'wrong password!!');
      log('UNEXPECTED bad password ok');
    } on AuthProblem catch (e) {
      log('badPassword="${e.message}"');
    }
    await auth.signInWithEmail(email: email, password: 'correct horse battery');
    log('signedBackIn sameAccount=${FirebaseAuth.instance.currentUser!.uid == account.uid}');
    final again = await FirebaseFirestore.instance.collection('profiles').where('ownerUid', isEqualTo: account.uid).get();
    log('profilesAfterSignIn=${again.size}');

    // Another account cannot see these profiles.
    await auth.signOut();
    await auth.createEmailAccount(email: 'other${now.millisecondsSinceEpoch}@example.com', password: 'another good pass');
    try {
      await FirebaseFirestore.instance.doc('profiles/$ownId').get();
      log('UNEXPECTED stranger read');
    } on FirebaseException catch (e) {
      log('strangerRead=${e.code}');
    }
    expect(unexpected, isEmpty, reason: 'steps that should have been refused succeeded');
    debugPrint('E2E DONE');
  });
}
