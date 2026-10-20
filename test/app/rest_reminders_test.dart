import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/session/rest_notifications.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  testReminders.events.clear();
  testReminders.permissionRequests = 0;
  testReminders.lastScheduledAt = null;
  SharedPreferences.setMockInitialValues({'workoutFocusView': true, ...prefs});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testAuthOverride,
      testProfilesOverride,
      testSessionsOverride,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(640, 1400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<ProviderContainer> startWithRest(WidgetTester tester, {Map<String, Object> prefs = const {}, bool rest = true}) async {
  final container = await mount(tester, prefs: prefs);
  final drill = sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 3));
  await container.read(drillRestSettingsProvider.notifier).configure(drill.id, (enabled: rest, seconds: 60));
  container.read(trainingSessionProvider.notifier).start([drill]);
  container.read(appRouterProvider).go('/train/session');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('the first rest asks for notification permission', (tester) async {
    final container = await startWithRest(tester);
    expect(testReminders.permissionRequests, 0);
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    expect(testReminders.permissionRequests, 1);
  });

  testWidgets('no permission prompt without a rest or when reminders are off', (tester) async {
    final noRest = await startWithRest(tester, rest: false);
    noRest.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    expect(testReminders.permissionRequests, 0);

    final off = await startWithRest(tester, prefs: {RestRemindersEnabled.storageKey: false});
    off.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    expect(testReminders.permissionRequests, 0);
  });

  testWidgets('leaving the app during a rest schedules a reminder for the moment it ends, and returning cancels it', (tester) async {
    final container = await startWithRest(tester);
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    final deadline = container.read(trainingSessionProvider).restEndsAt!;
    testReminders.events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(testReminders.events, ['schedule']);
    expect(testReminders.lastScheduledAt, deadline);
    expect(testReminders.lastBody, 'Time for your next set of Quick-release wrist shots.');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(testReminders.events, ['schedule', 'cancel']);
  });

  testWidgets('nothing is scheduled with no rest, a finished rest, or reminders off', (tester) async {
    final noRest = await startWithRest(tester, rest: false);
    noRest.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    testReminders.events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(testReminders.events, isNot(contains('schedule')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    final expired = await startWithRest(tester);
    expired.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump(const Duration(seconds: 90));
    testReminders.events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(testReminders.events, isNot(contains('schedule')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    final off = await startWithRest(tester, prefs: {RestRemindersEnabled.storageKey: false});
    off.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    testReminders.events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(testReminders.events, isNot(contains('schedule')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('the rest chime stays quiet while the app is in the background', (tester) async {
    final container = await startWithRest(tester);
    testCues.events.clear();
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 65));
    expect(testCues.events, isNot(contains('rest')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('a skipped rest leaves nothing to schedule', (tester) async {
    final container = await startWithRest(tester);
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    container.read(trainingSessionProvider.notifier).skipRest();
    await tester.pump();
    testReminders.events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(testReminders.events, isNot(contains('schedule')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('Me has a Rest reminders switch that turns reminders off', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rest reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rest reminders'));
    await tester.pumpAndSettle();
    expect(container.read(restRemindersEnabledProvider), isFalse);
  });

  test('rest reminders default to on and the choice is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);
    expect(container.read(restRemindersEnabledProvider), isTrue);
    await container.read(restRemindersEnabledProvider.notifier).set(false);
    final next = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(next.dispose);
    expect(next.read(restRemindersEnabledProvider), isFalse);
  });

  test('the permission prompt is only ever shown once', () async {
    SharedPreferences.setMockInitialValues({DeviceRestNotifications.askedKey: true});
    final preferences = await SharedPreferences.getInstance();
    // With the flag set it returns before touching any platform plugin.
    await DeviceRestNotifications(preferences: preferences).ensurePermission();
    // Reaching here without a platform error is the check.
  });
}
