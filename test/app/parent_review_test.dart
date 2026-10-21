import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {required String activeId}) async {
  SharedPreferences.setMockInitialValues({'activePlayerId': activeId});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      authServiceProvider.overrideWithValue(FakeAuthService(const SignedInAccount(uid: 'existing-user', email: 'pat@example.com', emailVerified: true))),
      testProfilesOverride,
      testTeamsOverride,
      testSessionsOverride,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() async {
    testProfiles.own = null;
    testProfiles.children
      ..clear()
      ..add(const PlayerProfile(id: 'child-1', ownerUid: 'existing-user', displayName: 'Avery H.', birthYear: 2015, isChild: true));
  });

  Future<ProviderContainer> finishOneDrill(WidgetTester tester, String activeId) async {
    final container = await mount(tester, activeId: activeId);
    final notifier = container.read(trainingSessionProvider.notifier);
    final drill = sampleDrills.first;
    notifier.start([drill]);
    for (var i = 0; i < drill.defaultPrescription.sets; i++) {
      notifier.logSet(reps: 5, hits: 4);
    }
    container.read(appRouterProvider).go('/train/session');
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a child\'s finished workout waits for a grown-up, who confirms it before it is saved', (tester) async {
    final container = await finishOneDrill(tester, 'child-1');
    expect(container.read(activePlayerProvider)?.isChild, isTrue);

    await tester.tap(find.text('Hand to a grown-up'));
    await tester.pumpAndSettle();
    expect(find.text('Hand to a grown-up'), findsWidgets);
    expect(find.text('Confirm & save'), findsOneWidget);
    expect(container.read(workoutHistoryProvider), isEmpty);
    expect(container.read(trainingSessionProvider).dismissed, isFalse);

    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    expect(find.text('Review & save'), findsOneWidget);
    await tester.tap(find.text('Review & save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm & save'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).dismissed, isTrue);
    expect(container.read(workoutHistoryProvider), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fix a result opens the editable list without saving', (tester) async {
    final container = await finishOneDrill(tester, 'child-1');
    await tester.tap(find.text('Hand to a grown-up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix a result'));
    await tester.pumpAndSettle();
    expect(find.text('Workout'), findsOneWidget);
    expect(container.read(workoutHistoryProvider), isEmpty);
  });

  testWidgets('an account\'s own player saves straight away, with no grown-up step', (tester) async {
    testProfiles.own = const PlayerProfile(id: 'existing-user', ownerUid: 'existing-user', displayName: 'Pat H.', birthYear: 1985, isChild: false);
    final container = await finishOneDrill(tester, 'existing-user');
    expect(container.read(activePlayerProvider)?.isChild, isFalse);
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect(container.read(workoutHistoryProvider), hasLength(1));
    expect(find.text('Confirm & save'), findsNothing);
  });
}
