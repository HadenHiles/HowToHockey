import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/sessions/session_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
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
  ChildWorkout workout(String id, int seconds, {bool corrected = false}) =>
      ChildWorkout(profileId: 'child-1', id: id, startedAt: DateTime.now().subtract(const Duration(days: 1)), routineName: 'Garage shooting', drillCount: 3, seconds: seconds, corrected: corrected);

  setUp(() {
    testSessions.corrections.clear();
    testSessions.failWith = null;
    testSessions.setRecent('child-1', [workout('w1', 1200), workout('w2', 300, corrected: true)]);
  });

  Future<ProviderContainer> open(WidgetTester tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/parent/kids/child-1/workouts');
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a parent sees the counted workouts, with edited ones marked', (tester) async {
    await open(tester);
    expect(find.textContaining('20 min'), findsOneWidget);
    expect(find.textContaining('5 min · edited'), findsOneWidget);
  });

  testWidgets('Fix time uses big buttons and sends the minutes', (tester) async {
    await open(tester);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('workout-w1')), matching: find.text('Fix time')));
    await tester.pumpAndSettle();
    expect(find.text('20 min'), findsOneWidget);
    await tester.tap(find.text('-10'));
    await tester.tap(find.text('+5'));
    await tester.pumpAndSettle();
    expect(find.text('15 min'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(testSessions.corrections, ['time:w1:15']);
    expect(find.text('Time updated.'), findsOneWidget);
  });

  testWidgets('Remove asks first, and a server error is shown instead of pretending it worked', (tester) async {
    await open(tester);
    final remove = find.descendant(of: find.byKey(const ValueKey('workout-w2')), matching: find.text('Remove'));
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(testSessions.corrections, isEmpty);

    testSessions.failWith = const SessionCorrectionException('Offline. Try again.');
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Offline. Try again.'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-w2')), findsOneWidget);

    testSessions.failWith = null;
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(testSessions.corrections, ['remove:w2']);
    expect(find.byKey(const ValueKey('workout-w2')), findsNothing);
  });
}
