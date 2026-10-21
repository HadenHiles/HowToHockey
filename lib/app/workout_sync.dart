import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/auth_service.dart';
import '../features/drills/models/drill.dart';
import '../features/profiles/active_player.dart';
import '../features/progress/progress_stats.dart';
import '../features/sessions/session_repository.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'progress_state.dart';
import 'progress_tuning.dart';
import 'training_state.dart';
import 'workout_history.dart';

/// A finished workout waiting to reach (or waiting to be counted by) the player's account.
class SyncEntry {
  const SyncEntry({this.profileId, this.uploadedAtMs, required this.queuedAtMs, this.pending = false});

  /// Sent from a child's device: it only counts once a grown-up confirms it.
  final bool pending;

  /// The profile it belongs to. Null for workouts done as a guest: the account's own profile claims those.
  final String? profileId;

  /// Set once the workout is stored; it stays until the server's stats include it.
  final int? uploadedAtMs;
  final int queuedAtMs;

  SyncEntry copyWith({String? profileId, int? uploadedAtMs}) =>
      SyncEntry(profileId: profileId ?? this.profileId, uploadedAtMs: uploadedAtMs ?? this.uploadedAtMs, queuedAtMs: queuedAtMs, pending: pending);

  Map<String, Object?> toJson() => {'profileId': profileId, 'uploadedAtMs': uploadedAtMs, 'queuedAtMs': queuedAtMs, if (pending) 'pending': true};

  static SyncEntry? fromJson(Object? json) => json is Map<String, dynamic> && json['queuedAtMs'] is int
      ? SyncEntry(profileId: json['profileId'] as String?, uploadedAtMs: json['uploadedAtMs'] as int?, queuedAtMs: json['queuedAtMs'] as int, pending: json['pending'] == true)
      : null;
}

const _giveUpAfter = Duration(days: 1);
const _retryEvery = Duration(minutes: 1);

