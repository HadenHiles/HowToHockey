import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/session/session_cues.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(640, 1400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> revealDrill(WidgetTester tester) async {
  final scroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(scroll).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> startTimedSession(WidgetTester tester, {int seconds = 5}) async {
  testCues.events.clear();
  final container = await mount(tester);
  final timed = sampleDrills.firstWhere((drill) => drill.trackingType == TrackingType.duration);
  container.read(trainingSessionProvider.notifier).start([timed.copyWith(defaultPrescription: timed.defaultPrescription.copyWith(seconds: seconds, sets: 2))]);
  container.read(appRouterProvider).go('/train/session');
  await tester.pumpAndSettle();
  await revealDrill(tester);
  await tester.ensureVisible(find.text('Start timer'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a timed set counts 3-2-1, starts, and finishes with a cue at each step', (tester) async {
    await startTimedSession(tester);
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Get ready'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(testCues.events, ['tick3']);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1, milliseconds: 100));
    expect(testCues.events, ['tick3', 'tick2', 'tick1', 'start']);
    expect(find.text('seconds remaining'), findsOneWidget);
    expect(find.text('Pause timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(testCues.events.last, 'stop');
    expect(testCues.events.where((e) => e == 'stop'), hasLength(1));
    expect(find.text('Set complete'), findsOneWidget);
    expect(find.text('Start timer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the lead-in returns to a fresh timer without starting the set', (tester) async {
    await startTimedSession(tester);
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Start timer'), findsOneWidget);
    expect(testCues.events, ['tick3', 'tick2']);
    expect(find.text('0:05'), findsOneWidget);
  });

  testWidgets('pause and resume keep the time and do not replay the lead-in', (tester) async {
    await startTimedSession(tester, seconds: 20);
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 3, milliseconds: 500));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Pause timer'));
    await tester.pump();
    final remaining = find.textContaining(RegExp(r'^0:1[3-5]$'));
    expect(remaining, findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(remaining, findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    testCues.events.clear();
    await tester.tap(find.text('Resume timer'));
    await tester.pump(const Duration(seconds: 2));
    expect(testCues.events, isEmpty);
    expect(find.text('Pause timer'), findsOneWidget);
    // Stop the periodic timer before the test ends.
    await tester.tap(find.text('Pause timer'));
    await tester.pump();
  });

  testWidgets('a rest that runs out chimes, but skipping it stays quiet', (tester) async {
    testCues.events.clear();
    final container = await mount(tester);
    final drill = sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 3));
    await container.read(drillRestSettingsProvider.notifier).configure(drill.id, (enabled: true, seconds: 15));
    container.read(trainingSessionProvider.notifier).start([drill]);
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    container.read(appRouterProvider).go('/train/session');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 14));
    expect(testCues.events, isEmpty);
    await tester.pump(const Duration(seconds: 3));
    expect(testCues.events, ['rest']);

    testCues.events.clear();
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    await tester.pump(const Duration(seconds: 1));
    container.read(trainingSessionProvider.notifier).skipRest();
    await tester.pump(const Duration(seconds: 6));
    expect(testCues.events, isEmpty);
  });

  test('workout sounds default to on and the choice is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);
    expect(container.read(workoutCuesEnabledProvider), isTrue);
    await container.read(workoutCuesEnabledProvider.notifier).set(false);
    expect(container.read(workoutCuesEnabledProvider), isFalse);

    final next = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(next.dispose);
    expect(next.read(workoutCuesEnabledProvider), isFalse);
  });

  testWidgets('Me has a Sounds and haptics switch that turns cues off', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sounds and haptics'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
    await tester.tap(find.text('Sounds and haptics'));
    await tester.pumpAndSettle();
    expect(container.read(workoutCuesEnabledProvider), isFalse);
  });

  test('the workout audio session mixes with music and follows the silent switch on both platforms', () {
    expect(workoutAudioContext, returnsNormally);
    final context = workoutAudioContext();
    expect(context.iOS.category, AVAudioSessionCategory.ambient);
    expect(context.android.audioFocus, AndroidAudioFocus.none);
  });
}
