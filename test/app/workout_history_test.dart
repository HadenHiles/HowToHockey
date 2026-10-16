import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Drill oneSet(Drill drill) => drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: 1));

TrainingSession finished(DateTime startedAt, {List<Drill>? drills, int reps = 10}) {
  final list = drills ?? [oneSet(sampleDrills.first)];
  return TrainingSession(
    drills: list,
    startedAt: startedAt.toUtc(),
    endedAt: startedAt.toUtc().add(const Duration(minutes: 5)),
    logs: [for (final drill in list) (drillId: drill.id, log: SetLog(setIndex: 0, reps: reps, hits: drill.trackingType == TrackingType.accuracy ? reps ~/ 2 : null, loggedAt: startedAt.toUtc()))],
  );
}

Future<ProviderContainer> open(SharedPreferences preferences) async {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride, testRemindersOverride]);
  addTearDown(container.dispose);
  return container;
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  group('helpers', () {
    test('titles name the first drill and how many more', () {
      expect(workoutTitle(finished(DateTime(2026, 10, 1))), sampleDrills.first.title);
      expect(workoutTitle(finished(DateTime(2026, 10, 1), drills: [sampleDrills[0], sampleDrills[1], sampleDrills[2]].map(oneSet).toList())), '${sampleDrills.first.title} + 2 more');
    });

    test('dates read as Today, Yesterday, or a short date', () {
      final now = DateTime(2026, 10, 16, 15);
      expect(workoutDateLabel(DateTime(2026, 10, 16, 8), now), 'Today');
      expect(workoutDateLabel(DateTime(2026, 10, 15, 23, 59), now), 'Yesterday');
      expect(workoutDateLabel(DateTime(2026, 10, 12, 9), now), 'Mon, Oct 12');
      expect(workoutDateLabel(DateTime(2025, 12, 31), now), 'Wed, Dec 31');
    });

    test('shots count reps from the shooting skills only', () {
      final shooting = oneSet(sampleDrills.firstWhere((d) => d.pillar == SkillPillar.shotPower));
      final hands = oneSet(sampleDrills.firstWhere((d) => d.pillar == SkillPillar.hands));
      expect(shotsLogged(finished(DateTime(2026, 10, 1), drills: [shooting, hands], reps: 12)), 12);
    });

    test('totals add active time and only count this week\'s shots', () {
      final now = DateTime(2026, 10, 16, 12);
      final shooting = oneSet(sampleDrills.firstWhere((d) => d.pillar == SkillPillar.shotPower));
      final history = [
        finished(now.subtract(const Duration(days: 1)), drills: [shooting], reps: 20),
        finished(now.subtract(const Duration(days: 20)), drills: [shooting], reps: 50),
      ];
      final totals = totalsFor(history, now);
      expect(totals.workouts, 2);
      expect(totals.shotsThisWeek, 20);
      expect(totals.activeSeconds, history.fold<int>(0, (sum, s) => sum + s.activeSeconds));
    });
  });

  group('storage', () {
    test('workouts are kept newest first, survive a restart, and the same workout is stored once', () async {
      final first = await open(preferences);
      final history = first.read(workoutHistoryProvider.notifier);
      history.add(finished(DateTime(2026, 10, 1, 9)));
      history.add(finished(DateTime(2026, 10, 2, 9)));
      history.add(finished(DateTime(2026, 10, 1, 9)));
      await flush();
      expect(first.read(workoutHistoryProvider).map((s) => s.startedAt!.day), [1, 2], reason: 'the repeat moves to the front and is not duplicated');

      final second = await open(preferences);
      expect(second.read(workoutHistoryProvider), hasLength(2));
      expect(second.read(workoutHistoryProvider).first.logs.single.log.reps, 10);
    });

    test('only the latest workouts are kept', () async {
      final container = await open(preferences);
      final history = container.read(workoutHistoryProvider.notifier);
      for (var i = 0; i < WorkoutHistory.maxWorkouts + 5; i++) {
        history.add(finished(DateTime(2026, 1, 1).add(Duration(days: i))));
      }
      expect(container.read(workoutHistoryProvider), hasLength(WorkoutHistory.maxWorkouts));
      expect(container.read(workoutHistoryProvider).first.startedAt!.isAfter(container.read(workoutHistoryProvider).last.startedAt!), isTrue);
    });

    test('unfinished workouts are rejected', () async {
      final container = await open(preferences);
      final unfinished = TrainingSession(drills: [sampleDrills.first], startedAt: DateTime.utc(2026));
      expect(() => container.read(workoutHistoryProvider.notifier).add(unfinished), throwsStateError);
    });

    test('one corrupt entry is reported and skipped without losing the rest', () async {
      final good = finished(DateTime(2026, 10, 3, 9)).toJson();
      SharedPreferences.setMockInitialValues({
        WorkoutHistory.storageKey: jsonEncode([
          good,
          {'broken': true},
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final reported = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = original);
      final history = (await open(prefs)).read(workoutHistoryProvider);
      FlutterError.onError = original;
      expect(history, hasLength(1));
      expect(reported, hasLength(1));
    });

    test('unreadable history is reported and treated as empty', () async {
      SharedPreferences.setMockInitialValues({WorkoutHistory.storageKey: 'not json'});
      final prefs = await SharedPreferences.getInstance();
      final original = FlutterError.onError;
      var reports = 0;
      FlutterError.onError = (_) => reports++;
      addTearDown(() => FlutterError.onError = original);
      expect((await open(prefs)).read(workoutHistoryProvider), isEmpty);
      FlutterError.onError = original;
      expect(reports, 1);
    });

    test('finishing a workout saves it to history exactly once', () async {
      final container = await open(preferences);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([oneSet(sampleDrills.first)]);
      notifier.logSet(reps: 10);
      notifier.dismissFinishedWorkout();
      await flush();
      expect(container.read(workoutHistoryProvider), hasLength(1));
      expect(container.read(workoutHistoryProvider).single.drills.single.id, sampleDrills.first.id);
    });
  });

  group('screens', () {
    Future<ProviderContainer> mount(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      final p = await SharedPreferences.getInstance();
      final container = await open(p);
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('Progress starts with an honest empty state and zero totals', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Recent training'));
      expect(find.text('No workouts yet. Finish one and it shows up here.'), findsOneWidget);
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('workouts'), findsOneWidget);
    });

    testWidgets('a finished workout appears on Progress and opens its saved summary', (tester) async {
      final container = await mount(tester);
      final notifier = container.read(trainingSessionProvider.notifier);
      final shooting = oneSet(sampleDrills.firstWhere((d) => d.pillar == SkillPillar.shotPower));
      notifier.start([shooting]);
      notifier.logSet(reps: 24);
      notifier.dismissFinishedWorkout();
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();

      expect(find.text('No workouts yet. Finish one and it shows up here.'), findsNothing);
      expect(find.text(shooting.title), findsOneWidget);
      expect(find.text('workout'), findsOneWidget);
      expect(find.text('24'), findsWidgets);
      await tester.ensureVisible(find.text(shooting.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(shooting.title));
      await tester.pumpAndSettle();
      expect(find.text('Workout summary'), findsWidgets);
      expect(find.textContaining('Today · ${shooting.title}'), findsOneWidget);
      expect(find.text('24 reps in 1 set'), findsOneWidget);
      await tester.tap(find.text('Back to Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Your totals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown saved workout shows a friendly message', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/history/12345');
      await tester.pumpAndSettle();
      expect(find.text('Workout not found'), findsWidgets);
      expect(find.text('Back to Progress'), findsOneWidget);
    });

    testWidgets('history survives a restart and the Shot Logger saves too', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/log/shots');
      await tester.pumpAndSettle();
      await tester.tap(find.text('+25'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log 25 shots'));
      await tester.pumpAndSettle();
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      final reopened = await open(prefs);
      expect(reopened.read(workoutHistoryProvider).single.drills.single.title, 'Shot logger');
    });
  });
}
