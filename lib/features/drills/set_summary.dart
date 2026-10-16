import 'models/drill.dart';
import 'set_calculations.dart';

String formatDuration(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _plural(int count, String one, [String? many]) => '$count ${count == 1 ? one : many ?? '${one}s'}';

String _number(double value) => value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);

/// One-line result for a single set, for example `8 / 10 hits · 80%`.
String setResultLabel(SetLog log, TrackingType type) => switch (type) {
  TrackingType.volume => _plural(log.reps ?? 0, 'rep'),
  TrackingType.duration => '${log.seconds ?? 0}s',
  TrackingType.density => '${_plural(log.reps ?? 0, 'shot')} in ${log.seconds ?? 0}s${_perMinute(log)}',
  TrackingType.accuracy => '${log.hits ?? 0} / ${log.reps ?? 0} hits${_percent(log)}',
  TrackingType.streak => '${log.streak ?? 0} in a row',
  TrackingType.binary => (log.completed ?? false) ? 'Completed' : 'Not completed',
};

String _perMinute(SetLog log) {
  final spm = shotsPerMinute(log);
  return spm == null ? '' : ' · ${_number(spm)} a minute';
}

String _percent(SetLog log) {
  final fraction = accuracyFraction(log);
  return fraction == null ? '' : ' · ${(fraction * 100).round()}%';
}

/// Headline total for a drill across all of its sets, for example `14 / 20 hits · 70% accuracy`.
String drillTotalsLabel(Drill drill, DrillTotals totals) {
  if (totals.sets == 0) return 'No sets logged';
  return switch (drill.trackingType) {
    TrackingType.volume => '${_plural(totals.reps, 'rep')} in ${_plural(totals.sets, 'set')}',
    TrackingType.duration => '${formatDuration(totals.seconds)} of timed work in ${_plural(totals.sets, 'set')}',
    TrackingType.density => '${_plural(totals.reps, 'shot')} · ${totals.averageShotsPerMinute == null ? 'no time logged' : '${_number(totals.averageShotsPerMinute!)} a minute on average'}',
    TrackingType.accuracy => '${totals.hits} / ${totals.attempts} hits${totals.accuracy == null ? '' : ' · ${(totals.accuracy! * 100).round()}% accuracy'}',
    TrackingType.streak => 'Best streak: ${totals.bestStreak}',
    TrackingType.binary => '${totals.completedSets} of ${_plural(totals.sets, 'set')} completed',
  };
}
