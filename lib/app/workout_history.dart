import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/models/drill.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'progress_state.dart';
import 'sample_data.dart';
import 'training_state.dart';

/// Shots logged in a workout: reps from the shooting skills (accuracy and power).
int shotsLogged(TrainingSession session) => session.logs
    .where((entry) {
      final pillar = session.drills.firstWhere((drill) => drill.id == entry.drillId).pillar;
      return pillar == SkillPillar.shotAccuracy || pillar == SkillPillar.shotPower;
    })
    .fold(0, (total, entry) => total + (entry.log.reps ?? 0));

/// A short name for a workout: the drill's title, or the first drill and how many more.
String workoutTitle(TrainingSession session) {
  final first = session.drills.first.title;
  final more = session.drills.length - 1;
  return more == 0 ? first : '$first + $more more';
}

/// Stable id for routing to a saved workout.
String workoutId(TrainingSession session) => '${session.startedAt!.millisecondsSinceEpoch}';

/// Friendly date for a saved workout, such as `Today`, `Yesterday`, or `Mon, Oct 12`.
String workoutDateLabel(DateTime when, DateTime now) {
  final day = DateTime(when.year, when.month, when.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${weekdays[when.weekday - 1]}, ${months[when.month - 1]} ${when.day}';
}

/// Totals across saved workouts.
class HistoryTotals {
  const HistoryTotals({required this.workouts, required this.activeSeconds, required this.shotsThisWeek});

  final int workouts;
  final int activeSeconds;
  final int shotsThisWeek;
}

HistoryTotals totalsFor(List<TrainingSession> history, DateTime now) {
  final weekStart = now.subtract(const Duration(days: 7));
  return HistoryTotals(
    workouts: history.length,
    activeSeconds: history.fold(0, (sum, session) => sum + session.activeSeconds),
    shotsThisWeek: history.where((session) => session.startedAt!.isAfter(weekStart)).fold(0, (sum, session) => sum + shotsLogged(session)),
  );
}

/// Finished workouts kept on this device, newest first. A stand-in until workouts are saved to the
/// player's account.
class WorkoutHistory extends Notifier<List<TrainingSession>> {
  static const storageKey = 'workoutHistory';
  static const maxWorkouts = 60;

  @override
  List<TrainingSession> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (stored == null) return const [];
    try {
      final decoded = jsonDecode(stored) as List;
      final workouts = <TrainingSession>[];
      for (final entry in decoded) {
        try {
          final session = TrainingSession.fromJson(entry as Map<String, dynamic>);
          if (session.startedAt != null && session.finished) workouts.add(session);
        } on Object catch (error, stackTrace) {
          // One bad entry should not hide the rest of the history.
          FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'workout history', context: ErrorDescription('while reading a saved workout')));
        }
      }
      return List.unmodifiable(workouts);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'workout history', context: ErrorDescription('while reading saved workouts')));
      return const [];
    }
  }

  /// Saves a finished workout. Saving the same workout twice keeps one copy.
  void add(TrainingSession session) {
    if (session.startedAt == null || !session.finished) throw StateError('Only finished workouts are saved to history.');
    final id = workoutId(session);
    final next = [session, ...state.where((existing) => workoutId(existing) != id)].take(maxWorkouts).toList();
    state = List.unmodifiable(next);
    ref.read(lifetimeStatsProvider.notifier).record(session);
    final write = ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode([for (final workout in next) workout.toJson()]));
    unawaited(
      write.then((saved) {
        if (!saved) FlutterError.reportError(FlutterErrorDetails(exception: StateError('Couldn\'t save your workout to history.'), library: 'workout history'));
      }),
    );
  }

  TrainingSession? byId(String id) => state.where((session) => workoutId(session) == id).firstOrNull;
}

final workoutHistoryProvider = NotifierProvider<WorkoutHistory, List<TrainingSession>>(WorkoutHistory.new);
