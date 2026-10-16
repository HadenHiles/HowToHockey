import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/drills/set_calculations.dart';

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

void main() {
  group('validateSetEntry', () {
    test('volume needs a non-negative rep count', () {
      validateSetEntry(TrackingType.volume, reps: 0);
      validateSetEntry(TrackingType.volume, reps: 12);
      expect(() => validateSetEntry(TrackingType.volume), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.volume, reps: -1), throwsA(isA<InvalidSetEntry>()));
    });

    test('duration needs a positive duration', () {
      validateSetEntry(TrackingType.duration, seconds: 30);
      expect(() => validateSetEntry(TrackingType.duration), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.duration, seconds: 0), throwsA(isA<InvalidSetEntry>()));
    });

    test('density needs shots and a positive duration', () {
      validateSetEntry(TrackingType.density, reps: 14, seconds: 30);
      expect(() => validateSetEntry(TrackingType.density, seconds: 30), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.density, reps: 14), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.density, reps: 14, seconds: 0), throwsA(isA<InvalidSetEntry>()));
    });

    test('accuracy requires hits no greater than shots taken', () {
      validateSetEntry(TrackingType.accuracy, reps: 10, hits: 10);
      validateSetEntry(TrackingType.accuracy, reps: 10, hits: 0);
      expect(() => validateSetEntry(TrackingType.accuracy, reps: 10, hits: 11), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.accuracy, reps: 0, hits: 0), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.accuracy, reps: 10), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.accuracy, reps: 10, hits: -1), throwsA(isA<InvalidSetEntry>()));
    });

    test('streak needs a non-negative number', () {
      validateSetEntry(TrackingType.streak, streak: 0);
      expect(() => validateSetEntry(TrackingType.streak), throwsA(isA<InvalidSetEntry>()));
      expect(() => validateSetEntry(TrackingType.streak, streak: -2), throwsA(isA<InvalidSetEntry>()));
    });

    test('binary needs an explicit answer', () {
      validateSetEntry(TrackingType.binary, completed: false);
      validateSetEntry(TrackingType.binary, completed: true);
      expect(() => validateSetEntry(TrackingType.binary), throwsA(isA<InvalidSetEntry>()));
    });
  });

  group('calculations', () {
    test('shots per minute is reps / seconds * 60', () {
      expect(shotsPerMinute(log(reps: 15, seconds: 30)), 30);
      expect(shotsPerMinute(log(reps: 10, seconds: 45)), closeTo(13.333, 0.001));
      expect(shotsPerMinute(log(reps: 0, seconds: 30)), 0);
      expect(shotsPerMinute(log(reps: 10, seconds: 0)), isNull);
      expect(shotsPerMinute(log(reps: 10)), isNull);
    });

    test('accuracy is hits / shots taken', () {
      expect(accuracyFraction(log(reps: 10, hits: 8)), 0.8);
      expect(accuracyFraction(log(reps: 10, hits: 0)), 0);
      expect(accuracyFraction(log(reps: 0, hits: 0)), isNull);
      expect(accuracyFraction(log(reps: 10)), isNull);
    });

    test('active time uses the measured time, else the drill estimate', () {
      final drill = drillOf(TrackingType.volume, estimated: 55);
      expect(activeSecondsForSet(log(reps: 10), drill), 55);
      expect(activeSecondsForSet(log(reps: 10, seconds: 20), drill), 20);
    });
  });

  group('summarizeDrill', () {
    test('volume adds reps and estimated time', () {
      final totals = summarizeDrill(drillOf(TrackingType.volume, estimated: 50), [log(reps: 10), log(reps: 12)]);
      expect((totals.sets, totals.reps, totals.seconds), (2, 22, 100));
    });

    test('accuracy totals hits over shots taken', () {
      final totals = summarizeDrill(drillOf(TrackingType.accuracy), [log(reps: 10, hits: 8), log(reps: 10, hits: 6)]);
      expect((totals.hits, totals.attempts), (14, 20));
      expect(totals.accuracy, 0.7);
    });

    test('accuracy is null when nothing was logged', () {
      expect(summarizeDrill(drillOf(TrackingType.accuracy), const []).accuracy, isNull);
    });

    test('density averages shots per minute over measured time', () {
      final totals = summarizeDrill(drillOf(TrackingType.density), [log(reps: 15, seconds: 30), log(reps: 20, seconds: 30)]);
      expect((totals.reps, totals.seconds), (35, 60));
      expect(totals.averageShotsPerMinute, 35);
    });

    test('streak keeps the best run', () {
      expect(summarizeDrill(drillOf(TrackingType.streak), [log(streak: 4), log(streak: 9), log(streak: 6)]).bestStreak, 9);
    });

    test('binary counts completed sets', () {
      final totals = summarizeDrill(drillOf(TrackingType.binary), [log(completed: true), log(completed: false), log(completed: true)]);
      expect((totals.sets, totals.completedSets), (3, 2));
    });

    test('duration adds the timed seconds', () {
      final totals = summarizeDrill(drillOf(TrackingType.duration), [log(seconds: 30), log(seconds: 45)]);
      expect(totals.seconds, 75);
    });
  });
}
