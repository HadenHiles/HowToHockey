import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/coach_state.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/routine_state.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<(ProviderContainer, SharedPreferences)> mount(WidgetTester tester, {Map<String, Object> saved = const {}, bool emptyCatalog = false}) async {
  SharedPreferences.setMockInitialValues(saved);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      emptyCatalog ? drillCatalogProvider.overrideWithValue(const AsyncData(<Drill>[])) : testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testAuthOverride,
      testProfilesOverride,
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
  return (container, preferences);
}

ProviderContainer plain(SharedPreferences preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('remembered setup', () {
    test('setup, focus and length survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = plain(preferences);
      first.read(trainingSetupProvider.notifier)
        ..selectLocation(LocationOption.basement)
        ..selectInventory(PuckInventory.high)
        ..selectBall(BallType.golfBall)
        ..selectPasser(PasserType.rebounder);
      first.read(trainingFocusProvider.notifier).select(SkillPillar.hands, 60);
      first.read(trainingLengthProvider.notifier).select(45);

      final second = plain(preferences);
      expect(second.read(trainingSetupProvider), (location: LocationOption.basement, inventory: PuckInventory.high, ball: BallType.golfBall, passer: PasserType.rebounder));
      expect(second.read(trainingFocusProvider), first.read(trainingFocusProvider));
      expect(second.read(trainingFocusProvider)[SkillPillar.hands], 60);
      expect(second.read(trainingLengthProvider), 45);
    });

    test('damaged saved values fall back to safe defaults', () async {
      SharedPreferences.setMockInitialValues({'trainingSetup': 'not json', 'trainingFocus': '{"hands": 50}', 'trainingMinutes': 7, 'setupPresets': '[1, {"id": 3}]'});
      final container = plain(await SharedPreferences.getInstance());
      expect(container.read(trainingSetupProvider), defaultTrainingSetup);
      expect(container.read(trainingFocusProvider), defaultTrainingFocus);
      expect(container.read(trainingLengthProvider), 20);
      expect(container.read(setupPresetsProvider), isEmpty);
      expect(() => container.read(trainingLengthProvider.notifier).select(7), throwsRangeError);
    });
  });

  group('saved setups', () {
    test('save, apply, replace by name, limit and remove', () async {
      SharedPreferences.setMockInitialValues({});
      final container = plain(await SharedPreferences.getInstance());
      final presets = container.read(setupPresetsProvider.notifier);
      container.read(trainingSetupProvider.notifier).selectLocation(LocationOption.ice);
      container.read(trainingLengthProvider.notifier).select(30);
      expect(presets.save('Rink Tuesday'), isNull);

      container.read(trainingSetupProvider.notifier).selectLocation(LocationOption.basement);
      container.read(trainingLengthProvider.notifier).select(15);
      expect(presets.save('  rink   tuesday '), isNull, reason: 'same name replaces');
      expect(container.read(setupPresetsProvider), hasLength(1));
      expect(container.read(setupPresetsProvider).single.setup.location, LocationOption.basement);

      container.read(trainingSetupProvider.notifier).selectLocation(LocationOption.roller);
      presets.apply(container.read(setupPresetsProvider).single);
      expect(container.read(trainingSetupProvider).location, LocationOption.basement);
      expect(container.read(trainingLengthProvider), 15);

      expect(presets.save(''), isNotNull);
      expect(presets.save('x' * (maxPresetNameLength + 1)), isNotNull);
      for (var i = 1; i < maxSetupPresets; i++) {
        expect(presets.save('Spot $i'), isNull);
      }
      expect(presets.save('One too many'), contains('up to $maxSetupPresets'));
      presets.remove(container.read(setupPresetsProvider).first.id);
      expect(presets.save('One too many'), isNull);

      final again = plain(await SharedPreferences.getInstance());
      expect(again.read(setupPresetsProvider).map((p) => p.name), container.read(setupPresetsProvider).map((p) => p.name));
    });
  });

  group('today\'s workout', () {
    test('is built from the setup, stays the same until asked for another, and changes with focus', () async {
      SharedPreferences.setMockInitialValues({});
      final container = plain(await SharedPreferences.getInstance());
      List<String> ids() => [for (final d in container.read(generatedRoutineProvider).requireValue.drills) d.id];

      final first = ids();
      expect(first, isNotEmpty);
      expect(ids(), first);

      container.read(trainingFocusProvider.notifier).select(SkillPillar.hands, 70);
      expect(ids().where((id) => id.contains('stickhandling') || id.contains('toe-drag') || id.contains('quiet-hands') || id.contains('ball-bounce')).length, greaterThanOrEqualTo(2));

      container.read(trainingLengthProvider.notifier).select(45);
      final long = container.read(generatedRoutineProvider).requireValue;
      container.read(trainingLengthProvider.notifier).select(15);
      expect(long.drills.length, greaterThan(container.read(generatedRoutineProvider).requireValue.drills.length));

      container.read(trainingFocusProvider.notifier).apply(defaultTrainingFocus);
      container.read(trainingLengthProvider.notifier).select(30);
      final seen = {ids().join(',')};
      for (var i = 0; i < 6; i++) {
        container.read(routineShuffleProvider.notifier).next(ids());
        seen.add(ids().join(','));
      }
      expect(seen.length, greaterThan(1));
    });

    test('titles follow the biggest focus, or say balanced', () {
      expect(routineTitle(defaultTrainingFocus), 'A balanced\nworkout');
      expect(
        routineTitle({
          ...defaultTrainingFocus,
          SkillPillar.passing: 60,
          SkillPillar.hands: 0,
          SkillPillar.shotAccuracy: 0,
          SkillPillar.shotPower: 15,
          SkillPillar.speedStrength: 15,
          SkillPillar.endurance: 10,
        }),
        contains('focus'),
      );
      expect(topPillar({for (final p in SkillPillar.values) p: p == SkillPillar.endurance ? 100 : 0}), SkillPillar.endurance);
    });
  });

  group('screens', () {
    testWidgets('the workout page shows the generated plan and starts exactly that workout', (tester) async {
      final (container, _) = await mount(tester);
      container.read(appRouterProvider).go('/routine');
      await tester.pumpAndSettle();
      final routine = container.read(generatedRoutineProvider).requireValue;
      expect(find.text('Start workout'), findsOneWidget);
      expect(find.text('${routine.drills.length}'.padLeft(2, '0')), findsOneWidget);
      expect(find.text(routine.drills.first.title), findsWidgets);

      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).drills.map((d) => d.id), routine.drills.map((d) => d.id));
    });

    testWidgets('Try another changes the workout', (tester) async {
      final (container, _) = await mount(tester);
      container.read(trainingLengthProvider.notifier).select(45);
      container.read(appRouterProvider).go('/routine');
      await tester.pumpAndSettle();
      final seen = <String>{container.read(generatedRoutineProvider).requireValue.drills.map((d) => d.id).join(',')};
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Try another'));
        await tester.pumpAndSettle();
        seen.add(container.read(generatedRoutineProvider).requireValue.drills.map((d) => d.id).join(','));
      }
      expect(seen.length, greaterThan(1));
    });

    testWidgets('a setup nothing fits says so and offers the setup screen', (tester) async {
      final (container, _) = await mount(tester, emptyCatalog: true);
      container.read(appRouterProvider).go('/routine');
      await tester.pumpAndSettle();
      expect(find.text('Start workout'), findsNothing);
      expect(find.textContaining('No drills fit this setup yet'), findsOneWidget);
      await tester.tap(find.text('Change my setup'));
      await tester.pumpAndSettle();
      expect(find.text('Where are you training?'), findsOneWidget);
    });

    testWidgets('saving a workout keeps it, and at three it asks which to replace', (tester) async {
      final (container, _) = await mount(tester);
      container.read(appRouterProvider).go('/routine');
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider), hasLength(1));

      await tester.tap(find.text('Save workout'));
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider), hasLength(2));
      expect(find.textContaining('to My routines'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try another'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save workout'));
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider), hasLength(3));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save workout'));
      await tester.pumpAndSettle();
      expect(find.text('Replace a saved routine?'), findsOneWidget);
      await tester.tap(find.text('Foundation Builder'));
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider), hasLength(3));
      expect(container.read(routineLibraryProvider).map((r) => r.name), isNot(contains('Foundation Builder')));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider), hasLength(3));
    });

    testWidgets('the setup screen picks a length, saves a named setup and applies it again', (tester) async {
      final (container, preferences) = await mount(tester);
      container.read(appRouterProvider).go('/setup');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('45 min'));
      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
      expect(container.read(trainingLengthProvider), 45);
      expect(preferences.getInt('trainingMinutes'), 45);

      await tester.ensureVisible(find.text('Basement'));
      await tester.tap(find.text('Basement'));
      await tester.ensureVisible(find.text('Save this setup'));
      await tester.tap(find.text('Save this setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Give this setup a name.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save this setup'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Basement 45');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Basement 45'), findsOneWidget);

      container.read(trainingLengthProvider.notifier).select(15);
      container.read(trainingSetupProvider.notifier).selectLocation(LocationOption.roller);
      await tester.tap(find.text('Basement 45'));
      await tester.pumpAndSettle();
      expect(container.read(trainingLengthProvider), 45);
      expect(container.read(trainingSetupProvider).location, LocationOption.basement);
    });

    testWidgets('the Train tab shows today\'s generated workout', (tester) async {
      final (container, _) = await mount(tester);
      final routine = container.read(generatedRoutineProvider).requireValue;
      expect(find.text('View workout'), findsOneWidget);
      expect(find.text('${routine.estimatedMinutes}'), findsWidgets);
    });
  });
}
