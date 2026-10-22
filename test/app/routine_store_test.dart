import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/routine_state.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/routines/profile_routine_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final profiles = FakeProfileRepository()..own = const PlayerProfile(id: 'parent', ownerUid: 'parent', displayName: 'Pat H.', birthYear: 1985, isChild: false);
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

  testWidgets('a signed-in player\'s library routines go to their account, custom-drill ones stay on the device, and the cap counts both', (tester) async {
    final container = await mount(tester);
    final store = container.read(routineStoreProvider);
    container.listen(allRoutinesProvider, (_, _) {});
    await store.save(RoutinePlan(id: 'a', name: 'Hands', drills: [first, second]));
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls.single, startsWith('save:parent:Hands:'));
    expect(container.read(allRoutinesProvider).map((r) => r.name), ['Foundation Builder', 'Hands']);
    expect(container.read(allRoutinesProvider).last.id, startsWith(cloudRoutinePrefix));

    await store.save(
      RoutinePlan(
        id: 'b',
        name: 'My own',
        drills: [first.copyWith(id: 'custom-hands-1')],
      ),
    );
    expect(testProfileRoutines.calls, hasLength(1), reason: 'custom drills stay on this device');
    expect(container.read(routineLibraryProvider).map((r) => r.name), ['Foundation Builder', 'My own']);

    await expectLater(store.save(RoutinePlan(id: 'c', name: 'Fourth', drills: [first])), throwsA(isA<StateError>().having((e) => e.message, 'message', contains('up to 3'))));
    expect(await store.isAtLimit(), isTrue);

    await store.remove(container.read(allRoutinesProvider).firstWhere((r) => r.name == 'Hands').id);
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls.last, startsWith('delete:'));
    await store.save(RoutinePlan(id: 'c', name: 'Fourth', drills: [first]));
    expect(testProfileRoutines.calls.last, startsWith('save:parent:Fourth'));
  });

  testWidgets('a server error on a cloud save surfaces as a normal message', (tester) async {
    final container = await mount(tester);
    container.listen(allRoutinesProvider, (_, _) {});
    testProfileRoutines.failWith = const RoutineException('You can keep up to 3 saved routines. Delete one to save another, or go Pro for unlimited.');
    await expectLater(
      container.read(routineStoreProvider).save(RoutinePlan(id: 'a', name: 'Hands', drills: [first])),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('go Pro'))),
    );
  });

  testWidgets('an adult names a routine freely (40 characters at most) when editing it', (tester) async {
    final container = await mount(tester);
    container.listen(allRoutinesProvider, (_, _) {});
    await container.read(routineStoreProvider).save(RoutinePlan(id: 'a', name: 'Hands', drills: [first, second]));
    await tester.pumpAndSettle();
    final cloudId = container.read(allRoutinesProvider).last.id;
    container.read(appRouterProvider).go('/routines/$cloudId/edit');
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('routine-name'));
    expect(tester.widget<TextField>(field).maxLength, 40);
    await tester.enterText(field, 'Saturday morning hands');
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls.last, startsWith('save:parent:Saturday morning hands:'));
    expect(testProfileRoutines.calls.last, endsWith(':${cloudId.substring(cloudRoutinePrefix.length)}'));

    container.read(appRouterProvider).go('/routines/$cloudId/edit');
    await tester.pumpAndSettle();
    await tester.enterText(field, 'x');
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(find.textContaining('between 2 and 40'), findsOneWidget);
  });

  testWidgets('a parent edits a routine on their child\'s profile', (tester) async {
    final container = await mount(tester);
    testProfileRoutines.set('child-1', [
      ProfileRoutine(
        id: 'k1',
        routine: TeamRoutine(name: 'Quick hands night', drills: [(drillId: first.id, sets: 2), (drillId: second.id, sets: 3)]),
      ),
    ]);
    container.read(appRouterProvider).go('/parent/kids/child-1/routines');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Quick hands night'));
    await tester.pumpAndSettle();
    expect(find.text('Edit routine'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('routine-name')), 'Hands and feet');
    await tester.tap(find.byTooltip('More sets for ${first.title}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(testProfileRoutines.calls.last, 'save:child-1:Hands and feet:${first.id}x3,${second.id}x3:k1');
    expect(find.text('Hands and feet'), findsOneWidget);
  });
}
