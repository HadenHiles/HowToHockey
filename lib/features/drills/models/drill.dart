import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'drill.freezed.dart';
part 'drill.g.dart';

enum TrackingType { volume, duration, density, accuracy, streak, binary }

enum LocationOption { ice, roller, drivewayGarage, basement, syntheticIce }

enum PuckInventory { low, medium, high }

enum BallType { golfBall, trainingBall, greenBiscuit }

enum PasserType { rebounder, partner }

enum SkillPillar {
  shotAccuracy,
  hands,
  shotPower,
  passing,
  speedStrength,
  endurance,
}

enum AccessTier { free, pro }

@freezed
abstract class Drill with _$Drill {
  const factory Drill({
    required String id,
    required String title,
    required String mediaAssetPath,
    required List<String> formCues,
    required TrackingType trackingType,
    required List<LocationOption> allowedLocations,
    required PuckInventory minPuckInventory,
    required bool requiresPasser,
    @SkillWeightsConverter() required Map<SkillPillar, double> skillWeights,
    required AccessTier tier,
    required List<BallType> supportedBalls,
    required List<PasserType> passerTypes,
    @JsonKey(toJson: _serializeDrillPrescription) required DrillPrescription defaultPrescription,
    required int estimatedSecondsPerSet,
    required int difficulty,
    required List<String> tags,
    String? swapGroup,
  }) = _Drill;

  factory Drill.fromJson(Map<String, dynamic> json) => _$DrillFromJson(json);
}

Map<String, dynamic> _serializeDrillPrescription(DrillPrescription prescription) => prescription.toJson();

class SkillWeightsConverter extends JsonConverter<Map<SkillPillar, double>, Map<String, dynamic>> {
  const SkillWeightsConverter();

  @override
  Map<SkillPillar, double> fromJson(Map<String, dynamic> json) {
    final result = <SkillPillar, double>{};
    for (final entry in json.entries) {
      final pillar = switch (entry.key) {
        'shotAccuracy' => SkillPillar.shotAccuracy,
        'hands' || 'stickhandling' => SkillPillar.hands,
        'shotPower' || 'shooting' => SkillPillar.shotPower,
        'passing' => SkillPillar.passing,
        'speedStrength' || 'skating' => SkillPillar.speedStrength,
        'endurance' || 'iqConditioning' => SkillPillar.endurance,
        _ => throw FormatException('Unknown skill pillar "${entry.key}".'),
      };
      final weight = (entry.value as num).toDouble();
      result[pillar] = (result[pillar] ?? 0) + weight;
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson(Map<SkillPillar, double> object) => {
    for (final entry in object.entries) entry.key.name: entry.value,
  };
}

@freezed
abstract class DrillPrescription with _$DrillPrescription {
  const factory DrillPrescription({required int sets, int? reps, int? seconds, @Default(45) int restSeconds, String? targetLabel}) = _DrillPrescription;

  factory DrillPrescription.fromJson(Map<String, dynamic> json) => _$DrillPrescriptionFromJson(json);
}

@freezed
abstract class SetLog with _$SetLog {
  const factory SetLog({required int setIndex, int? reps, int? hits, int? seconds, int? streak, bool? completed, @TimestampConverter() required DateTime loggedAt}) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);
}

class TimestampConverter extends JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) => switch (json) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    String value => DateTime.parse(value).toUtc(),
    _ => throw const FormatException('Expected a Firestore Timestamp, DateTime, or ISO-8601 string.'),
  };

  @override
  Timestamp toJson(DateTime dateTime) => Timestamp.fromDate(dateTime);
}