/// Sends finished workouts to the player's account and keeps track of which ones the server has counted.
/// Offline or signed out, workouts wait here and go up when they can.
/// Tries again whenever the app comes back to the front.
class _ResumeFlush with WidgetsBindingObserver {
  _ResumeFlush(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

class WorkoutSync extends Notifier<Map<String, SyncEntry>> {
  static const storageKey = 'workoutSyncLedger';
  var _flushing = false;
  Timer? _retry;

  @override
  Map<String, SyncEntry> build() {
    final preferences = ref.read(sharedPreferencesProvider);
    var ledger = <String, SyncEntry>{};
    final stored = preferences.getString(storageKey);
    if (stored != null) {
      try {
        for (final entry in (jsonDecode(stored) as Map<String, dynamic>).entries) {
          final value = SyncEntry.fromJson(entry.value);
          if (value != null) ledger[entry.key] = value;
        }
      } on Object {
        ledger = {};
      }
    } else {
      // First run with syncing: workouts already on the device go up too.
      final now = clock.now().millisecondsSinceEpoch;
      ledger = {for (final workout in ref.read(workoutHistoryProvider)) workoutId(workout): SyncEntry(queuedAtMs: now)};
      unawaited(preferences.setString(storageKey, jsonEncode({for (final e in ledger.entries) e.key: e.value.toJson()})));
    }
    ref.listen(switchablePlayersProvider, (_, _) => unawaited(flush()));
    // When the server's stats for the player on screen change, check which workouts it has now counted.
    ref.listen(activeCloudStatsProvider, (_, _) => unawaited(flush()));
    final lifecycle = _ResumeFlush(() => unawaited(flush()));
    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.addObserver(lifecycle);
    ref.onDispose(() {
      binding.removeObserver(lifecycle);
      _retry?.cancel();
    });
    Future.microtask(flush);
    return ledger;
  }

  void _store(Map<String, SyncEntry> next) {
    state = Map.unmodifiable(next);
    unawaited(ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode({for (final e in next.entries) e.key: e.value.toJson()})));
  }

  /// Notes a finished workout for the player who did it, and tries to send it right away.
  void enqueue(TrainingSession session) {
    final id = workoutId(session);
    if (state.containsKey(id)) return;
    _store({...state, id: SyncEntry(profileId: ref.read(activePlayerProvider)?.id, queuedAtMs: clock.now().millisecondsSinceEpoch, pending: ref.read(authStateProvider).value is KidDeviceSession)});
    unawaited(flush());
  }

  Future<void> flush() async {
    if (_flushing || state.isEmpty) return;
    _flushing = true;
    try {
      final players = ref.read(switchablePlayersProvider);
      final allowed = {for (final p in players) p.id};
      final ownId = players.where((p) => !p.isChild).firstOrNull?.id;
      final history = ref.read(workoutHistoryProvider.notifier);
      final repository = ref.read(sessionRepositoryProvider);
      final next = {...state};
      final now = clock.now();
      var failed = false;
      for (final MapEntry(:key, :value) in state.entries) {
        final target = value.profileId ?? ownId;
        if (value.uploadedAtMs != null) {
          final counted = target != null && _cloudCounted(target).contains(key);
          if (counted || now.millisecondsSinceEpoch - value.uploadedAtMs! > _giveUpAfter.inMilliseconds) next.remove(key);
          continue;
        }
        final session = history.byId(key);
        if (session == null) {
          next.remove(key); // trimmed from history before it could be sent
          continue;
        }
        if (target == null || !allowed.contains(target)) continue;
        try {
          await repository.upload(
            target,
            SessionUpload(record: session.toRecord(), endedAt: session.endedAt ?? session.startedAt!, routineName: workoutTitle(session), activeSeconds: session.activeSeconds, pending: value.pending),
          );
          next[key] = value.copyWith(profileId: target, uploadedAtMs: now.millisecondsSinceEpoch);
        } on Object catch (error) {
          debugPrint('Workout $key will be sent later: $error');
          failed = true;
        }
      }
      if (failed) {
        _retry?.cancel();
        _retry = Timer(_retryEvery, () => unawaited(flush()));
      }
      if (!mapEquals(next.map((k, v) => MapEntry(k, jsonEncode(v.toJson()))), state.map((k, v) => MapEntry(k, jsonEncode(v.toJson()))))) _store(next);
    } finally {
      _flushing = false;
    }
  }

  Set<String> _cloudCounted(String profileId) {
    final cloud = ref.read(cloudStatsProvider(profileId));
    return cloud is AsyncData<LifetimeStats?> ? (cloud.value?.counted ?? const <String>{}) : const <String>{};
  }
}

final workoutSyncProvider = NotifierProvider<WorkoutSync, Map<String, SyncEntry>>(WorkoutSync.new);

/// What the server has counted for a profile so far.
final cloudStatsProvider = StreamProvider.family<LifetimeStats?, String>((ref, profileId) => ref.watch(sessionRepositoryProvider).watchStats(profileId));

/// The server's stats for whoever is training, or nothing if there is no profile yet.
final activeCloudStatsProvider = Provider<AsyncValue<LifetimeStats?>>((ref) {
  final player = ref.watch(activePlayerProvider);
  return player == null ? const AsyncData<LifetimeStats?>(null) : ref.watch(cloudStatsProvider(player.id));
});

/// The stats to show for whoever is training: their account's stats plus workouts still on their way.
/// Guests, who have no profile yet, see what this device has recorded.
final progressStatsProvider = Provider<LifetimeStats>((ref) {
  final player = ref.watch(activePlayerProvider);
  final tuning = ref.watch(progressTuningProvider);
  if (player == null) return ref.watch(lifetimeStatsProvider);
  final cloud = ref.watch(cloudStatsProvider(player.id));
  var stats = (cloud is AsyncData<LifetimeStats?> ? cloud.value : null) ?? const LifetimeStats();
  final history = ref.watch(workoutHistoryProvider.notifier);
  ref.watch(workoutHistoryProvider);
  final ownId = ref.watch(switchablePlayersProvider).where((p) => !p.isChild).firstOrNull?.id;
  for (final MapEntry(:key, :value) in ref.watch(workoutSyncProvider).entries) {
    if (value.pending || (value.profileId ?? ownId) != player.id) continue;
    final session = history.byId(key);
    if (session != null) stats = stats.add(session.toRecord(), tuning: tuning).stats;
  }
  return stats;
});

/// Saved workouts for whoever is training, newest first. Guests, who have no profile yet, see what
/// this device has recorded; a profile never sees another profile's workouts.
final playerHistoryProvider = Provider<List<TrainingSession>>((ref) {
  final player = ref.watch(activePlayerProvider);
  final history = ref.watch(workoutHistoryProvider);
  if (player == null) return history;
  final ownId = ref.watch(switchablePlayersProvider).where((p) => !p.isChild).firstOrNull?.id;
  final owners = ref.watch(workoutOwnersProvider);
  return [
    for (final workout in history)
      if ((owners[workoutId(workout)] ?? ownId) == player.id) workout,
  ];
});

/// A drill's most recent logged sets for the player training, for comparing as they log.
typedef LastResult = ({DateTime when, List<SetLog> sets});

final lastResultsProvider = Provider<Map<String, LastResult>>((ref) {
  final results = <String, LastResult>{};
  for (final workout in ref.watch(playerHistoryProvider)) {
    for (final drill in workout.drills) {
      if (results.containsKey(drill.id)) continue;
      final sets = [
        for (final entry in workout.logs)
          if (entry.drillId == drill.id) entry.log,
      ];
      if (sets.isNotEmpty) results[drill.id] = (when: workout.startedAt!, sets: sets);
    }
  }
  return results;
});
