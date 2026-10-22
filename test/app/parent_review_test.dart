import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/parent_review_page.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/app/workout_sync.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/sessions/session_repository.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {required String activeId, AuthState? auth}) async {
  SharedPreferences.setMockInitialValues({'activePlayerId': activeId});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      authServiceProvider.overrideWithValue(FakeAuthService(auth ?? const SignedInAccount(uid: 'existing-user', email: 'pat@example.com', emailVerified: true))),
      testProfilesOverride,
      testTeamsOverride,
      testSessionsOverride,
      testProfileRoutinesOverride,
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

  Future<ProviderContainer> finishOneDrill(WidgetTester tester, String activeId, {AuthState? auth}) async {
    final container = await mount(tester, activeId: activeId, auth: auth);
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

  testWidgets('a child\'s own device sends the workout to a grown-up instead of saving it', (tester) async {
    testSessions.pendingUploads.clear();
    testProfiles.own = const PlayerProfile(id: 'child-1', ownerUid: 'existing-user', displayName: 'Avery H.', birthYear: 2015, isChild: true);
    final container = await finishOneDrill(tester, 'child-1', auth: const KidDeviceSession('child-1'));
    expect(container.read(needsParentConfirmationProvider), isFalse);
    expect(find.text('Hand to a grown-up'), findsNothing);
    await tester.tap(find.text('Send to a grown-up'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Waiting for a grown-up'), findsOneWidget);
    final id = container.read(workoutSyncProvider).keys.single;
    expect(container.read(workoutSyncProvider)[id]!.pending, isTrue);
    expect(testSessions.pendingUploads, [id]);
    expect(find.text('Confirm & save'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('a grown-up reviewing a workout sent from a child\'s device', () {
    final sent = PendingWorkout(profileId: 'child-1', id: 'w1', routineName: 'Garage shooting', startedAt: DateTime.utc(2026, 10, 20, 15), drillCount: 1, activeSeconds: 600);

    Future<ProviderContainer> openQueue(WidgetTester tester) async {
      testSessions.reviewed.clear();
      testSessions.setPending('child-1', [sent]);
      testSessions.pendingDrills
        ..clear()
        ..add(
          PendingDrill(
            title: 'Pick your corner',
            trackingType: TrackingType.accuracy,
            sets: [SetLog(setIndex: 0, reps: 10, hits: 7, loggedAt: DateTime.utc(2026, 10, 20, 15))],
          ),
        );
      final container = await mount(tester, activeId: 'existing-user');
      container.read(appRouterProvider).go('/train');
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('sees the queue on Train, checks the results and confirms', (tester) async {
      await openQueue(tester);
      expect(find.text('Waiting for you'), findsOneWidget);
      expect(find.text('Avery H. finished a workout'), findsOneWidget);
      await tester.tap(find.text('Avery H. finished a workout'));
      await tester.pumpAndSettle();
      expect(find.text('Pick your corner'), findsOneWidget);
      expect(find.text('Set 1 · 7 / 10 hits · 70%'), findsOneWidget);
      await tester.tap(find.text('Confirm & save'));
      await tester.pumpAndSettle();
      expect(testSessions.reviewed, ['confirm:w1']);
      expect(find.text('Waiting for you'), findsNothing);
    });

    testWidgets('can discard it', (tester) async {
      await openQueue(tester);
      await tester.tap(find.text('Avery H. finished a workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard this workout'));
      await tester.pumpAndSettle();
      expect(testSessions.reviewed, ['discard:w1']);
      expect(find.text('Waiting for you'), findsNothing);
    });
  });
}
