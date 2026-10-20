import '../drills/models/drill.dart';
import '../drills/set_calculations.dart';
import 'progress_stats.dart';

/// One drill's results across workouts, oldest first, for the per-drill breakdown.
class DrillTrend {
  const DrillTrend({required this.drillId, required this.title, required this.tracking, required this.points, required this.totalSets});

  final String drillId;
  final String title;
  final TrackingType tracking;

  /// One value per workout the drill was in, oldest first. What the value means depends on [tracking].
  final List<({DateTime at, double value})> points;
  final int totalSets;

  double get latest => points.last.value;

  double get best => points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  /// How the value reads, such as `80%` or `45 reps`.
  String format(double value) => switch (tracking) {
    TrackingType.accuracy => '${value.round()}%',
    TrackingType.volume => '${value.round()} reps',
    TrackingType.density => '${value.round()} / min',
    TrackingType.streak => '${value.round()}',
    TrackingType.duration => value >= 120 ? '${(value / 60).toStringAsFixed(1)} min' : '${value.round()} s',
    TrackingType.binary => '${value.round()}% done',
  };

  /// What the value is, for the one-line explanation under the drill's name.
  String get metricLabel => switch (tracking) {
    TrackingType.accuracy => 'Accuracy per workout',
    TrackingType.volume => 'Reps per workout',
    TrackingType.density => 'Shots per minute',
    TrackingType.streak => 'Best streak',
    TrackingType.duration => 'Time under the clock',
    TrackingType.binary => 'Sets completed',
  };
}

/// The value a workout earned in one drill, or null if it has no usable sets for it.
double? _workoutValue(Drill drill, List<SetLog> logs) {
  final usable = [
    for (final log in logs)
      if (isCountableSet(drill, log)) log,
  ];
  if (usable.isEmpty) return null;
  final totals = summarizeDrill(drill, usable);
  return switch (drill.trackingType) {
    TrackingType.accuracy => totals.accuracy == null ? null : totals.accuracy! * 100,
    TrackingType.volume => totals.reps.toDouble(),
    TrackingType.density => totals.averageShotsPerMinute,
    TrackingType.streak => totals.bestStreak.toDouble(),
    TrackingType.duration => usable.fold<int>(0, (sum, log) => sum + (log.seconds ?? 0)).toDouble(),
    TrackingType.binary => totals.sets == 0 ? null : totals.completedSets / totals.sets * 100,
  };
}

/// Trends for every drill in [workouts] (any order), most-trained first. A drill needs only one workout to appear.
List<DrillTrend> drillTrends(List<WorkoutRecord> workouts) {
  final byDrill = <String, List<({DateTime at, double value, int sets})>>{};
  final drills = <String, Drill>{};
  for (final workout in [...workouts]..sort((a, b) => a.startedAt.compareTo(b.startedAt))) {
    for (final drill in workout.drills) {
      final logs = [
        for (final entry in workout.logs)
          if (entry.drillId == drill.id) entry.log,
      ];
      final value = _workoutValue(drill, logs);
      if (value == null) continue;
      drills[drill.id] = drill;
      byDrill.putIfAbsent(drill.id, () => []).add((at: workout.startedAt, value: value, sets: logs.length));
    }
  }
  final trends = [
    for (final entry in byDrill.entries)
      DrillTrend(
        drillId: entry.key,
        title: drills[entry.key]!.title,
        tracking: drills[entry.key]!.trackingType,
        points: [for (final p in entry.value) (at: p.at, value: p.value)],
        totalSets: entry.value.fold(0, (sum, p) => sum + p.sets),
      ),
  ];
  return trends..sort((a, b) {
    final byCount = b.points.length.compareTo(a.points.length);
    return byCount != 0 ? byCount : a.title.compareTo(b.title);
  });
}
