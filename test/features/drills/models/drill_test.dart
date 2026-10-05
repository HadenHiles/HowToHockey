import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';

void main() {
  group('Drill serialization', () {
    test('round-trips the catalog model with stable enum names', () {
      final drill = Drill(
        id: 'quick-release',
        title: 'Quick Release',
        mediaAssetPath: 'drills/quick-release.mp4',
        formCues: const ['Keep the puck close'],
        trackingType: TrackingType.accuracy,
        allowedLocations: const [LocationOption.drivewayGarage],
        minPuckInventory: PuckInventory.medium,
        requiresPasser: true,
        skillWeights: const {SkillPillar.shotAccuracy: 0.75, SkillPillar.endurance: 0.25},
        tier: AccessTier.free,
        supportedBalls: const [BallType.greenBiscuit],
        passerTypes: const [PasserType.partner],
        defaultPrescription: const DrillPrescription(sets: 3, reps: 10, targetLabel: 'Top-right pipe'),
        estimatedSecondsPerSet: 90,
        difficulty: 2,
        tags: const ['quick-release'],
        swapGroup: 'release-shot',
      );

      final json = drill.toJson();

      expect(json['trackingType'], 'accuracy');
      expect(json['allowedLocations'], ['drivewayGarage']);
      expect(json['skillWeights'], {'shotAccuracy': 0.75, 'endurance': 0.25});
      expect(Drill.fromJson(json), drill);
    });

    test('applies prescription defaults when decoding older catalog data', () {
      final prescription = DrillPrescription.fromJson({'sets': 4});

      expect(prescription.sets, 4);
      expect(prescription.restSeconds, 45);
      expect(prescription.reps, isNull);
      expect(prescription.seconds, isNull);
    });

    test('migrates the previous five-skill keys when decoding catalog data', () {
      final drill = Drill.fromJson({
        'id': 'legacy',
        'title': 'Legacy drill',
        'mediaAssetPath': 'legacy',
        'formCues': <String>[],
        'trackingType': 'volume',
        'allowedLocations': ['ice'],
        'minPuckInventory': 'low',
        'requiresPasser': false,
        'skillWeights': {'shooting': 0.5, 'stickhandling': 0.25, 'iqConditioning': 0.25},
        'tier': 'free',
        'supportedBalls': <String>[],
        'passerTypes': <String>[],
        'defaultPrescription': {'sets': 1},
        'estimatedSecondsPerSet': 30,
        'difficulty': 1,
        'tags': <String>[],
      });

      expect(drill.skillWeights, {SkillPillar.shotPower: 0.5, SkillPillar.hands: 0.25, SkillPillar.endurance: 0.25});
    });
  });

  group('SetLog serialization', () {
    test('reads and writes Firestore timestamps', () {
      final loggedAt = DateTime.utc(2026, 10, 5, 14, 30);
      final log = SetLog(setIndex: 1, reps: 12, hits: 8, loggedAt: loggedAt);

      final json = log.toJson();

      expect(json['loggedAt'], Timestamp.fromDate(loggedAt));
      expect(SetLog.fromJson(json), log);
    });

    test('rejects an unsupported timestamp representation', () {
      expect(
        () => SetLog.fromJson({
          'setIndex': 1,
          'loggedAt': {'seconds': 1},
        }),
        throwsFormatException,
      );
    });
  });
}
