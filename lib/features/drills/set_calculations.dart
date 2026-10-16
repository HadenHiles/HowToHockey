import 'models/drill.dart';

/// Thrown when a set entry does not make sense for the drill's tracking type.
class InvalidSetEntry extends ArgumentError {
  InvalidSetEntry(String super.message);
}

/// Checks a set entry against the drill's tracking type before it is logged.
void validateSetEntry(TrackingType type, {int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
  switch (type) {
    case TrackingType.volume:
      if (reps == null || reps < 0) throw InvalidSetEntry('Enter how many reps you did.');
    case TrackingType.duration:
      if (seconds == null || seconds <= 0) throw InvalidSetEntry('A timed set needs a duration.');
    case TrackingType.density:
      if (reps == null || reps < 0) throw InvalidSetEntry('Enter how many shots you took.');
      if (seconds == null || seconds <= 0) throw InvalidSetEntry('A shots-per-minute set needs a duration.');
    case TrackingType.accuracy:
      if (reps == null || reps <= 0) throw InvalidSetEntry('Enter how many shots you took.');
      if (hits == null || hits < 0) throw InvalidSetEntry('Enter how many shots hit the target.');
      if (hits > reps) throw InvalidSetEntry('Hits can\'t be more than the shots you took.');
    case TrackingType.streak:
      if (streak == null || streak < 0) throw InvalidSetEntry('Enter your longest streak.');
    case TrackingType.binary:
      if (completed == null) throw InvalidSetEntry('Mark whether you completed the set.');
  }
}

/// Shots per minute for a density set: reps / seconds * 60.
double? shotsPerMinute(SetLog log) {
  final reps = log.reps;
  final seconds = log.seconds;
  if (reps == null || seconds == null || seconds <= 0) return null;
  return reps / seconds * 60;
}

/// Accuracy as a fraction from 0 to 1: hits / shots taken.
double? accuracyFraction(SetLog log) {
  final hits = log.hits;
  final reps = log.reps;
  if (hits == null || reps == null || reps <= 0) return null;
  return hits / reps;
}

/// Seconds of active training for a set. Sets without a measured time use the drill's estimate.
int activeSecondsForSet(SetLog log, Drill drill) => log.seconds ?? drill.estimatedSecondsPerSet;

/// Totals for one drill across the sets logged in a session.
class DrillTotals {
  const DrillTotals({required this.sets, required this.reps, required this.hits, required this.attempts, required this.bestStreak, required this.completedSets, required this.seconds});

  final int sets;
  final int reps;
  final int hits;

  /// Shots taken in accuracy sets (the denominator for [accuracy]).
  final int attempts;
  final int bestStreak;
  final int completedSets;
  final int seconds;

  /// Overall accuracy from 0 to 1, or null when no accuracy sets were logged.
  double? get accuracy => attempts == 0 ? null : hits / attempts;

  /// Average shots per minute across timed shot sets, or null when there are none.
  double? get averageShotsPerMinute => seconds == 0 || reps == 0 ? null : reps / seconds * 60;
}

DrillTotals summarizeDrill(Drill drill, Iterable<SetLog> logs) {
  var sets = 0;
  var reps = 0;
  var hits = 0;
  var attempts = 0;
  var bestStreak = 0;
  var completed = 0;
  var seconds = 0;
  var densitySeconds = 0;
  var densityReps = 0;
  for (final log in logs) {
    sets++;
    seconds += activeSecondsForSet(log, drill);
    switch (drill.trackingType) {
      case TrackingType.volume:
        reps += log.reps ?? 0;
      case TrackingType.accuracy:
        hits += log.hits ?? 0;
        attempts += log.reps ?? 0;
      case TrackingType.density:
        densityReps += log.reps ?? 0;
        densitySeconds += log.seconds ?? 0;
      case TrackingType.streak:
        final streak = log.streak ?? 0;
        if (streak > bestStreak) bestStreak = streak;
      case TrackingType.binary:
        if (log.completed ?? false) completed++;
      case TrackingType.duration:
        break;
    }
  }
  return DrillTotals(
    sets: sets,
    reps: drill.trackingType == TrackingType.density ? densityReps : reps,
    hits: hits,
    attempts: attempts,
    bestStreak: bestStreak,
    completedSets: completed,
    seconds: drill.trackingType == TrackingType.density ? densitySeconds : seconds,
  );
}
