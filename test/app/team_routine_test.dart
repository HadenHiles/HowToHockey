import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/routine_state.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

const adult = PlayerProfile(id: 'parent', ownerUid: 'parent', displayName: 'Pat H.', birthYear: 1990, isChild: false);
const child = PlayerProfile(id: 'child', ownerUid: 'parent', displayName: 'Avery H.', birthYear: 2015, isChild: true);

Future<(ProviderContainer, FakeTeamRepository)> mount(WidgetTester tester, List<Team> teams, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final repository = FakeTeamRepository()..teams = teams;
  final profiles = FakeProfileRepository()..own = adult;
  profiles.children.add(child);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authServiceProvider.overrideWithValue(FakeAuthService(const SignedInAccount(uid: 'parent', email: 'parent@example.com', emailVerified: true))),
      profileRepositoryProvider.overrideWithValue(profiles),
      teamRepositoryProvider.overrideWithValue(repository),
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
  return (container, repository);
}

void main() {
  final first = sampleDrills.first;
  final second = sampleDrills[1];

  testWidgets('a coach shares a saved routine with the team and can stop sharing', (tester) async {
    final plan = RoutinePlan(id: 'r1', name: 'Quick hands night', drills: [first, second]);
    final custom = RoutinePlan(
      id: 'r2',
      name: 'My own thing',
      drills: [first.copyWith(id: 'custom-shot-1')],
    );
    final (container, repository) = await mount(
      tester,
      [const Team(id: 't1', name: 'North Stars', memberCount: 0, joinCode: 'ABCDEF0123456789')],
      prefs: {'savedRoutines': '[]'},
    );
    await container.read(routineLibraryProvider.notifier).save(plan);
    await container.read(routineLibraryProvider.notifier).save(custom);
    container.read(appRouterProvider).go('/coach/team');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share a routine'));
    await tester.pumpAndSettle();
    expect(find.text('Quick hands night'), findsOneWidget);
    expect(find.text('My own thing'), findsNothing, reason: 'custom drills can\'t be shared with a team');
    await tester.tap(find.byKey(const ValueKey('share-r1')));
    await tester.pumpAndSettle();
    expect(repository.calls.last, 'shareRoutine:t1:Quick hands night:${first.id}x${first.defaultPrescription.sets},${second.id}x${second.defaultPrescription.sets}');

    repository.teams = [
      Team(
        id: 't1',
        name: 'North Stars',
        memberCount: 0,
        joinCode: 'ABCDEF0123456789',
        routine: TeamRoutine(name: 'Quick hands night', drills: [(drillId: first.id, sets: 3)]),
      ),
    ];
    container.invalidate(coachedTeamsProvider);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-routine-name')), findsOneWidget);
    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();
    expect(repository.calls.last, 'stopSharing:t1');
  });

  testWidgets('a player sees the coach\'s routine on Train and starts it with the coach\'s set counts', (tester) async {
    final (container, _) = await mount(tester, [
      Team(
        id: 't1',
        name: 'North Stars',
        memberCount: 1,
        memberProfileIds: const ['parent'],
        routine: TeamRoutine(name: 'Quick hands night', drills: [(drillId: first.id, sets: 2), (drillId: 'not-in-this-app', sets: 5), (drillId: second.id, sets: 4)]),
      ),
      const Team(id: 't2', name: 'Other team', memberCount: 1, memberProfileIds: ['someone-else']),
    ]);
    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    expect(find.text('Quick hands night'), findsOneWidget);
    expect(find.textContaining('North Stars'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final session = container.read(trainingSessionProvider);
    expect(session.drills.map((d) => d.id), [first.id, second.id]);
    expect(session.drills.map((d) => d.defaultPrescription.sets), [2, 4]);
  });

  testWidgets('another family\'s team routine never shows up', (tester) async {
    final (container, _) = await mount(tester, [
      Team(
        id: 't9',
        name: 'Strangers',
        memberCount: 1,
        memberProfileIds: const ['someone-else'],
        routine: TeamRoutine(name: 'Secret', drills: [(drillId: first.id, sets: 2)]),
      ),
    ]);
    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    expect(find.text('Secret'), findsNothing);
  });
}
