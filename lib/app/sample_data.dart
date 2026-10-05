import 'package:flutter/material.dart';

import '../design/tokens/app_colors.dart';
import '../features/drills/models/drill.dart';

extension PillarPresentation on SkillPillar {
  String get label => switch (this) {
    SkillPillar.shooting => 'Shooting',
    SkillPillar.stickhandling => 'Stickhandling',
    SkillPillar.skating => 'Skating',
    SkillPillar.passing => 'Passing',
    SkillPillar.iqConditioning => 'Hockey IQ',
  };

  Color color(PillarColors colors) => switch (this) {
    SkillPillar.shooting => colors.shooting,
    SkillPillar.stickhandling => colors.stickhandling,
    SkillPillar.skating => colors.skating,
    SkillPillar.passing => colors.passing,
    SkillPillar.iqConditioning => colors.iqConditioning,
  };
}

extension TrackingPresentation on TrackingType {
  String get label => switch (this) {
    TrackingType.volume => 'Reps',
    TrackingType.duration => 'Duration',
    TrackingType.density => 'Shots per minute',
    TrackingType.accuracy => 'Accuracy',
    TrackingType.streak => 'Best streak',
    TrackingType.binary => 'Completion',
  };
}

extension LocationPresentation on LocationOption {
  String get label => switch (this) {
    LocationOption.ice => 'Ice',
    LocationOption.roller => 'Roller',
    LocationOption.drivewayGarage => 'Driveway / garage',
    LocationOption.basement => 'Basement',
    LocationOption.syntheticIce => 'Synthetic ice',
  };
}

extension InventoryPresentation on PuckInventory {
  String get label => switch (this) {
    PuckInventory.low => '1–10 pucks',
    PuckInventory.medium => '10–25 pucks',
    PuckInventory.high => '25+ pucks',
  };
}

extension BallPresentation on BallType {
  String get label => switch (this) {
    BallType.golfBall => 'Golf ball',
    BallType.trainingBall => 'Training ball',
    BallType.greenBiscuit => 'Green Biscuit',
  };
}

extension PasserPresentation on PasserType {
  String get label => switch (this) {
    PasserType.rebounder => 'Rebounder',
    PasserType.partner => 'Partner',
  };
}

extension DrillPresentation on Drill {
  SkillPillar get pillar => skillWeights.keys.first;
  String get prescriptionLabel {
    final prescription = defaultPrescription;
    final target = prescription.seconds != null
        ? '${prescription.seconds}s'
        : prescription.reps != null
        ? '${prescription.reps} reps'
        : trackingType == TrackingType.streak
        ? 'best streak'
        : 'complete';
    return '${prescription.sets} sets · $target';
  }
}

final sampleDrills = List<Drill>.unmodifiable([
  _drill('quick-release', 'Quick-release wrist shots', TrackingType.volume, SkillPillar.shooting, reps: 10,
    cues: ['Start with the puck close to your feet.', 'Load your stick, then snap your wrists.', 'Point your blade at the target.']),
  _drill('quiet-hands', 'Quiet hands, quick feet', TrackingType.duration, SkillPillar.stickhandling, seconds: 30,
    cues: ['Keep your top hand away from your body.', 'Look up between touches.', 'Stay light on your feet.']),
  _drill('shot-burst', '30-second shot burst', TrackingType.density, SkillPillar.shooting, seconds: 30,
    cues: ['Set your pucks within easy reach.', 'Reset your feet between shots.', 'Keep a smooth, repeatable release.']),
  _drill('pick-corners', 'Pick your corner', TrackingType.accuracy, SkillPillar.shooting, reps: 10,
    cues: ['Choose one corner for the full set.', 'Look at the target before you shoot.', 'Follow through toward your corner.']),
  _drill('partner-passes', 'Pass and settle', TrackingType.streak, SkillPillar.passing,
    cues: ['Show your blade as a target.', 'Cushion the pass as it arrives.', 'Send it back flat and on target.']),
  _drill('athletic-reset', 'Athletic stance reset', TrackingType.binary, SkillPillar.skating,
    cues: ['Bend at the knees, not the waist.', 'Keep your chest tall.', 'Hold your balance through each shift.']),
]);

Drill _drill(
  String id,
  String title,
  TrackingType type,
  SkillPillar pillar, {
  int? reps,
  int? seconds,
  required List<String> cues,
}) => Drill(
  id: id,
  title: title,
  mediaAssetPath: 'placeholder/$id',
  formCues: cues,
  trackingType: type,
  allowedLocations: const [LocationOption.drivewayGarage, LocationOption.basement],
  minPuckInventory: PuckInventory.low,
  requiresPasser: pillar == SkillPillar.passing,
  skillWeights: {pillar: 1},
  tier: AccessTier.free,
  supportedBalls: const [BallType.trainingBall, BallType.greenBiscuit],
  passerTypes: pillar == SkillPillar.passing ? const [PasserType.partner] : const [],
  defaultPrescription: DrillPrescription(sets: 2, reps: reps, seconds: seconds),
  estimatedSecondsPerSet: seconds ?? 45,
  difficulty: 2,
  tags: const ['Fundamentals'],
);
