import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/onboarding_pages.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/coach_state.dart';
import 'package:how_to_hockey/features/coach/outcomes.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

void main() {
  group('outcomes', () {
    test('every skill has exactly one outcome, in words a player would use', () {
      expect(outcomes.map((o) => o.pillar).toSet(), SkillPillar.values.toSet());
      expect(outcomes, hasLength(SkillPillar.values.length));
      expect(outcomes.map((o) => o.label), containsAll(['Harder shot', 'Better accuracy', 'Quicker hands', 'Faster & more explosive']));
    });

    test('an outcome puts 55 of the 100 points on its skill and keeps the others in proportion', () {
      for (final outcome in outcomes) {
        final focus = focusForOutcome(outcome.pillar, defaultTrainingFocus);
        expect(focus.values.fold(0, (a, b) => a + b), 100, reason: outcome.label);
        expect(focus[outcome.pillar], outcomeFocusPoints);
        expect(outcomeFor(focus), outcome);
      }
      final power = focusForOutcome(SkillPillar.shotPower, defaultTrainingFocus);
      expect(power[SkillPillar.shotAccuracy]! > power[SkillPillar.hands]! || power[SkillPillar.shotAccuracy] == power[SkillPillar.hands], isTrue, reason: 'accuracy started above hands');
      expect(power[SkillPillar.speedStrength], power[SkillPillar.endurance], reason: 'those two started equal');
    });

    test('a balanced or hand-tuned mix has no outcome', () {
      expect(outcomeFor(defaultTrainingFocus), isNull);
      expect(outcomeFor({...defaultTrainingFocus, SkillPillar.hands: 50, SkillPillar.shotAccuracy: 0, SkillPillar.shotPower: 15}), isNull);
    });
  });

  group('screens', () {
    Future<ProviderContainer> mount(WidgetTester tester, {Size size = const Size(1000, 3000), double scale = 1, String? start}) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          if (start != null) initialLocationProvider.overrideWithValue(start),
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
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
      await tester.pumpAndSettle();
      return container;
    }

    String path(ProviderContainer container) => container.read(appRouterProvider).routerDelegate.currentConfiguration.last.matchedLocation;

    testWidgets('Train asks what you want to get better at and offers one Start', (tester) async {
      await mount(tester);
      expect(find.text('What do you want to get better at?'), findsOneWidget);
      for (final outcome in outcomes) {
        expect(find.text(outcome.label), findsOneWidget);
      }
      expect(find.text('Start workout'), findsOneWidget);
      expect(find.text('View workout'), findsNothing);
      expect(find.text('Build a workout'), findsNothing, reason: 'setup and routines are optional drill-downs now');
      expect(find.text('Customize'), findsOneWidget);
    });

    testWidgets('choosing an outcome points today\'s workout at it, and choosing it again goes back to balanced', (tester) async {
      final container = await mount(tester);
      await tester.tap(find.text('Harder shot'));
      await tester.pumpAndSettle();
      expect(outcomeFor(container.read(trainingFocusProvider))?.pillar, SkillPillar.shotPower);
      expect(find.textContaining('HARDER SHOT'), findsOneWidget);
      final planned = container.read(generatedRoutineProvider).requireValue.drills;
      expect(planned.any((d) => d.skillWeights.containsKey(SkillPillar.shotPower)), isTrue, reason: 'the workout includes the chosen skill');

      await tester.tap(find.text('Harder shot'));
      await tester.pumpAndSettle();
      expect(container.read(trainingFocusProvider), defaultTrainingFocus);
      expect(find.textContaining('HARDER SHOT'), findsNothing);

      await tester.tap(find.text('Quicker hands'));
      await tester.pumpAndSettle();
      expect(outcomeFor(container.read(trainingFocusProvider))?.pillar, SkillPillar.hands);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Start begins today\'s workout in one tap; once under way the same button resumes it instead of replacing it', (tester) async {
      final container = await mount(tester);
      final planned = container.read(generatedRoutineProvider).requireValue.drills;
      await tester.ensureVisible(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      expect(path(container), '/train/session');
      expect(container.read(trainingSessionProvider).drills.map((d) => d.id), planned.map((d) => d.id));

      final current = container.read(trainingSessionProvider).drill;
      container.read(trainingSessionProvider.notifier).logSet(reps: current.defaultPrescription.reps ?? 10, hits: 5, seconds: current.defaultPrescription.seconds ?? 30, streak: 3, completed: true);
      container.read(appRouterProvider).go('/train');
      await tester.pumpAndSettle();
      expect(find.text('Start workout'), findsNothing);
      await tester.ensureVisible(find.text('Resume workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume workout'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).logs, hasLength(1), reason: 'nothing was thrown away');
      expect(path(container), '/train/session');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the plan and the setup are one tap away but not in the way', (tester) async {
      final container = await mount(tester);
      await tester.ensureVisible(find.text('See the plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See the plan'));
      await tester.pumpAndSettle();
      expect(path(container), '/routine');
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Where you train'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Where you train'));
      await tester.pumpAndSettle();
      expect(path(container), '/setup');
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My routines'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My routines'));
      await tester.pumpAndSettle();
      expect(path(container), '/routines');
    });

    testWidgets('the welcome walkthrough shows player, parent and coach, honestly marking what is coming', (tester) async {
      final container = await mount(tester, start: '/welcome');
      expect(path(container), '/welcome');
      expect(find.text('FOR PLAYERS'), findsOneWidget);
      expect(find.text('Harder shot'), findsOneWidget);
      expect(find.text('Soon'), findsNothing, reason: 'everything promised to players works today');

      await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('FOR PARENTS'), findsOneWidget);
      expect(find.text('Confirm their workouts and fix their training time.'), findsOneWidget);
      expect(find.text('Soon'), findsOneWidget);

      await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('FOR COACHES'), findsOneWidget);
      expect(find.text('Share a routine with your whole team.'), findsOneWidget);
      expect(find.text('Soon'), findsOneWidget);

      for (final way in ['Get started', 'I already have an account', 'Set up a kid\'s device', 'Look around first']) {
        expect(find.text(way), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving the welcome walkthrough remembers it, so it only opens by itself once', (tester) async {
      final container = await mount(tester, start: '/welcome');
      expect(container.read(sharedPreferencesProvider).getBool(welcomeSeenKey), isNull);
      await tester.ensureVisible(find.text('Look around first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Look around first'));
      await tester.pumpAndSettle();
      expect(path(container), '/train');
      expect(container.read(sharedPreferencesProvider).getBool(welcomeSeenKey), isTrue);
    });

    testWidgets('without the first-launch override the app opens on Train', (tester) async {
      final container = await mount(tester);
      expect(path(container), '/train');
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('the welcome walkthrough and Train fit a 320 px phone at ${scale}x text', (tester) async {
        final container = await mount(tester, size: const Size(640, 1136), scale: scale, start: '/welcome');
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        container.read(appRouterProvider).go('/train');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
