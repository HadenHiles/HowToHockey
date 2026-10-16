import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {double scale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride, testRemindersOverride]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Train opens the Shot logger and Timer screens', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/train');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Shot logger'));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Shot logger'));
    expect(find.text('Shots taken'), findsOneWidget);
    expect(find.text('Log shots'), findsOneWidget);
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Timer'));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Timer'));
    expect(find.text('Start 1 min timer'), findsOneWidget);
  });

  testWidgets('logging shots goes straight to a summary with the count', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/log/shots');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed, isNull, reason: 'nothing to log yet');
    await tap(tester, find.text('+50'));
    await tap(tester, find.text('+10'));
    await tap(tester, find.byTooltip('One more'));
    expect(find.text('61'), findsOneWidget);
    expect(find.text('Log 61 shots'), findsOneWidget);

    await tap(tester, find.text('Log 61 shots'));
    final session = container.read(trainingSessionProvider);
    expect(session.drills.single.title, 'Shot logger');
    expect(session.logs.single.log.reps, 61);
    expect(session.dismissed, isTrue);
    expect(find.text('Shots logged'), findsOneWidget);
    expect(find.text('61 reps in 1 set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking hits adds accuracy and never lets hits exceed shots', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/log/shots');
    await tester.pumpAndSettle();
    await tap(tester, find.text('+25'));
    await tap(tester, find.text('Track hits too'));
    expect(find.text('Hits'), findsOneWidget);

    // Type 18 hits through the number dialog.
    await tap(tester, find.bySemanticsLabel(RegExp('Hits: 0')));
    await tester.enterText(find.byType(TextField), '18');
    await tap(tester, find.text('Done'));
    expect(find.text('18'), findsOneWidget);

    // Dropping shots below hits pulls hits down with it.
    await tap(tester, find.bySemanticsLabel(RegExp('Shots taken: 25')));
    await tester.enterText(find.byType(TextField), '10');
    await tap(tester, find.text('Done'));
    expect(find.text('Log 10 shots'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel(RegExp('Hits: 10')));
    await tester.enterText(find.byType(TextField), '9999');
    await tap(tester, find.text('Done'));
    expect(find.bySemanticsLabel(RegExp('Hits: 10')), findsOneWidget, reason: 'hits are capped at the shots taken');

    await tap(tester, find.text('Log 10 shots'));
    final log = container.read(trainingSessionProvider).logs.single.log;
    expect((log.reps, log.hits), (10, 10));
    expect(find.text('10 / 10 hits · 100% accuracy'), findsOneWidget);
  });

  testWidgets('the shot count only accepts digits and stays within its limit', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/log/shots');
    await tester.pumpAndSettle();
    await tap(tester, find.bySemanticsLabel(RegExp('Shots taken: 0')));
    await tester.enterText(find.byType(TextField), '12ab');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '12');
    await tap(tester, find.text('Cancel'));
    expect(find.text('Log shots'), findsOneWidget, reason: 'cancelling changes nothing');
  });

  testWidgets('the timer starts a one-set timed session with the chosen length', (tester) async {
    final container = await mount(tester);
    container.read(appRouterProvider).go('/log/timer');
    await tester.pumpAndSettle();
    await tap(tester, find.text('5 min'));
    expect(find.text('Start 5 min timer'), findsOneWidget);
    await tap(tester, find.text('Start 5 min timer'));

    final session = container.read(trainingSessionProvider);
    expect(session.drills.single.id, 'manual-timer');
    expect(session.drills.single.defaultPrescription.seconds, 300);
    expect(session.drills.single.defaultPrescription.sets, 1);
    expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/train/session');
  });

  testWidgets('starting a manual log asks before ending a workout in progress', (tester) async {
    final container = await mount(tester);
    container.read(trainingSessionProvider.notifier).start([sampleDrills.first]);
    container.read(trainingSessionProvider.notifier).logSet(reps: 10);
    container.read(appRouterProvider).go('/log/timer');
    await tester.pumpAndSettle();

    await tap(tester, find.text('Start 1 min timer'));
    expect(find.text('End your current workout?'), findsOneWidget);
    await tap(tester, find.text('Keep workout'));
    expect(container.read(trainingSessionProvider).drills.single.id, sampleDrills.first.id);
    expect(container.read(trainingSessionProvider).logs, hasLength(1));

    await tap(tester, find.text('Start 1 min timer'));
    await tap(tester, find.text('End it'));
    expect(container.read(trainingSessionProvider).drills.single.id, 'manual-timer');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('both screens fit a small phone at ${scale}x text', (tester) async {
      final container = await mount(tester, scale: scale);
      tester.view.physicalSize = const Size(640, 1136);
      for (final route in ['/log/shots', '/log/timer']) {
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }

  test('manual drills are valid one-set drills', () {
    final drill = Drill(
      id: 'x',
      title: 'x',
      mediaAssetPath: 'placeholder/x',
      formCues: const ['x'],
      trackingType: TrackingType.volume,
      allowedLocations: LocationOption.values,
      minPuckInventory: PuckInventory.low,
      requiresPasser: false,
      skillWeights: const {SkillPillar.endurance: 1},
      tier: AccessTier.free,
      supportedBalls: const [],
      passerTypes: const [],
      defaultPrescription: const DrillPrescription(sets: 1),
      estimatedSecondsPerSet: 30,
      difficulty: 1,
      tags: const ['manual'],
    );
    expect(drill.skillWeights.values.single, 1);
  });
}
