import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/drill_swap.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

final catalog = parseDrillCatalog(File(drillCatalogAsset).readAsStringSync());
Drill drill(String id) => catalog.firstWhere((d) => d.id == id);
List<String> ids(List<Drill> drills) => drills.map((d) => d.id).toList()..sort();

void main() {
  group('swap candidates', () {
    const driveway = (location: LocationOption.drivewayGarage, inventory: PuckInventory.low, ball: null as BallType?, passer: PasserType.partner as PasserType?);

    test('only same-group drills that fit today\'s setup are offered', () {
      final options = swapCandidates(current: drill('pick-your-corner'), catalog: catalog, alreadyInWorkout: const ['pick-your-corner'], setup: driveway);
      // Shoot the tarp needs a medium puck supply.
      expect(ids(options), ['bottom-shelf-snaps', 'top-shelf-lifts']);
    });

    test('a bigger puck supply unlocks more swaps, and a basement removes outdoor-only drills', () {
      final bigger = (location: LocationOption.drivewayGarage, inventory: PuckInventory.medium, ball: null as BallType?, passer: PasserType.partner as PasserType?);
      expect(ids(swapCandidates(current: drill('pick-your-corner'), catalog: catalog, alreadyInWorkout: const [], setup: bigger)), contains('shoot-the-tarp'));

      final basement = (location: LocationOption.basement, inventory: PuckInventory.high, ball: null as BallType?, passer: null as PasserType?);
      expect(ids(swapCandidates(current: drill('pick-your-corner'), catalog: catalog, alreadyInWorkout: const [], setup: basement)), ['bottom-shelf-snaps']);
    });

    test('drills already in the workout are excluded', () {
      final options = swapCandidates(current: drill('pick-your-corner'), catalog: catalog, alreadyInWorkout: const ['pick-your-corner', 'bottom-shelf-snaps'], setup: driveway);
      expect(ids(options), ['top-shelf-lifts']);
    });

    test('the ball choice limits swaps, but drills that need no ball always fit', () {
      final golf = (location: LocationOption.drivewayGarage, inventory: PuckInventory.high, ball: BallType.golfBall as BallType?, passer: null as PasserType?);
      expect(ids(swapCandidates(current: drill('pick-your-corner'), catalog: catalog, alreadyInWorkout: const [], setup: golf)), isNot(contains('top-shelf-lifts')));
      expect(ids(swapCandidates(current: drill('squat-jumps'), catalog: catalog, alreadyInWorkout: const [], setup: golf)), contains('athletic-stance-reset'));
    });

    test('passer drills need a matching passer', () {
      final alone = (location: LocationOption.drivewayGarage, inventory: PuckInventory.high, ball: null as BallType?, passer: null as PasserType?);
      expect(ids(swapCandidates(current: drill('target-saucer-passes'), catalog: catalog, alreadyInWorkout: const [], setup: alone)), isEmpty);
      expect(ids(swapCandidates(current: drill('target-saucer-passes'), catalog: catalog, alreadyInWorkout: const [], setup: driveway)), containsAll(['pass-and-settle', 'backhand-passes']));
    });

    test('a drill with no swap group has no swaps', () {
      expect(swapCandidates(current: drill('one-timer-reps'), catalog: catalog, alreadyInWorkout: const [], setup: driveway), isEmpty);
    });
  });

  group('session actions', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride, testRemindersOverride, testAuthOverride, testProfilesOverride],
      );
      addTearDown(container.dispose);
    });

    TrainingSessionNotifier notifier() => container.read(trainingSessionProvider.notifier);

    test('swapping replaces only an untouched drill and keeps everything else', () {
      notifier().start([drill('pick-your-corner'), drill('toe-drag-reps')]);
      notifier().swapDrill(0, drill('bottom-shelf-snaps'));
      final session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), ['bottom-shelf-snaps', 'toe-drag-reps']);
      expect(session.startedAt, isNotNull);
    });

    test('a drill with logged sets, a duplicate, or a bad index cannot be swapped', () {
      notifier().start([drill('pick-your-corner'), drill('toe-drag-reps')]);
      notifier().logSet(reps: 10, hits: 6);
      expect(() => notifier().swapDrill(0, drill('bottom-shelf-snaps')), throwsStateError);
      expect(() => notifier().swapDrill(1, drill('pick-your-corner')), throwsArgumentError);
      expect(() => notifier().swapDrill(5, drill('bottom-shelf-snaps')), throwsRangeError);
      expect(container.read(trainingSessionProvider).drills.map((d) => d.id), ['pick-your-corner', 'toe-drag-reps']);
    });

    test('starting a rest sets the countdown, and rejects bad lengths or a finished workout', () {
      notifier().start([drill('pick-your-corner'), drill('toe-drag-reps')]);
      notifier().startRest(45);
      final remaining = container.read(trainingSessionProvider).restEndsAt!.difference(DateTime.now().toUtc()).inSeconds;
      expect(remaining, inInclusiveRange(43, 45));
      expect(() => notifier().startRest(5), throwsRangeError);
      expect(() => notifier().startRest(601), throwsRangeError);

      final tiny = drill('toe-drag-reps').copyWith(defaultPrescription: drill('toe-drag-reps').defaultPrescription.copyWith(sets: 1));
      notifier().start([tiny]);
      notifier().logSet(reps: 5);
      expect(() => notifier().startRest(30), throwsStateError);
    });
  });

  group('screens', () {
    Future<ProviderContainer> mount(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride, testRemindersOverride, testAuthOverride, testProfilesOverride],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('Swap drill offers fitting drills and swaps the chosen one in', (tester) async {
      final container = await mount(tester);
      container.read(trainingSessionProvider.notifier).start([drill('pick-your-corner'), drill('toe-drag-reps')]);
      container.read(appRouterProvider).go('/train/session');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Swap drill'));
      await tester.pumpAndSettle();
      expect(find.text('Bottom-shelf snap shots'), findsOneWidget);
      expect(find.text('Top-shelf lifts'), findsOneWidget);
      expect(find.text('Shoot the tarp'), findsNothing);

      await tester.tap(find.text('Top-shelf lifts'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).drills.first.id, 'top-shelf-lifts');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Swap drill explains when nothing else fits and disappears once sets are logged', (tester) async {
      final container = await mount(tester);
      container.read(trainingSessionProvider.notifier).start([drill('one-timer-reps'), drill('toe-drag-reps')]);
      container.read(appRouterProvider).go('/train/session');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap drill'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No other drills fit your setup'), findsOneWidget);
      Navigator.of(tester.element(find.text('Swap drill').last)).pop();
      await tester.pumpAndSettle();

      container.read(trainingSessionProvider.notifier).logSet(reps: 8);
      await tester.pumpAndSettle();
      expect(find.text('Swap drill'), findsNothing);
    });

    testWidgets('Start rest begins a countdown you can skip', (tester) async {
      final container = await mount(tester);
      container.read(trainingSessionProvider.notifier).start([drill('toe-drag-reps')]);
      container.read(appRouterProvider).go('/train/session');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start rest'));
      await tester.pump();
      expect(container.read(trainingSessionProvider).restEndsAt, isNotNull);
      expect(find.textContaining('Rest 0:'), findsOneWidget);
      expect(tester.widget<TextButton>(find.ancestor(of: find.text('Start rest'), matching: find.byType(TextButton))).onPressed, isNull);

      await tester.tap(find.text('Skip rest'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).restEndsAt, isNull);
      expect(find.text('Start rest'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('the workout actions fit a 320 px phone at ${scale}x text', (tester) async {
        final container = await mount(tester);
        tester.view.physicalSize = const Size(640, 1136);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        container.read(trainingSessionProvider.notifier).start([drill('pick-your-corner'), drill('quiet-hands-quick-feet')]);
        container.read(appRouterProvider).go('/train/session');
        await tester.pumpAndSettle();
        final scroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
        final position = tester.state<ScrollableState>(scroll).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(find.text('Swap drill'), findsOneWidget);
        expect(find.text('Start rest'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
