import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';
import '../features/drills/set_calculations.dart';
import '../features/progress/progress_stats.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'progress_tuning.dart';
import 'training_state.dart';
import 'workout_history.dart';

/// Active minutes the weekly ring on Train counts toward.
const weeklyGoalMinutes = 120;

extension WorkoutRecordOfSession on TrainingSession {
  WorkoutRecord toRecord() => WorkoutRecord(id: workoutId(this), startedAt: startedAt!, drills: drills, logs: logs, explicitTzOffsetMinutes: startedAt!.toLocal().timeZoneOffset.inMinutes);
}

/// Lifetime totals, skill levels, personal bests and streaks, kept on this device and updated the moment a
/// workout is saved. Separate from the workout history, which only keeps the latest 60.
class LifetimeStatsNotifier extends Notifier<LifetimeStats> {
  static const storageKey = 'lifetimeStats';

  @override
  LifetimeStats build() {
    final preferences = ref.read(sharedPreferencesProvider);
    final stored = preferences.getString(storageKey);
    if (stored != null) {
      try {
        final restored = LifetimeStats.fromJson(jsonDecode(stored));
        if (restored != null) return restored;
      } on Object {
        // Fall through and rebuild from the saved workouts.
      }
    }
    // First run after this was added, or damaged data: rebuild from the workouts still on the device.
    var stats = const LifetimeStats();
    for (final workout in ref.read(workoutHistoryProvider).reversed) {
      stats = stats.add(workout.toRecord(), tuning: ref.read(progressTuningProvider)).stats;
    }
    return stats;
  }

  /// Counts a finished workout. Counting the same one twice changes nothing.
  void record(TrainingSession session) {
    final next = state.add(session.toRecord(), tuning: ref.read(progressTuningProvider)).stats;
    if (identical(next, state)) return;
    state = next;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(next.toJson())).then((saved) {
        if (!saved) FlutterError.reportError(FlutterErrorDetails(exception: StateError('Couldn\'t save your progress.'), library: 'progress stats'));
      }),
    );
  }
}

final lifetimeStatsProvider = NotifierProvider<LifetimeStatsNotifier, LifetimeStats>(LifetimeStatsNotifier.new);

/// Personal bests a workout set: the ones already recorded for it, or, if it isn't counted yet, the ones it would set.
List<PersonalBest> bestsSetBy(LifetimeStats stats, TrainingSession session, [ProgressTuning tuning = ProgressTuning.defaults]) {
  final record = session.toRecord();
  if (stats.counted.contains(record.id)) {
    return [
      for (final best in stats.bests.values)
        if (best.workoutId == record.id) best,
    ];
  }
  return [
    for (final best in creditFor(record, tuning: tuning).bests.values)
      if (stats.bests[best.key] == null || best.value > stats.bests[best.key]!.value) best,
  ];
}

/// Whether Player Pro features are unlocked for the player being trained.
final playerProProvider = Provider<bool>((ref) => ref.watch(drillFiltersUnlockedProvider));

/// The drills that put the most time into a skill across the workouts still on the device, most first.
List<({String title, int seconds})> topDrillsFor(SkillPillar pillar, List<TrainingSession> history, {int limit = 3}) {
  final seconds = <String, double>{};
  final titles = <String, String>{};
  for (final workout in history) {
    final byId = {for (final drill in workout.drills) drill.id: drill};
    for (final entry in workout.logs) {
      final drill = byId[entry.drillId];
      final weight = drill?.skillWeights[pillar] ?? 0;
      if (drill == null || weight <= 0 || !isCountableSet(drill, entry.log)) continue;
      titles[drill.id] = drill.title;
      seconds[drill.id] = (seconds[drill.id] ?? 0) + activeSecondsForSet(entry.log, drill) * weight;
    }
  }
  final ranked = seconds.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [for (final entry in ranked.take(limit)) (title: titles[entry.key]!, seconds: entry.value.round())];
}
