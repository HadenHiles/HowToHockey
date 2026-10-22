import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/progress_state.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/app/workout_sync.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

final catalog = {for (final d in parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())) d.id: d};
const own = PlayerProfile(id: 'parent-uid', ownerUid: 'parent-uid', displayName: 'Pat H.', birthYear: 1985, isChild: false);
const kid = PlayerProfile(id: 'child-1', ownerUid: 'parent-uid', displayName: 'Avery H.', birthYear: 2015, isChild: true);

TrainingSession workout(DateTime at, {int hits = 6, String? programRunId}) {
  final drill = catalog['pick-your-corner']!.copyWith(defaultPrescription: catalog['pick-your-corner']!.defaultPrescription.copyWith(sets: 1));
  return TrainingSession(
    drills: [drill],
    startedAt: at.toUtc(),
    endedAt: at.toUtc().add(const Duration(minutes: 5)),
    logs: [(drillId: drill.id, log: SetLog(setIndex: 0, reps: 10, hits: hits, loggedAt: at.toUtc()))],
    programRunId: programRunId,
  );
}

Future<void> settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProviderContainer> open({AuthState auth = const GuestSession('guest'), Map<String, Object> saved = const {}}) async {
  SharedPreferences.setMockInitialValues(saved);
  final preferences = await SharedPreferences.getInstance();
  testAuth.signOutSilently(auth);
  testProfiles.own = own;
  testProfiles.children
    ..clear()
    ..add(kid);
  testSessions.uploads.clear();
  testSessions.uploadedSessions.clear();
  testSessions.stats.clear();
  testSessions.failWith = null;
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testAuthOverride, testProfilesOverride, testSessionsOverride]);
  addTearDown(container.dispose);
  container.listen(workoutSyncProvider, (_, _) {});
  container.listen(progressStatsProvider, (_, _) {});
  await settle();
  return container;
}

void main() {
  final day = DateTime(2026, 10, 20, 9);

  test('a guest\'s workout waits, and counts on the device', () async {
    final container = await open();
    container.read(workoutHistoryProvider.notifier).add(workout(day));
    await settle();
    expect(testSessions.uploads, isEmpty);
    expect(container.read(workoutSyncProvider), hasLength(1));
    expect(container.read(progressStatsProvider).workouts, 1);
  });

  test('signing in sends the waiting workouts to the account\'s own profile', () async {
    final container = await open();
    container.read(workoutHistoryProvider.notifier).add(workout(day));
    await settle();

    testAuth.signInSilently(const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true));
    await settle();
    await settle();
    final id = workoutId(workout(day));
    expect(testSessions.uploads, [('parent-uid', id)]);
    final entry = container.read(workoutSyncProvider)[id]!;
    expect(entry.uploadedAtMs, isNotNull);
    expect(entry.profileId, 'parent-uid');
    expect(container.read(progressStatsProvider).workouts, 1, reason: 'still shown while the server catches up');
  });

  test('program run IDs are included when finished workouts are uploaded', () async {
    final container = await open(
      auth: const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true),
    );
    final session = workout(day, programRunId: 'program-run-1');
    container.read(workoutHistoryProvider.notifier).add(session);
    await settle();

    expect(testSessions.uploadedSessions.single.programRunId, 'program-run-1');
  });

  test('the server\'s count takes over without counting a workout twice', () async {
    final container = await open(
      auth: const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true),
    );
    final session = workout(day);
    container.read(workoutHistoryProvider.notifier).add(session);
    await settle();
    expect(testSessions.uploads.single.$2, workoutId(session));
    expect(container.read(progressStatsProvider).workouts, 1);

    final serverCopy = LifetimeStats.fromJson({
      ...const LifetimeStats().add(session.toRecord()).stats.toJson(),
      'recent': [workoutId(session)],
    })!;
    testSessions.setStats('parent-uid', serverCopy);
    await settle();
    expect(container.read(progressStatsProvider).workouts, 1, reason: 'not 2');
    expect(container.read(progressStatsProvider).shots, 10);

    await container.read(workoutSyncProvider.notifier).flush();
    expect(container.read(workoutSyncProvider), isEmpty, reason: 'counted by the server, nothing left to track');
    expect(container.read(progressStatsProvider).workouts, 1);
  });

  test('each profile gets its own workouts and its own stats', () async {
    final container = await open(
      auth: const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true),
    );
    final history = container.read(workoutHistoryProvider.notifier);
    history.add(workout(day));
    container.read(activePlayerIdProvider.notifier).choose('child-1');
    await settle();
    history.add(workout(day.add(const Duration(hours: 3)), hits: 9));
    await settle();

    expect(testSessions.uploads.map((u) => u.$1).toSet(), {'parent-uid', 'child-1'});
    expect(testSessions.uploads.where((u) => u.$1 == 'child-1'), hasLength(1));
    expect(container.read(progressStatsProvider).workouts, 1, reason: 'the child sees only their own');
    expect(container.read(progressStatsProvider).bests['accuracy:pick-your-corner']!.value, 90);

    container.read(activePlayerIdProvider.notifier).choose('parent-uid');
    await settle();
    expect(container.read(progressStatsProvider).bests['accuracy:pick-your-corner']!.value, 60);
  });

  test('a failed upload is kept, still counts, and goes up on the next try', () async {
    final container = await open(
      auth: const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true),
    );
    testSessions.failWith = Exception('offline');
    container.read(workoutHistoryProvider.notifier).add(workout(day));
    await settle();
    final id = workoutId(workout(day));
    expect(container.read(workoutSyncProvider)[id]!.uploadedAtMs, isNull);
    expect(container.read(progressStatsProvider).workouts, 1);

    testSessions.failWith = null;
    await container.read(workoutSyncProvider.notifier).flush();
    expect(testSessions.uploads, [('parent-uid', id)]);
    expect(container.read(workoutSyncProvider)[id]!.uploadedAtMs, isNotNull);
  });

  test('a kid\'s device only sends for its own profile', () async {
    final container = await open(
      saved: {
        WorkoutSync.storageKey: jsonEncode({'123': SyncEntry(profileId: 'someone-else', queuedAtMs: 1).toJson()}),
      },
    );
    testAuth.signInSilently(const KidDeviceSession('child-1'));
    await settle();
    await container.read(workoutSyncProvider.notifier).flush();
    expect(testSessions.uploads, isEmpty);
  });

  test('workouts already on the device when syncing first starts are queued', () async {
    SharedPreferences.setMockInitialValues({
      WorkoutHistory.storageKey: jsonEncode([workout(day).toJson()]),
    });
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()), testCatalogOverride, testAuthOverride, testProfilesOverride, testSessionsOverride],
    );
    addTearDown(container.dispose);
    expect(container.read(workoutSyncProvider).keys, [workoutId(workout(day))]);
  });
}
