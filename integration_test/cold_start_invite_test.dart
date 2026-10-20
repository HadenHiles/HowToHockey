import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart' as app;

import 'accounts_emulator_test.dart' show waitForText;

/// Run with tool/test_cold_start_invite.mjs inside local Firebase emulators.
/// The host terminates the app and opens its native URL before attaching the driver.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a native cold-start invitation survives sign-in and joins the selected profile', (tester) async {
    const email = String.fromEnvironment('COLD_INVITE_EMAIL');
    const code = String.fromEnvironment('COLD_INVITE_CODE');
    const profileId = String.fromEnvironment('COLD_INVITE_PROFILE');
    expect(const bool.fromEnvironment('USE_EMULATORS'), isTrue, reason: 'Never run against production.');
    expect(email, isNotEmpty);
    expect(code, isNotEmpty);
    expect(profileId, isNotEmpty);

    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    // A guest sees the invitation and sign-in action, not a lookup button yet.
    await waitForText(tester, 'Sign in or create an account, then open this invitation again. Your code stays below.');
    final container = ProviderScope.containerOf(tester.element(find.byType(HockeyApp)));
    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, '/join', reason: 'The OS must deliver the URL; this test never calls router.go.');
    expect(router.state.uri.queryParameters['code'], code);
    expect(find.text(code), findsOneWidget);
    expect(container.read(pendingTeamInviteProvider), code);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'local cold invite password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await waitForText(tester, 'Look up invitation');
    expect(router.state.uri.path, '/join');
    expect(router.state.uri.queryParameters['code'], code);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Team code or invite link')).controller!.text, code);

    await tester.tap(find.text('Look up invitation'));
    await waitForText(tester, 'Join team');
    expect(find.text('Cold Start Team'), findsOneWidget);
    expect(tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).initialValue, profileId);
    await tester.ensureVisible(find.text('Join team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join team'));
    await waitForText(tester, 'Joined Cold Start Team.');
    final profile = await FirebaseFirestore.instance.doc('profiles/$profileId').get(const GetOptions(source: Source.server));
    expect(profile.data()!['teamIds'], [profileId]);
    expect(container.read(pendingTeamInviteProvider), isNull);
    await ProfileRepository().deleteAccount();
    debugPrint('COLD INVITE PASS: native URL, retained code, sign-in, lookup and membership');
  });
}
