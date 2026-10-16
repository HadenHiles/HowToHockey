import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/drills/set_calculations.dart';
import 'package:how_to_hockey/features/drills/set_summary.dart';

Drill drillOf(TrackingType type, {int estimated = 40}) => Drill(
  id: type.name,
  title: type.name,
  mediaAssetPath: 'drills/x.mp4',
  formCues: const ['cue'],
  trackingType: type,
  allowedLocations: const [LocationOption.basement],
  minPuckInventory: PuckInventory.low,
  requiresPasser: false,
  skillWeights: const {SkillPillar.hands: 1},
  tier: AccessTier.free,
  supportedBalls: const [],
  passerTypes: const [],
  defaultPrescription: const DrillPrescription(sets: 3),
  estimatedSecondsPerSet: estimated,
  difficulty: 1,
  tags: const [],
);

SetLog log({int? reps, int? hits, int? seconds, int? streak, bool? completed}) =>
    SetLog(setIndex: 0, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: DateTime.utc(2026));

String totals(TrackingType type, List<SetLog> logs) {
  final drill = drillOf(type);
  return drillTotalsLabel(drill, summarizeDrill(drill, logs));
}

void main() {
  test('set labels show the result and the derived number', () {
    expect(setResultLabel(log(reps: 1), TrackingType.volume), '1 rep');
    expect(setResultLabel(log(reps: 12), TrackingType.volume), '12 reps');
    expect(setResultLabel(log(seconds: 30), TrackingType.duration), '30s');
    expect(setResultLabel(log(reps: 15, seconds: 30), TrackingType.density), '15 shots in 30s · 30 a minute');
    expect(setResultLabel(log(reps: 10, seconds: 45), TrackingType.density), '10 shots in 45s · 13.3 a minute');
    expect(setResultLabel(log(reps: 10, hits: 8), TrackingType.accuracy), '8 / 10 hits · 80%');
    expect(setResultLabel(log(streak: 9), TrackingType.streak), '9 in a row');
    expect(setResultLabel(log(completed: true), TrackingType.binary), 'Completed');
    expect(setResultLabel(log(completed: false), TrackingType.binary), 'Not completed');
  });

  test('drill totals read naturally for every tracking type', () {
    expect(totals(TrackingType.volume, [log(reps: 10), log(reps: 12)]), '22 reps in 2 sets');
    expect(totals(TrackingType.volume, [log(reps: 1)]), '1 rep in 1 set');
    expect(totals(TrackingType.duration, [log(seconds: 30), log(seconds: 45)]), '1:15 of timed work in 2 sets');
    expect(totals(TrackingType.density, [log(reps: 15, seconds: 30), log(reps: 20, seconds: 30)]), '35 shots · 35 a minute on average');
    expect(totals(TrackingType.accuracy, [log(reps: 10, hits: 8), log(reps: 10, hits: 6)]), '14 / 20 hits · 70% accuracy');
    expect(totals(TrackingType.streak, [log(streak: 4), log(streak: 9)]), 'Best streak: 9');
    expect(totals(TrackingType.binary, [log(completed: true), log(completed: false), log(completed: true)]), '2 of 3 sets completed');
  });

  test('a drill with no sets says so', () {
    expect(totals(TrackingType.accuracy, const []), 'No sets logged');
  });

  test('durations format as minutes and seconds', () {
    expect(formatDuration(0), '0:00');
    expect(formatDuration(75), '1:15');
    expect(formatDuration(600), '10:00');
  });
}
