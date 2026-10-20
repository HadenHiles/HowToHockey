import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:url_launcher/url_launcher.dart';

/// Runs the whole account flow against the local Auth, Firestore and Functions emulators:
///   npm --prefix functions run build
///   firebase emulators:start --only auth,functions,firestore --project how-to-hockey
///   flutter test integration_test/accounts_emulator_test.dart -d EMULATOR_ID --dart-define=USE_EMULATORS=true
/// It prints `E2E ...` lines and fails if any `UNEXPECTED` line appears.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('accounts end to end against the emulators', (tester) async {
    expect(const bool.fromEnvironment('USE_EMULATORS'), isTrue, reason: 'Never run account creation/deletion tests against production.');
    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    // Native Auth persists across installs, but a fresh emulator has no previous sign-ins.
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
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
    expect(guest.isAnonymous, isTrue);
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
    expect(account.uid, guest.uid);
    expect(account.isAnonymous, isFalse);
    log('upgraded sameUid=${account.uid == guest.uid} anon=${account.isAnonymous} state=${auth.current.runtimeType}');

    final ownId = await profiles.createOwnProfile(displayName: ' pat  h ', birthYear: now.year - 30, now: now);
    final profileDoc = await FirebaseFirestore.instance.doc('profiles/$ownId').get();
    expect(ownId, account.uid);
    expect(profileDoc.data()?['displayName'], 'Pat H.');
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
    expect(kids.size, 3);
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
    expect(FirebaseAuth.instance.currentUser!.uid, account.uid);
    expect(again.size, 4);
    log('profilesAfterSignIn=${again.size}');

    // Create a real team through the app, then exercise the callable + rules boundary.
    final container = ProviderScope.containerOf(tester.element(find.byType(HockeyApp)));
    final router = container.read(appRouterProvider);
    final teams = TeamRepository();
    router.go('/coach/create');
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Team name'), 'QA North Stars');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create team'));
    await waitForText(tester, 'Player join code');
    final coached = await FirebaseFirestore.instance.collection('teams').where('coachUids', arrayContains: account.uid).get();
    expect(coached.size, 1);
    final team = coached.docs.single;
    final code = team.data()['joinCode'] as String;
    expect(team.data()['visibility'], 'private');
    final childId = kids.docs.first.id;

    final link = Uri.parse(teamInviteLink(code)).replace(queryParameters: {'code': code, 'profile': childId});
    expect(await launchUrl(link, mode: LaunchMode.externalApplication), isTrue);
    await waitForText(tester, 'Look up invitation');
    await tester.tap(find.text('Look up invitation'));
    await waitForText(tester, 'Join team');
    await tester.tap(find.text('Join team'));
    await waitForText(tester, 'Joined QA North Stars.');
    expect(find.text('Joined QA North Stars.'), findsOneWidget);
    expect((await FirebaseFirestore.instance.doc('profiles/$childId').get()).data()!['teamIds'], [team.id]);
    container.read(activePlayerIdProvider.notifier).choose(childId);
    router.go('/team');
    await tester.pumpAndSettle();
    expect(find.text('QA North Stars'), findsOneWidget);
    container.read(activePlayerIdProvider.notifier).choose(ownId);
    await tester.pumpAndSettle();
    expect(find.text('QA North Stars'), findsNothing, reason: 'Membership belongs to the child, not the account.');

    final coachCode = await teams.createInvite(team.id, coach: true);
    final kidCode = await profiles.createPairingCode(kids.docs[1].id);
    final pairing = await profiles.redeemPairingCode(kidCode.code);
    await auth.signInWithKidToken(pairing.token);
    expect(auth.current, isA<KidDeviceSession>());
    expect(await teams.join(profileId: kids.docs[1].id, code: code), 'parentPending');
    await auth.signOut();
    await auth.signInWithEmail(email: email, password: 'correct horse battery');
    final requests = await teams.watchParentRequests(account.uid).firstWhere((requests) => requests.isNotEmpty).timeout(const Duration(seconds: 30));
    expect(requests, hasLength(1));
    await teams.review(requests.single, true);
    expect((await FirebaseFirestore.instance.doc('profiles/${kids.docs[1].id}').get()).data()!['teamIds'], [team.id]);

    // Another account cannot see these profiles.
    await auth.signOut();
    await auth.createEmailAccount(email: 'other${now.millisecondsSinceEpoch}@example.com', password: 'another good pass');
    try {
      await FirebaseFirestore.instance.doc('profiles/$ownId').get();
      log('UNEXPECTED stranger read');
    } on FirebaseException catch (e) {
      log('strangerRead=${e.code}');
    }
    await profiles.createOwnProfile(displayName: 'Other H.', birthYear: now.year - 30, now: now);
    await teams.acceptCoach(coachCode);
    expect((await FirebaseFirestore.instance.doc('teams/${team.id}').get()).data()!['coachUids'], contains(FirebaseAuth.instance.currentUser!.uid));
    await expectLater(teams.acceptCoach(coachCode), throwsA(isA<TeamException>()));
    await teams.remove(team.id, childId);
    expect((await FirebaseFirestore.instance.collection('teams/${team.id}/members').get()).size, 1);
    await profiles.deleteAccount();
    await auth.signOut();
    await auth.signInWithEmail(email: email, password: 'correct horse battery');
    expect((await FirebaseFirestore.instance.doc('teams/${team.id}').get()).data()!['coachUids'], [account.uid]);
    await profiles.deleteAccount();
    await auth.signOut();
    expect(unexpected, isEmpty, reason: 'steps that should have been refused succeeded');
    debugPrint('E2E DONE');
  });
}

Future<void> waitForText(WidgetTester tester, String text) async {
  final timeout = DateTime.now().add(const Duration(seconds: 30));
  while (find.text(text).evaluate().isEmpty && DateTime.now().isBefore(timeout)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.text(text), findsWidgets, reason: 'Timed out waiting for $text');
  await tester.pumpAndSettle();
}
