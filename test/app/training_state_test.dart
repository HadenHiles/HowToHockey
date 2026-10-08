import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  });

  tearDown(() => container.dispose());

  test('progress is per drill, supports out-of-order sets, and rejects duplicate completion', () {
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start([sampleDrills.first, sampleDrills[3]]);
    notifier.selectDrill(1);
    notifier.logSet(reps: 10, hits: 8);
    notifier.selectDrill(0);
    notifier.logSet(reps: 7);
    notifier.selectDrill(1);
    notifier.logSet(reps: 10, hits: 9);
    expect(container.read(trainingSessionProvider).finished, isFalse);
    expect(() => notifier.logSet(reps: 10, hits: 9), throwsStateError);
    notifier.selectDrill(0);
    notifier.logSet(reps: 12);
    final session = container.read(trainingSessionProvider);
    expect(session.finished, isTrue);
    expect(session.logs.map((entry) => entry.log.setIndex), [0, 0, 1, 1]);
    expect(session.drillIndex, 0);
    expect(session.endedAt, isNotNull);
    expect(session.restEndsAt, isNull);
    expect(() => notifier.logSet(reps: 12), throwsStateError);
  });

  test('rest defaults off, uses saved duration, adjusts precisely, and can be skipped', () async {
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start(sampleDrills);
    notifier.logSet(reps: 10);
    expect(container.read(trainingSessionProvider).restEndsAt, isNull);
    await container.read(drillRestSettingsProvider.notifier).configure(sampleDrills.first.id, (enabled: true, seconds: 90));
    final before = DateTime.now().toUtc();
    notifier.logSet(reps: 10);
    final deadline = container.read(trainingSessionProvider).restEndsAt!;
    expect(deadline.difference(before).inMilliseconds, inInclusiveRange(90000, 90100));
    notifier.adjustRest(15);
    expect(container.read(trainingSessionProvider).restEndsAt!.difference(deadline), const Duration(seconds: 15));
    notifier.adjustRest(-15);
    expect(container.read(trainingSessionProvider).restEndsAt, deadline);
    notifier.selectDrill(1);
    expect(container.read(trainingSessionProvider).restEndsAt, deadline);
    notifier.skipRest();
    expect(container.read(trainingSessionProvider).restEndsAt, isNull);
    expect(() => notifier.adjustRest(15), throwsStateError);
  });

  test('invalid settings and duplicate drill IDs are rejected', () async {
    final settings = container.read(drillRestSettingsProvider.notifier);
    await expectLater(settings.configure('drill', (enabled: true, seconds: 0)), throwsRangeError);
    expect(container.read(drillRestSettingsProvider), isEmpty);
    final notifier = container.read(trainingSessionProvider.notifier);
    expect(() => notifier.start([]), throwsArgumentError);
    expect(() => notifier.start([sampleDrills.first, sampleDrills.first]), throwsArgumentError);
    expect(() => notifier.selectDrill(-1), throwsRangeError);
  });

  test('only a finished workout can dismiss its panel and a new workout resets it', () {
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start([sampleDrills.first]);
    expect(() => notifier.dismissFinishedWorkout(), throwsStateError);
    notifier.logSet(reps: 10);
    notifier.logSet(reps: 10);
    final finished = container.read(trainingSessionProvider);
    expect(finished.dismissed, isFalse);
    notifier.dismissFinishedWorkout();
    final dismissed = container.read(trainingSessionProvider);
    expect(dismissed.dismissed, isTrue);
    expect(dismissed.logs, finished.logs);
    expect(dismissed.startedAt, finished.startedAt);
    expect(dismissed.endedAt, finished.endedAt);
    notifier.start(sampleDrills);
    expect(container.read(trainingSessionProvider).dismissed, isFalse);
  });

  test('elapsed time is fixed after completion and logged training distinguishes estimates', () {
    final start = DateTime.utc(2026, 10, 5, 12);
    final session = TrainingSession(drills: sampleDrills, startedAt: start, endedAt: start.add(const Duration(seconds: 125)));
    expect(session.elapsedSeconds, 125);
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start(sampleDrills);
    notifier.selectDrill(1);
    notifier.logSet(seconds: 30);
    expect(container.read(trainingSessionProvider).activeSeconds, 30);
    expect(container.read(trainingSessionProvider).hasEstimatedTime, isFalse);
    notifier.selectDrill(0);
    notifier.logSet(reps: 10);
    expect(container.read(trainingSessionProvider).activeSeconds, 30 + sampleDrills.first.estimatedSecondsPerSet);
    expect(container.read(trainingSessionProvider).hasEstimatedTime, isTrue);
  });

  test('corrupt stored rest settings produce an explicit error', () async {
    await container.read(sharedPreferencesProvider).setString('drillRest.invalid', 'on:0');
    expect(() => container.read(drillRestSettingsProvider), throwsA(isA<Exception>().having((error) => error.toString(), 'message', contains('Invalid rest settings for invalid'))));
  });
}
