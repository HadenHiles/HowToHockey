// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Drill _$DrillFromJson(Map<String, dynamic> json) => _Drill(
  id: json['id'] as String,
  title: json['title'] as String,
  mediaAssetPath: json['mediaAssetPath'] as String,
  formCues: (json['formCues'] as List<dynamic>).map((e) => e as String).toList(),
  trackingType: $enumDecode(_$TrackingTypeEnumMap, json['trackingType']),
  allowedLocations: (json['allowedLocations'] as List<dynamic>).map((e) => $enumDecode(_$LocationOptionEnumMap, e)).toList(),
  minPuckInventory: $enumDecode(_$PuckInventoryEnumMap, json['minPuckInventory']),
  requiresPasser: json['requiresPasser'] as bool,
  skillWeights: const SkillWeightsConverter().fromJson(json['skillWeights'] as Map<String, dynamic>),
  tier: $enumDecode(_$AccessTierEnumMap, json['tier']),
  supportedBalls: (json['supportedBalls'] as List<dynamic>).map((e) => $enumDecode(_$BallTypeEnumMap, e)).toList(),
  passerTypes: (json['passerTypes'] as List<dynamic>).map((e) => $enumDecode(_$PasserTypeEnumMap, e)).toList(),
  defaultPrescription: DrillPrescription.fromJson(json['defaultPrescription'] as Map<String, dynamic>),
  estimatedSecondsPerSet: (json['estimatedSecondsPerSet'] as num).toInt(),
  difficulty: (json['difficulty'] as num).toInt(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  swapGroup: json['swapGroup'] as String?,
);

Map<String, dynamic> _$DrillToJson(_Drill instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'mediaAssetPath': instance.mediaAssetPath,
  'formCues': instance.formCues,
  'trackingType': _$TrackingTypeEnumMap[instance.trackingType]!,
  'allowedLocations': instance.allowedLocations.map((e) => _$LocationOptionEnumMap[e]!).toList(),
  'minPuckInventory': _$PuckInventoryEnumMap[instance.minPuckInventory]!,
  'requiresPasser': instance.requiresPasser,
  'skillWeights': const SkillWeightsConverter().toJson(instance.skillWeights),
  'tier': _$AccessTierEnumMap[instance.tier]!,
  'supportedBalls': instance.supportedBalls.map((e) => _$BallTypeEnumMap[e]!).toList(),
  'passerTypes': instance.passerTypes.map((e) => _$PasserTypeEnumMap[e]!).toList(),
  'defaultPrescription': _serializeDrillPrescription(instance.defaultPrescription),
  'estimatedSecondsPerSet': instance.estimatedSecondsPerSet,
  'difficulty': instance.difficulty,
  'tags': instance.tags,
  'swapGroup': instance.swapGroup,
};

const _$TrackingTypeEnumMap = {
  TrackingType.volume: 'volume',
  TrackingType.duration: 'duration',
  TrackingType.density: 'density',
  TrackingType.accuracy: 'accuracy',
  TrackingType.streak: 'streak',
  TrackingType.binary: 'binary',
};

const _$LocationOptionEnumMap = {
  LocationOption.ice: 'ice',
  LocationOption.roller: 'roller',
  LocationOption.drivewayGarage: 'drivewayGarage',
  LocationOption.basement: 'basement',
  LocationOption.syntheticIce: 'syntheticIce',
};

const _$PuckInventoryEnumMap = {PuckInventory.low: 'low', PuckInventory.medium: 'medium', PuckInventory.high: 'high'};

const _$AccessTierEnumMap = {AccessTier.free: 'free', AccessTier.pro: 'pro'};

const _$BallTypeEnumMap = {BallType.golfBall: 'golfBall', BallType.trainingBall: 'trainingBall', BallType.greenBiscuit: 'greenBiscuit'};

const _$PasserTypeEnumMap = {PasserType.rebounder: 'rebounder', PasserType.partner: 'partner'};

_DrillPrescription _$DrillPrescriptionFromJson(Map<String, dynamic> json) => _DrillPrescription(
  sets: (json['sets'] as num).toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  seconds: (json['seconds'] as num?)?.toInt(),
  restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 45,
  targetLabel: json['targetLabel'] as String?,
);

Map<String, dynamic> _$DrillPrescriptionToJson(_DrillPrescription instance) => <String, dynamic>{
  'sets': instance.sets,
  'reps': instance.reps,
  'seconds': instance.seconds,
  'restSeconds': instance.restSeconds,
  'targetLabel': instance.targetLabel,
};

_SetLog _$SetLogFromJson(Map<String, dynamic> json) => _SetLog(
  setIndex: (json['setIndex'] as num).toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  hits: (json['hits'] as num?)?.toInt(),
  seconds: (json['seconds'] as num?)?.toInt(),
  streak: (json['streak'] as num?)?.toInt(),
  completed: json['completed'] as bool?,
  loggedAt: const TimestampConverter().fromJson(json['loggedAt']),
);

Map<String, dynamic> _$SetLogToJson(_SetLog instance) => <String, dynamic>{
  'setIndex': instance.setIndex,
  'reps': instance.reps,
  'hits': instance.hits,
  'seconds': instance.seconds,
  'streak': instance.streak,
  'completed': instance.completed,
  'loggedAt': const TimestampConverter().toJson(instance.loggedAt),
};
