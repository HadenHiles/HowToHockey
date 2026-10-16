import 'package:flutter/material.dart';

import '../design/tokens/app_colors.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';

extension PillarPresentation on SkillPillar {
  IconData get icon => switch (this) {
    SkillPillar.shotAccuracy => Icons.gps_fixed,
    SkillPillar.hands => Icons.bolt,
    SkillPillar.shotPower => Icons.sports_hockey,
    SkillPillar.passing => Icons.swap_horiz,
    SkillPillar.speedStrength => Icons.speed,
    SkillPillar.endurance => Icons.favorite_outline,
  };

  String get label => switch (this) {
    SkillPillar.shotAccuracy => 'Accuracy',
    SkillPillar.hands => 'Hands',
    SkillPillar.shotPower => 'Power',
    SkillPillar.passing => 'Passing',
    SkillPillar.speedStrength => 'Speed/Strength',
    SkillPillar.endurance => 'Endurance',
  };

  Color color(PillarColors colors) => switch (this) {
    SkillPillar.shotAccuracy => colors.shotAccuracy,
    SkillPillar.hands => colors.hands,
    SkillPillar.shotPower => colors.shotPower,
    SkillPillar.passing => colors.passing,
    SkillPillar.speedStrength => colors.speedStrength,
    SkillPillar.endurance => colors.endurance,
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
  SkillPillar get pillar => primaryPillar(this);
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
  _drill(
    'quick-release-wrist-shots',
    'Quick-release wrist shots',
    TrackingType.volume,
    SkillPillar.shotPower,
    reps: 10,
    cues: ['Start with the puck close to your feet.', 'Load the stick, then snap your wrists.', 'Finish with your blade pointing at the target.'],
  ),
  _drill(
    'quiet-hands-quick-feet',
    'Quiet hands, quick feet',
    TrackingType.duration,
    SkillPillar.hands,
    seconds: 30,
    cues: ['Keep your top hand out in front of you.', 'Eyes up between touches.', 'Stay light on your feet.'],
  ),
  _drill(
    'shot-burst-30',
    '30-second shot burst',
    TrackingType.density,
    SkillPillar.endurance,
    seconds: 30,
    cues: ['Set your pucks within easy reach.', 'Reset your feet after every shot.', 'Keep your release smooth and the same each time.'],
  ),
  _drill(
    'pick-your-corner',
    'Pick your corner',
    TrackingType.accuracy,
    SkillPillar.shotAccuracy,
    reps: 10,
    cues: ['Pick one corner for the whole set.', 'Look at your target before you shoot.', 'Follow through toward that corner.'],
  ),
  _drill(
    'pass-and-settle',
    'Pass and settle',
    TrackingType.streak,
    SkillPillar.passing,
    cues: ['Give your partner your blade as a target.', 'Soften your hands to cushion the pass.', 'Send it back flat and on the tape.'],
  ),
  _drill(
    'athletic-stance-reset',
    'Athletic stance reset',
    TrackingType.binary,
    SkillPillar.speedStrength,
    cues: ['Bend at the knees, not the waist.', 'Keep your chest tall.', 'Stay balanced through every rep.'],
  ),
]);

Drill _drill(String id, String title, TrackingType type, SkillPillar pillar, {int? reps, int? seconds, required List<String> cues}) => Drill(
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
