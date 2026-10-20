import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

const adult = PlayerProfile(id: 'parent', ownerUid: 'parent', displayName: 'Pat H.', birthYear: 1990, isChild: false);
const child = PlayerProfile(id: 'child', ownerUid: 'parent', displayName: 'Kid H.', birthYear: 2017, isChild: true);
const team = Team(id: 't1', name: 'North Stars', memberCount: 1, memberProfileIds: ['child'], joinCode: 'ABCDEF0123456789');

Future<(ProviderContainer, FakeTeamRepository, FakeAuthService)> mount(
  WidgetTester tester, {
  AuthState auth = const SignedInAccount(uid: 'parent', email: 'parent@example.com', emailVerified: true),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final teams = FakeTeamRepository();
  final profiles = FakeProfileRepository()..own = adult;
  profiles.children.add(child);
  final authService = FakeAuthService(auth);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(authService),
      profileRepositoryProvider.overrideWithValue(profiles),
      teamRepositoryProvider.overrideWithValue(teams),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testSessionsOverride,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return (container, teams, authService);
}

void main() {
  testWidgets('invite lookup chooses a child, handles network failure, and retries without fake success', (tester) async {
    final (container, teams, _) = await mount(tester);
    container.read(appRouterProvider).go('/join?code=ABCDEF0123456789&profile=child');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look up invitation'));
    await tester.pumpAndSettle();
    expect(find.text('North Stars'), findsOneWidget);
    expect(tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).initialValue, 'child');
    teams.failWith = const TeamException('Offline. Try again.');
    await tester.tap(find.text('Join team'));
    await tester.pumpAndSettle();
    expect(find.text('Offline. Try again.'), findsOneWidget);
    expect(find.text('Joined North Stars.'), findsNothing);
    teams.failWith = null;
    await tester.tap(find.text('Join team'));
    await tester.pumpAndSettle();
    expect(teams.calls, contains('join:child'));
    expect(find.text('Joined North Stars.'), findsOneWidget);
    expect(container.read(pendingTeamInviteProvider), isNull);
  });

  testWidgets('kid device requests approval and cannot accept coach invitation', (tester) async {
    final (container, teams, _) = await mount(tester, auth: const KidDeviceSession('child'));
    teams.joinStatus = 'parentPending';
    container.read(appRouterProvider).go('/join?code=ABCDEF0123456789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look up invitation'));
    await tester.pumpAndSettle();
    expect(container.read(switchablePlayersProvider).map((p) => p.id), ['child']);
    await tester.tap(find.text('Join team'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent to your parent for approval.'), findsOneWidget);
    teams.inviteKind = 'coach';
    container.read(appRouterProvider).go('/team');
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/join?code=ABCDEF0123456789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look up invitation'));
    await tester.pumpAndSettle();
    expect(find.text('Accept coach invitation'), findsNothing);
    expect(find.textContaining('Ask an adult'), findsOneWidget);
  });

  testWidgets('guest invitation survives sign in and returns to review', (tester) async {
    final (container, _, _) = await mount(tester, auth: const GuestSession('guest'));
    container.read(appRouterProvider).go('/join?code=ABCDEF0123456789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'parent@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(container.read(appRouterProvider).state.uri.path, '/join');
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Team code or invite link')).controller!.text, 'ABCDEF0123456789');
  });

  testWidgets('membership follows the chosen player and parent can remove a child after confirmation', (tester) async {
    final (container, teams, _) = await mount(tester);
    teams.teams = [team];
    container.read(appRouterProvider).go('/team');
    await tester.pumpAndSettle();
    expect(find.text('North Stars'), findsNothing, reason: 'parent is not a member');
    container.read(activePlayerIdProvider.notifier).choose('child');
    await tester.pumpAndSettle();
    expect(find.text('North Stars'), findsOneWidget);
    await tester.tap(find.text('Leave team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(teams.calls, isEmpty);
    await tester.tap(find.text('Leave team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(teams.calls, ['remove:t1:child']);
  });

  testWidgets('parent approvals and coach requests call the server with the correct profile', (tester) async {
    final (container, teams, _) = await mount(tester);
    teams.requests = const [TeamRequest(teamId: 't1', profileId: 'child', teamName: 'North Stars', displayName: 'Kid H.', status: 'parentPending')];
    container.read(appRouterProvider).go('/parent/kids/approvals');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(teams.calls, ['review:child:true']);
    teams.teams = [team];
    teams.requests = const [TeamRequest(teamId: 't1', profileId: 'child', teamName: 'North Stars', displayName: 'Kid H.', status: 'coachPending')];
    container.read(appRouterProvider).go('/coach/roster/requests');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(teams.calls.last, 'review:child:false');
  });

  testWidgets('unfinished workouts cannot be handed to another player', (tester) async {
    final (container, _, _) = await mount(tester);
    container.read(trainingSessionProvider.notifier).start(sampleDrills);
    container.read(appRouterProvider).go('/parent/kids/child');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Train as Kid H.'));
    await tester.pumpAndSettle();
    expect(container.read(activePlayerProvider)?.id, 'parent');
    expect(find.text('Finish your current workout before switching players.'), findsOneWidget);
  });

  test('stale child snapshots are never switchable under a different account', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthService(const SignedInAccount(uid: 'stranger', email: 'other@example.com', emailVerified: true));
    final stream = StreamController<List<PlayerProfile>>();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
        ownProfileProvider.overrideWith((ref) => Stream.value(null)),
        childProfilesProvider.overrideWith((ref) => stream.stream),
      ],
    );
    final subscription = container.listen(switchablePlayersProvider, (_, _) {});
    stream.add([child]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(switchablePlayersProvider), isEmpty);
    subscription.close();
    container.dispose();
    await stream.close();
  });
}
