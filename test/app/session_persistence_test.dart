import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> openApp(SharedPreferences preferences) async {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
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

  test('a workout in progress survives the app being killed and resumes where it left off', () async {
    final first = await openApp(preferences);
    final notifier = first.read(trainingSessionProvider.notifier);
    notifier.start([sampleDrills.first, sampleDrills[3]]);
    notifier.logSet(reps: 10);
    notifier.selectDrill(1);
    notifier.logSet(reps: 10, hits: 7);
    await flush();
    final before = first.read(trainingSessionProvider);

    // "Kill" the app: a brand-new container reads only what was saved to disk.
    final second = await openApp(preferences);
    final restored = second.read(trainingSessionProvider);
    expect(restored.startedAt, before.startedAt);
    expect(restored.drills.map((d) => d.id), before.drills.map((d) => d.id));
    expect(restored.drillIndex, 1);
    expect(restored.setIndex, 1);
    expect(restored.logs.map((e) => (e.drillId, e.log.reps, e.log.hits)), [(sampleDrills.first.id, 10, null), (sampleDrills[3].id, 10, 7)]);
    expect(restored.finished, isFalse);

    // Logging continues from the restored state.
    second.read(trainingSessionProvider.notifier).logSet(reps: 10, hits: 9);
    expect(second.read(trainingSessionProvider).logs, hasLength(3));
  });

  test('progress is saved after every set', () async {
    final container = await openApp(preferences);
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start([sampleDrills.first]);
    for (var i = 1; i <= 2; i++) {
      notifier.logSet(reps: 10);
      await flush();
      final saved = jsonDecode(preferences.getString(TrainingSessionNotifier.storageKey)!) as Map<String, dynamic>;
      expect((saved['logs'] as List), hasLength(i));
    }
  });

  test('a finished workout is kept until it is dismissed, then forgotten', () async {
    final first = await openApp(preferences);
    final notifier = first.read(trainingSessionProvider.notifier);
    final drill = sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 1));
    notifier.start([drill]);
    notifier.logSet(reps: 8);
    await flush();

    final summary = await openApp(preferences);
    expect(summary.read(trainingSessionProvider).finished, isTrue);
    expect(summary.read(trainingSessionProvider).endedAt, isNotNull);

    summary.read(trainingSessionProvider.notifier).dismissFinishedWorkout();
    await flush();
    expect(preferences.getString(TrainingSessionNotifier.storageKey), isNull);
    expect((await openApp(preferences)).read(trainingSessionProvider).startedAt, isNull);
  });

  test('rest countdown and custom drills are restored too', () async {
    final custom = sampleDrills.first.copyWith(
      id: 'custom-template',
      title: 'My drill',
      mediaAssetPath: 'placeholder/custom-hands',
      defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 3),
    );
    final first = await openApp(preferences);
    first.read(trainingSessionProvider.notifier).start([custom]);
    first.read(trainingSessionProvider.notifier).logSet(reps: 5);
    await first.read(drillRestSettingsProvider.notifier).configure(custom.id, (enabled: true, seconds: 45));
    first.read(trainingSessionProvider.notifier).logSet(reps: 6);
    await flush();
    final deadline = first.read(trainingSessionProvider).restEndsAt;
    expect(deadline, isNotNull);

    final restored = (await openApp(preferences)).read(trainingSessionProvider);
    expect(restored.drills.single.title, 'My drill');
    expect(restored.restEndsAt, deadline);
  });

  test('corrupt saved data is reported and ignored instead of crashing', () async {
    for (final bad in [
      'not json',
      '{}',
      jsonEncode({'drills': [], 'drillIndex': 0, 'dismissed': false, 'logs': []}),
    ]) {
      SharedPreferences.setMockInitialValues({TrainingSessionNotifier.storageKey: bad});
      final prefs = await SharedPreferences.getInstance();
      final reported = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = original);

      final session = (await openApp(prefs)).read(trainingSessionProvider);
      FlutterError.onError = original;
      expect(session.startedAt, isNull, reason: bad);
      expect(reported, hasLength(1), reason: bad);
      await flush();
      expect(prefs.getString(TrainingSessionNotifier.storageKey), isNull, reason: bad);
    }
  });

  test('a saved set for a drill that is not in the session is rejected', () {
    final session = TrainingSession(drills: [sampleDrills.first], startedAt: DateTime.utc(2026));
    final json = session.toJson();
    (json['logs'] as List).add({'drillId': 'ghost', 'setIndex': 0, 'reps': 1, 'loggedAt': DateTime.utc(2026).toIso8601String()});
    expect(() => TrainingSession.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>), throwsFormatException);
  });

  group('state machine', () {
    late ProviderContainer container;
    setUp(() async => container = await openApp(preferences));

    test('invalid entries are rejected before they change the session', () {
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([sampleDrills[3]]);
      expect(() => notifier.logSet(reps: 10, hits: 11), throwsArgumentError);
      expect(() => notifier.logSet(hits: 5), throwsArgumentError);
      expect(container.read(trainingSessionProvider).logs, isEmpty);
    });

    test('start rejects empty and duplicate drill lists', () {
      final notifier = container.read(trainingSessionProvider.notifier);
      expect(() => notifier.start([]), throwsArgumentError);
      expect(() => notifier.start([sampleDrills.first, sampleDrills.first]), throwsArgumentError);
    });

    test('selecting a drill outside the session is a range error', () {
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([sampleDrills.first]);
      expect(() => notifier.selectDrill(1), throwsRangeError);
      expect(() => notifier.selectDrill(-1), throwsRangeError);
    });

    test('dismissing before every set is logged is refused', () {
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([sampleDrills.first]);
      expect(notifier.dismissFinishedWorkout, throwsStateError);
    });

    test('adjusting rest with no countdown is refused', () {
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([sampleDrills.first]);
      expect(() => notifier.adjustRest(15), throwsStateError);
    });
  });
}
