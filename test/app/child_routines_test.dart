import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/routine_state.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/routines/profile_routine_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {String? activeId}) async {
  SharedPreferences.setMockInitialValues({'activePlayerId': ?activeId});
  final preferences = await SharedPreferences.getInstance();
  final profiles = FakeProfileRepository()..own = null;
  profiles.children.add(const PlayerProfile(id: 'child-1', ownerUid: 'parent', displayName: 'Avery H.', birthYear: 2015, isChild: true));
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authServiceProvider.overrideWithValue(FakeAuthService(const SignedInAccount(uid: 'parent', email: 'p@example.com', emailVerified: true))),
      profileRepositoryProvider.overrideWithValue(profiles),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testSessionsOverride,
      testTeamsOverride,
      testProfileRoutinesOverride,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final first = sampleDrills.first;
  final second = sampleDrills[1];

  setUp(() {
    testProfileRoutines.calls.clear();
    testProfileRoutines.failWith = null;
    testProfileRoutines.routines.clear();
  });

  testWidgets('a parent sends a saved routine to a child, sees the cap message, and can delete', (tester) async {
    final container = await mount(tester);
    await container.read(routineLibraryProvider.notifier).save(RoutinePlan(id: 'r1', name: 'Quick hands night', drills: [first, second]));
    await container
        .read(routineLibraryProvider.notifier)
        .save(
          RoutinePlan(
            id: 'r2',
            name: 'Own drills',
            drills: [first.copyWith(id: 'custom-hands-1')],
          ),
        );
    container.read(appRouterProvider).go('/parent/kids/child-1/routines');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing here yet'), findsOneWidget);

    await tester.tap(find.text('Send one of my routines'));
    await tester.pumpAndSettle();
    expect(find.text('Own drills'), findsNothing, reason: 'custom drills can\'t go on a profile');
    await tester.tap(find.byKey(const ValueKey('send-r1')));
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls, ['save:child-1:Quick hands night:${first.id}x${first.defaultPrescription.sets},${second.id}x${second.defaultPrescription.sets}']);
    expect(find.text('Quick hands night'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    testProfileRoutines.failWith = const RoutineException('You can keep up to 3 saved routines. Delete one to save another, or go Pro for unlimited.');
    await tester.tap(find.text('Send one of my routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-r1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('keep up to 3'), findsOneWidget);

    testProfileRoutines.failWith = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Quick hands night'));
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls.last, startsWith('delete:'));
    expect(find.textContaining('Nothing here yet'), findsOneWidget);
  });

  testWidgets('the child sees their grown-up\'s routines on Train and starts one', (tester) async {
    final container = await mount(tester, activeId: 'child-1');
    testProfileRoutines.set('child-1', [
      ProfileRoutine(
        id: 'a',
        routine: TeamRoutine(name: 'Quick hands night', drills: [(drillId: first.id, sets: 2), (drillId: second.id, sets: 3)]),
      ),
    ]);
    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    expect(find.text('From your grown-up'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('grown-up-routine-a')));
    await tester.pumpAndSettle();
    final session = container.read(trainingSessionProvider);
    expect(session.drills.map((d) => d.id), [first.id, second.id]);
    expect(session.drills.map((d) => d.defaultPrescription.sets), [2, 3]);
  });

  testWidgets('an adult player never sees the grown-up card', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    expect(find.text('From your grown-up'), findsNothing);
  });
}
