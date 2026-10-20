import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/progress_state.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/design/components/training_components.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

final catalog = {for (final d in parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())) d.id: d};
final now = DateTime(2026, 10, 20, 12);

TrainingSession workout(DateTime at, List<(String, SetLog Function(DateTime))> sets) {
  final drills = [
    for (final id in {for (final s in sets) s.$1}) catalog[id]!.copyWith(defaultPrescription: catalog[id]!.defaultPrescription.copyWith(sets: 1)),
  ];
  return TrainingSession(drills: drills, startedAt: at.toUtc(), endedAt: at.toUtc().add(const Duration(minutes: 10)), logs: [for (final s in sets) (drillId: s.$1, log: s.$2(at.toUtc()))]);
}

SetLog Function(DateTime) shots(int reps, int hits) =>
    (at) => SetLog(setIndex: 0, reps: reps, hits: hits, loggedAt: at);

Future<ProviderContainer> mount(WidgetTester tester, {Map<String, Object> saved = const {}, bool pro = false}) async {
  SharedPreferences.setMockInitialValues(saved);
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
      if (pro) drillFiltersUnlockedProvider.overrideWithValue(true),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a new player sees an honest, empty Progress and a streakless Train', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester);
      expect(find.text('No streak yet'), findsOneWidget);
      expect(find.text('Train today to start one.'), findsOneWidget);
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      expect(find.text('Finish a workout and your progress starts here.'), findsOneWidget);
      expect(find.text('SHOTS LOGGED'), findsOneWidget);
      expect(find.text('0 shots this week  ·  0 min active'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(find.byType(SkillRadar), findsOneWidget, reason: 'blurred behind the unlock prompt');
      expect(find.text('Unlock with Player Pro'), findsNWidgets(3));
    });
  });

  testWidgets('finishing workouts feeds Train, Progress and the summary', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester, pro: true);
      final history = container.read(workoutHistoryProvider.notifier);
      history.add(workout(now.subtract(const Duration(days: 1)), [('pick-your-corner', shots(10, 6))]));
      history.add(workout(now, [('pick-your-corner', shots(20, 18)), ('ball-bounce-streak', (at) => SetLog(setIndex: 0, streak: 25, loggedAt: at))]));

      await tester.pumpAndSettle();
      expect(find.text('2-day streak'), findsOneWidget);
      expect(find.text('Keep grinding.'), findsOneWidget);

      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      expect(find.text('30'), findsWidgets, reason: 'all-time shots');
      expect(find.text('2 days'), findsWidgets);
      expect(find.text('Unlock with Player Pro'), findsNothing);
      expect(find.text('Accuracy · Lv 0'), findsOneWidget);
      await tester.ensureVisible(find.text('90%').first);
      expect(find.text('90%'), findsWidgets, reason: 'best accuracy, 18 of 20');
      expect(find.text('25'), findsWidgets, reason: 'best streak');

      await tester.ensureVisible(find.text('Accuracy · Lv 0'));
      await tester.tap(find.text('Accuracy · Lv 0'));
      await tester.pumpAndSettle();
      expect(find.text('Top drills lately'), findsOneWidget);
      expect(find.textContaining('Pick your corner'), findsWidgets);
      expect(find.textContaining('to level 1'), findsOneWidget);
    });
  });

  testWidgets('the summary of a workout that sets a best says so', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester);
      final first = workout(now.subtract(const Duration(days: 2)), [('pick-your-corner', shots(10, 5))]);
      container.read(workoutHistoryProvider.notifier).add(first);
      final second = workout(now, [('pick-your-corner', shots(10, 9))]);

      expect([for (final b in bestsSetBy(container.read(lifetimeStatsProvider), second)) b.valueLabel], ['90%'], reason: 'before saving, compare against what is recorded');
      container.read(workoutHistoryProvider.notifier).add(second);
      expect([for (final b in bestsSetBy(container.read(lifetimeStatsProvider), second)) b.valueLabel], ['90%'], reason: 'after saving, the bests it set');
      expect(bestsSetBy(container.read(lifetimeStatsProvider), first), isEmpty);

      container.read(appRouterProvider).go('/history/${workoutId(second)}');
      await tester.pumpAndSettle();
      expect(find.text('New personal best'), findsOneWidget);
      container.read(appRouterProvider).go('/history/${workoutId(first)}');
      await tester.pumpAndSettle();
      expect(find.text('New personal best'), findsNothing);
    });
  });

  testWidgets('locked cards lead to the paywall', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unlock with Player Pro').first);
      await tester.tap(find.text('Unlock with Player Pro').first);
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/paywall');
    });
  });

  testWidgets('drill by drill shows each drill\'s trend to Pro players, and a short list on Progress', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester, pro: true);
      final history = container.read(workoutHistoryProvider.notifier);
      history.add(workout(now.subtract(const Duration(days: 2)), [('pick-your-corner', shots(10, 5)), ('ball-bounce-streak', (at) => SetLog(setIndex: 0, streak: 8, loggedAt: at))]));
      history.add(workout(now.subtract(const Duration(days: 1)), [('pick-your-corner', shots(10, 7))]));
      history.add(workout(now, [('pick-your-corner', shots(10, 9))]));

      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Drill by drill'));
      expect(find.text('Accuracy per workout · 3 workouts'), findsOneWidget);
      expect(find.byType(Sparkline), findsWidgets);
      expect(find.textContaining('See all'), findsNothing, reason: 'only two drills');

      container.read(appRouterProvider).go('/progress/drills');
      await tester.pumpAndSettle();
      expect(find.text('Drill by drill'), findsWidgets);
      expect(find.text('Best streak · 1 workout'), findsOneWidget);
      expect(find.text('Unlock with Player Pro'), findsNothing);
      await tester.tap(find.text('Pick your corner').first);
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/drills/pick-your-corner');
    });
  });

  testWidgets('without Player Pro the drill page is a prompt over a blurred preview', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester);
      container.read(workoutHistoryProvider.notifier).add(workout(now, [('pick-your-corner', shots(10, 9))]));
      container.read(appRouterProvider).go('/progress/drills');
      await tester.pumpAndSettle();
      expect(find.text('Unlock with Player Pro'), findsOneWidget);
      expect(find.text('See every drill\'s results, workout by workout.'), findsOneWidget);
    });
  });

  testWidgets('the workout history lists every workout, and Progress links to it past five', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final container = await mount(tester);
      final history = container.read(workoutHistoryProvider.notifier);
      for (var i = 0; i < 7; i++) {
        history.add(workout(now.subtract(Duration(days: i)), [('pick-your-corner', shots(10, 5))]));
      }
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('See all'), 300);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/history');
      expect(find.text('Your latest 7 workouts, saved on this device.'), findsOneWidget);
      expect(find.text('Pick your corner'), findsNWidgets(7), reason: 'one card per workout');
      await tester.tap(find.text('Pick your corner').first);
      await tester.pumpAndSettle();
      expect(find.text('Workout summary'), findsWidgets);
    });
  });

  testWidgets('a personal best from a workout no longer in history says so instead of going nowhere', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final first = workout(now.subtract(const Duration(days: 80)), [('pick-your-corner', shots(10, 9))]);
      final container = await mount(tester, pro: true);
      container.read(workoutHistoryProvider.notifier).add(first);
      for (var i = 0; i < WorkoutHistory.maxWorkouts; i++) {
        container.read(workoutHistoryProvider.notifier).add(workout(now.subtract(Duration(minutes: i + 1)), [('toe-drag-reps', (at) => SetLog(setIndex: 0, reps: 10, loggedAt: at))]));
      }
      expect(container.read(workoutHistoryProvider.notifier).byId(workoutId(first)), isNull);
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      final card = find.widgetWithText(TrainingCard, 'Pick your corner');
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.textContaining('older than the latest 60'), findsOneWidget);
    });
  });

  group('lifetime stats storage', () {
    testWidgets('totals keep counting after the workout history is trimmed, and survive a restart', (tester) async {
      await withClock(Clock.fixed(now), () async {
        final container = await mount(tester);
        final history = container.read(workoutHistoryProvider.notifier);
        for (var i = 0; i < WorkoutHistory.maxWorkouts + 5; i++) {
          history.add(workout(now.subtract(Duration(minutes: i + 1)), [('pick-your-corner', shots(10, 5))]));
        }
        expect(container.read(workoutHistoryProvider), hasLength(WorkoutHistory.maxWorkouts));
        expect(container.read(lifetimeStatsProvider).workouts, WorkoutHistory.maxWorkouts + 5);
        expect(container.read(lifetimeStatsProvider).shots, (WorkoutHistory.maxWorkouts + 5) * 10);

        final preferences = await SharedPreferences.getInstance();
        final again = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride]);
        addTearDown(again.dispose);
        expect(again.read(lifetimeStatsProvider).workouts, WorkoutHistory.maxWorkouts + 5);
      });
    });

    test('first run rebuilds from the saved workouts, and damaged data does too', () async {
      final sessions = [
        workout(DateTime(2026, 10, 19, 9), [('pick-your-corner', shots(10, 5))]),
        workout(DateTime(2026, 10, 18, 9), [('pick-your-corner', shots(10, 8))]),
      ];
      for (final stored in [
        null,
        'not json',
        jsonEncode({'workouts': 'x'}),
      ]) {
        SharedPreferences.setMockInitialValues({
          WorkoutHistory.storageKey: jsonEncode([for (final s in sessions) s.toJson()]),
          ?(stored == null ? null : LifetimeStatsNotifier.storageKey): ?stored,
        });
        final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()), testCatalogOverride]);
        addTearDown(container.dispose);
        final stats = container.read(lifetimeStatsProvider);
        expect(stats.workouts, 2, reason: '$stored');
        expect(stats.shots, 20);
        expect(stats.bests['accuracy:pick-your-corner']!.value, 80);
      }
    });
  });
}
