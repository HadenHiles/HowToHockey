// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Drill {

 String get id; String get title; String get mediaAssetPath; List<String> get formCues; TrackingType get trackingType; List<LocationOption> get allowedLocations; PuckInventory get minPuckInventory; bool get requiresPasser; Map<SkillPillar, double> get skillWeights; AccessTier get tier; List<BallType> get supportedBalls; List<PasserType> get passerTypes;@JsonKey(toJson: _serializeDrillPrescription) DrillPrescription get defaultPrescription; int get estimatedSecondsPerSet; int get difficulty; List<String> get tags; String? get swapGroup;
/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrillCopyWith<Drill> get copyWith => _$DrillCopyWithImpl<Drill>(this as Drill, _$identity);

  /// Serializes this Drill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Drill;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Drill&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.mediaAssetPath, _this.mediaAssetPath) || other.mediaAssetPath == _this.mediaAssetPath)&&const DeepCollectionEquality().equals(other.formCues, _this.formCues)&&(identical(other.trackingType, _this.trackingType) || other.trackingType == _this.trackingType)&&const DeepCollectionEquality().equals(other.allowedLocations, _this.allowedLocations)&&(identical(other.minPuckInventory, _this.minPuckInventory) || other.minPuckInventory == _this.minPuckInventory)&&(identical(other.requiresPasser, _this.requiresPasser) || other.requiresPasser == _this.requiresPasser)&&const DeepCollectionEquality().equals(other.skillWeights, _this.skillWeights)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&const DeepCollectionEquality().equals(other.supportedBalls, _this.supportedBalls)&&const DeepCollectionEquality().equals(other.passerTypes, _this.passerTypes)&&(identical(other.defaultPrescription, _this.defaultPrescription) || other.defaultPrescription == _this.defaultPrescription)&&(identical(other.estimatedSecondsPerSet, _this.estimatedSecondsPerSet) || other.estimatedSecondsPerSet == _this.estimatedSecondsPerSet)&&(identical(other.difficulty, _this.difficulty) || other.difficulty == _this.difficulty)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.swapGroup, _this.swapGroup) || other.swapGroup == _this.swapGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Drill;
  return Object.hash(runtimeType,_this.id,_this.title,_this.mediaAssetPath,const DeepCollectionEquality().hash(_this.formCues),_this.trackingType,const DeepCollectionEquality().hash(_this.allowedLocations),_this.minPuckInventory,_this.requiresPasser,const DeepCollectionEquality().hash(_this.skillWeights),_this.tier,const DeepCollectionEquality().hash(_this.supportedBalls),const DeepCollectionEquality().hash(_this.passerTypes),_this.defaultPrescription,_this.estimatedSecondsPerSet,_this.difficulty,const DeepCollectionEquality().hash(_this.tags),_this.swapGroup);
}

@override
String toString() {
  final _this = this as Drill;
  return 'Drill(id: ${_this.id}, title: ${_this.title}, mediaAssetPath: ${_this.mediaAssetPath}, formCues: ${_this.formCues}, trackingType: ${_this.trackingType}, allowedLocations: ${_this.allowedLocations}, minPuckInventory: ${_this.minPuckInventory}, requiresPasser: ${_this.requiresPasser}, skillWeights: ${_this.skillWeights}, tier: ${_this.tier}, supportedBalls: ${_this.supportedBalls}, passerTypes: ${_this.passerTypes}, defaultPrescription: ${_this.defaultPrescription}, estimatedSecondsPerSet: ${_this.estimatedSecondsPerSet}, difficulty: ${_this.difficulty}, tags: ${_this.tags}, swapGroup: ${_this.swapGroup})';
}


}

/// @nodoc
abstract mixin class $DrillCopyWith<$Res>  {
  factory $DrillCopyWith(Drill value, $Res Function(Drill) _then) = _$DrillCopyWithImpl;
@useResult
$Res call({
 String id, String title, String mediaAssetPath, List<String> formCues, TrackingType trackingType, List<LocationOption> allowedLocations, PuckInventory minPuckInventory, bool requiresPasser, Map<SkillPillar, double> skillWeights, AccessTier tier, List<BallType> supportedBalls, List<PasserType> passerTypes,@JsonKey(toJson: _serializeDrillPrescription) DrillPrescription defaultPrescription, int estimatedSecondsPerSet, int difficulty, List<String> tags, String? swapGroup
});


$DrillPrescriptionCopyWith<$Res> get defaultPrescription;

}
/// @nodoc
class _$DrillCopyWithImpl<$Res>
    implements $DrillCopyWith<$Res> {
  _$DrillCopyWithImpl(this._self, this._then);

  final Drill _self;
  final $Res Function(Drill) _then;

/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mediaAssetPath = null,Object? formCues = null,Object? trackingType = null,Object? allowedLocations = null,Object? minPuckInventory = null,Object? requiresPasser = null,Object? skillWeights = null,Object? tier = null,Object? supportedBalls = null,Object? passerTypes = null,Object? defaultPrescription = null,Object? estimatedSecondsPerSet = null,Object? difficulty = null,Object? tags = null,Object? swapGroup = freezed,}) {
  return _then(Drill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaAssetPath: null == mediaAssetPath ? _self.mediaAssetPath : mediaAssetPath // ignore: cast_nullable_to_non_nullable
as String,formCues: null == formCues ? _self.formCues : formCues // ignore: cast_nullable_to_non_nullable
as List<String>,trackingType: null == trackingType ? _self.trackingType : trackingType // ignore: cast_nullable_to_non_nullable
as TrackingType,allowedLocations: null == allowedLocations ? _self.allowedLocations : allowedLocations // ignore: cast_nullable_to_non_nullable
as List<LocationOption>,minPuckInventory: null == minPuckInventory ? _self.minPuckInventory : minPuckInventory // ignore: cast_nullable_to_non_nullable
as PuckInventory,requiresPasser: null == requiresPasser ? _self.requiresPasser : requiresPasser // ignore: cast_nullable_to_non_nullable
as bool,skillWeights: null == skillWeights ? _self.skillWeights : skillWeights // ignore: cast_nullable_to_non_nullable
as Map<SkillPillar, double>,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as AccessTier,supportedBalls: null == supportedBalls ? _self.supportedBalls : supportedBalls // ignore: cast_nullable_to_non_nullable
as List<BallType>,passerTypes: null == passerTypes ? _self.passerTypes : passerTypes // ignore: cast_nullable_to_non_nullable
as List<PasserType>,defaultPrescription: null == defaultPrescription ? _self.defaultPrescription : defaultPrescription // ignore: cast_nullable_to_non_nullable
as DrillPrescription,estimatedSecondsPerSet: null == estimatedSecondsPerSet ? _self.estimatedSecondsPerSet : estimatedSecondsPerSet // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,swapGroup: freezed == swapGroup ? _self.swapGroup : swapGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrillPrescriptionCopyWith<$Res> get defaultPrescription {

  return $DrillPrescriptionCopyWith<$Res>(_self.defaultPrescription, (value) {
    return _then(_self.copyWith(defaultPrescription: value));
  });
}
}


/// Adds pattern-matching-related methods to [Drill].
extension DrillPatterns on Drill {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Drill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Drill() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Drill value)  $default,){
final _that = this;
switch (_that) {
case _Drill():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Drill value)?  $default,){
final _that = this;
switch (_that) {
case _Drill() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String mediaAssetPath,  List<String> formCues,  TrackingType trackingType,  List<LocationOption> allowedLocations,  PuckInventory minPuckInventory,  bool requiresPasser,  Map<SkillPillar, double> skillWeights,  AccessTier tier,  List<BallType> supportedBalls,  List<PasserType> passerTypes, @JsonKey(toJson: _serializeDrillPrescription)  DrillPrescription defaultPrescription,  int estimatedSecondsPerSet,  int difficulty,  List<String> tags,  String? swapGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Drill() when $default != null:
return $default(_that.id,_that.title,_that.mediaAssetPath,_that.formCues,_that.trackingType,_that.allowedLocations,_that.minPuckInventory,_that.requiresPasser,_that.skillWeights,_that.tier,_that.supportedBalls,_that.passerTypes,_that.defaultPrescription,_that.estimatedSecondsPerSet,_that.difficulty,_that.tags,_that.swapGroup);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String mediaAssetPath,  List<String> formCues,  TrackingType trackingType,  List<LocationOption> allowedLocations,  PuckInventory minPuckInventory,  bool requiresPasser,  Map<SkillPillar, double> skillWeights,  AccessTier tier,  List<BallType> supportedBalls,  List<PasserType> passerTypes, @JsonKey(toJson: _serializeDrillPrescription)  DrillPrescription defaultPrescription,  int estimatedSecondsPerSet,  int difficulty,  List<String> tags,  String? swapGroup)  $default,) {final _that = this;
switch (_that) {
case _Drill():
return $default(_that.id,_that.title,_that.mediaAssetPath,_that.formCues,_that.trackingType,_that.allowedLocations,_that.minPuckInventory,_that.requiresPasser,_that.skillWeights,_that.tier,_that.supportedBalls,_that.passerTypes,_that.defaultPrescription,_that.estimatedSecondsPerSet,_that.difficulty,_that.tags,_that.swapGroup);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String mediaAssetPath,  List<String> formCues,  TrackingType trackingType,  List<LocationOption> allowedLocations,  PuckInventory minPuckInventory,  bool requiresPasser,  Map<SkillPillar, double> skillWeights,  AccessTier tier,  List<BallType> supportedBalls,  List<PasserType> passerTypes, @JsonKey(toJson: _serializeDrillPrescription)  DrillPrescription defaultPrescription,  int estimatedSecondsPerSet,  int difficulty,  List<String> tags,  String? swapGroup)?  $default,) {final _that = this;
switch (_that) {
case _Drill() when $default != null:
return $default(_that.id,_that.title,_that.mediaAssetPath,_that.formCues,_that.trackingType,_that.allowedLocations,_that.minPuckInventory,_that.requiresPasser,_that.skillWeights,_that.tier,_that.supportedBalls,_that.passerTypes,_that.defaultPrescription,_that.estimatedSecondsPerSet,_that.difficulty,_that.tags,_that.swapGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Drill implements Drill {
  const _Drill({required this.id, required this.title, required this.mediaAssetPath, required  List<String> formCues, required this.trackingType, required  List<LocationOption> allowedLocations, required this.minPuckInventory, required this.requiresPasser, required  Map<SkillPillar, double> skillWeights, required this.tier, required  List<BallType> supportedBalls, required  List<PasserType> passerTypes, @JsonKey(toJson: _serializeDrillPrescription) required this.defaultPrescription, required this.estimatedSecondsPerSet, required this.difficulty, required  List<String> tags, this.swapGroup}): _formCues = formCues,_allowedLocations = allowedLocations,_skillWeights = skillWeights,_supportedBalls = supportedBalls,_passerTypes = passerTypes,_tags = tags;
  factory _Drill.fromJson(Map<String, dynamic> json) => _$DrillFromJson(json);

@override final  String id;
@override final  String title;
@override final  String mediaAssetPath;
 final  List<String> _formCues;
@override List<String> get formCues {
  if (_formCues is EqualUnmodifiableListView) return _formCues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_formCues);
}

@override final  TrackingType trackingType;
 final  List<LocationOption> _allowedLocations;
@override List<LocationOption> get allowedLocations {
  if (_allowedLocations is EqualUnmodifiableListView) return _allowedLocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedLocations);
}

@override final  PuckInventory minPuckInventory;
@override final  bool requiresPasser;
 final  Map<SkillPillar, double> _skillWeights;
@override Map<SkillPillar, double> get skillWeights {
  if (_skillWeights is EqualUnmodifiableMapView) return _skillWeights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skillWeights);
}

@override final  AccessTier tier;
 final  List<BallType> _supportedBalls;
@override List<BallType> get supportedBalls {
  if (_supportedBalls is EqualUnmodifiableListView) return _supportedBalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedBalls);
}

 final  List<PasserType> _passerTypes;
@override List<PasserType> get passerTypes {
  if (_passerTypes is EqualUnmodifiableListView) return _passerTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_passerTypes);
}

@override@JsonKey(toJson: _serializeDrillPrescription) final  DrillPrescription defaultPrescription;
@override final  int estimatedSecondsPerSet;
@override final  int difficulty;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String? swapGroup;

/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrillCopyWith<_Drill> get copyWith => __$DrillCopyWithImpl<_Drill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrillToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Drill&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaAssetPath, mediaAssetPath) || other.mediaAssetPath == mediaAssetPath)&&const DeepCollectionEquality().equals(other.formCues, _formCues)&&(identical(other.trackingType, trackingType) || other.trackingType == trackingType)&&const DeepCollectionEquality().equals(other.allowedLocations, _allowedLocations)&&(identical(other.minPuckInventory, minPuckInventory) || other.minPuckInventory == minPuckInventory)&&(identical(other.requiresPasser, requiresPasser) || other.requiresPasser == requiresPasser)&&const DeepCollectionEquality().equals(other.skillWeights, _skillWeights)&&(identical(other.tier, tier) || other.tier == tier)&&const DeepCollectionEquality().equals(other.supportedBalls, _supportedBalls)&&const DeepCollectionEquality().equals(other.passerTypes, _passerTypes)&&(identical(other.defaultPrescription, defaultPrescription) || other.defaultPrescription == defaultPrescription)&&(identical(other.estimatedSecondsPerSet, estimatedSecondsPerSet) || other.estimatedSecondsPerSet == estimatedSecondsPerSet)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.swapGroup, swapGroup) || other.swapGroup == swapGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,mediaAssetPath,const DeepCollectionEquality().hash(_formCues),trackingType,const DeepCollectionEquality().hash(_allowedLocations),minPuckInventory,requiresPasser,const DeepCollectionEquality().hash(_skillWeights),tier,const DeepCollectionEquality().hash(_supportedBalls),const DeepCollectionEquality().hash(_passerTypes),defaultPrescription,estimatedSecondsPerSet,difficulty,const DeepCollectionEquality().hash(_tags),swapGroup);
}

@override
String toString() {
    return 'Drill(id: $id, title: $title, mediaAssetPath: $mediaAssetPath, formCues: $formCues, trackingType: $trackingType, allowedLocations: $allowedLocations, minPuckInventory: $minPuckInventory, requiresPasser: $requiresPasser, skillWeights: $skillWeights, tier: $tier, supportedBalls: $supportedBalls, passerTypes: $passerTypes, defaultPrescription: $defaultPrescription, estimatedSecondsPerSet: $estimatedSecondsPerSet, difficulty: $difficulty, tags: $tags, swapGroup: $swapGroup)';
}


}

/// @nodoc
abstract mixin class _$DrillCopyWith<$Res> implements $DrillCopyWith<$Res> {
  factory _$DrillCopyWith(_Drill value, $Res Function(_Drill) _then) = __$DrillCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String mediaAssetPath, List<String> formCues, TrackingType trackingType, List<LocationOption> allowedLocations, PuckInventory minPuckInventory, bool requiresPasser, Map<SkillPillar, double> skillWeights, AccessTier tier, List<BallType> supportedBalls, List<PasserType> passerTypes,@JsonKey(toJson: _serializeDrillPrescription) DrillPrescription defaultPrescription, int estimatedSecondsPerSet, int difficulty, List<String> tags, String? swapGroup
});


@override $DrillPrescriptionCopyWith<$Res> get defaultPrescription;

}
/// @nodoc
class __$DrillCopyWithImpl<$Res>
    implements _$DrillCopyWith<$Res> {
  __$DrillCopyWithImpl(this._self, this._then);

  final _Drill _self;
  final $Res Function(_Drill) _then;

/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mediaAssetPath = null,Object? formCues = null,Object? trackingType = null,Object? allowedLocations = null,Object? minPuckInventory = null,Object? requiresPasser = null,Object? skillWeights = null,Object? tier = null,Object? supportedBalls = null,Object? passerTypes = null,Object? defaultPrescription = null,Object? estimatedSecondsPerSet = null,Object? difficulty = null,Object? tags = null,Object? swapGroup = freezed,}) {
  return _then(_Drill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaAssetPath: null == mediaAssetPath ? _self.mediaAssetPath : mediaAssetPath // ignore: cast_nullable_to_non_nullable
as String,formCues: null == formCues ? _self._formCues : formCues // ignore: cast_nullable_to_non_nullable
as List<String>,trackingType: null == trackingType ? _self.trackingType : trackingType // ignore: cast_nullable_to_non_nullable
as TrackingType,allowedLocations: null == allowedLocations ? _self._allowedLocations : allowedLocations // ignore: cast_nullable_to_non_nullable
as List<LocationOption>,minPuckInventory: null == minPuckInventory ? _self.minPuckInventory : minPuckInventory // ignore: cast_nullable_to_non_nullable
as PuckInventory,requiresPasser: null == requiresPasser ? _self.requiresPasser : requiresPasser // ignore: cast_nullable_to_non_nullable
as bool,skillWeights: null == skillWeights ? _self._skillWeights : skillWeights // ignore: cast_nullable_to_non_nullable
as Map<SkillPillar, double>,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as AccessTier,supportedBalls: null == supportedBalls ? _self._supportedBalls : supportedBalls // ignore: cast_nullable_to_non_nullable
as List<BallType>,passerTypes: null == passerTypes ? _self._passerTypes : passerTypes // ignore: cast_nullable_to_non_nullable
as List<PasserType>,defaultPrescription: null == defaultPrescription ? _self.defaultPrescription : defaultPrescription // ignore: cast_nullable_to_non_nullable
as DrillPrescription,estimatedSecondsPerSet: null == estimatedSecondsPerSet ? _self.estimatedSecondsPerSet : estimatedSecondsPerSet // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,swapGroup: freezed == swapGroup ? _self.swapGroup : swapGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Drill
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrillPrescriptionCopyWith<$Res> get defaultPrescription {

  return $DrillPrescriptionCopyWith<$Res>(_self.defaultPrescription, (value) {
    return _then(_self.copyWith(defaultPrescription: value));
  });
}
}


/// @nodoc
mixin _$DrillPrescription {

 int get sets; int? get reps; int? get seconds; int get restSeconds; String? get targetLabel;
/// Create a copy of DrillPrescription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrillPrescriptionCopyWith<DrillPrescription> get copyWith => _$DrillPrescriptionCopyWithImpl<DrillPrescription>(this as DrillPrescription, _$identity);

  /// Serializes this DrillPrescription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DrillPrescription;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrillPrescription&&(identical(other.sets, _this.sets) || other.sets == _this.sets)&&(identical(other.reps, _this.reps) || other.reps == _this.reps)&&(identical(other.seconds, _this.seconds) || other.seconds == _this.seconds)&&(identical(other.restSeconds, _this.restSeconds) || other.restSeconds == _this.restSeconds)&&(identical(other.targetLabel, _this.targetLabel) || other.targetLabel == _this.targetLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DrillPrescription;
  return Object.hash(runtimeType,_this.sets,_this.reps,_this.seconds,_this.restSeconds,_this.targetLabel);
}

@override
String toString() {
  final _this = this as DrillPrescription;
  return 'DrillPrescription(sets: ${_this.sets}, reps: ${_this.reps}, seconds: ${_this.seconds}, restSeconds: ${_this.restSeconds}, targetLabel: ${_this.targetLabel})';
}


}

/// @nodoc
abstract mixin class $DrillPrescriptionCopyWith<$Res>  {
  factory $DrillPrescriptionCopyWith(DrillPrescription value, $Res Function(DrillPrescription) _then) = _$DrillPrescriptionCopyWithImpl;
@useResult
$Res call({
 int sets, int? reps, int? seconds, int restSeconds, String? targetLabel
});




}
/// @nodoc
class _$DrillPrescriptionCopyWithImpl<$Res>
    implements $DrillPrescriptionCopyWith<$Res> {
  _$DrillPrescriptionCopyWithImpl(this._self, this._then);

  final DrillPrescription _self;
  final $Res Function(DrillPrescription) _then;

/// Create a copy of DrillPrescription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sets = null,Object? reps = freezed,Object? seconds = freezed,Object? restSeconds = null,Object? targetLabel = freezed,}) {
  return _then(DrillPrescription(
sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,seconds: freezed == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DrillPrescription].
extension DrillPrescriptionPatterns on DrillPrescription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrillPrescription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrillPrescription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrillPrescription value)  $default,){
final _that = this;
switch (_that) {
case _DrillPrescription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrillPrescription value)?  $default,){
final _that = this;
switch (_that) {
case _DrillPrescription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sets,  int? reps,  int? seconds,  int restSeconds,  String? targetLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrillPrescription() when $default != null:
return $default(_that.sets,_that.reps,_that.seconds,_that.restSeconds,_that.targetLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sets,  int? reps,  int? seconds,  int restSeconds,  String? targetLabel)  $default,) {final _that = this;
switch (_that) {
case _DrillPrescription():
return $default(_that.sets,_that.reps,_that.seconds,_that.restSeconds,_that.targetLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sets,  int? reps,  int? seconds,  int restSeconds,  String? targetLabel)?  $default,) {final _that = this;
switch (_that) {
case _DrillPrescription() when $default != null:
return $default(_that.sets,_that.reps,_that.seconds,_that.restSeconds,_that.targetLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrillPrescription implements DrillPrescription {
  const _DrillPrescription({required this.sets, this.reps, this.seconds, this.restSeconds = 45, this.targetLabel});
  factory _DrillPrescription.fromJson(Map<String, dynamic> json) => _$DrillPrescriptionFromJson(json);

@override final  int sets;
@override final  int? reps;
@override final  int? seconds;
@override@JsonKey() final  int restSeconds;
@override final  String? targetLabel;

/// Create a copy of DrillPrescription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrillPrescriptionCopyWith<_DrillPrescription> get copyWith => __$DrillPrescriptionCopyWithImpl<_DrillPrescription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrillPrescriptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrillPrescription&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sets,reps,seconds,restSeconds,targetLabel);
}

@override
String toString() {
    return 'DrillPrescription(sets: $sets, reps: $reps, seconds: $seconds, restSeconds: $restSeconds, targetLabel: $targetLabel)';
}


}

/// @nodoc
abstract mixin class _$DrillPrescriptionCopyWith<$Res> implements $DrillPrescriptionCopyWith<$Res> {
  factory _$DrillPrescriptionCopyWith(_DrillPrescription value, $Res Function(_DrillPrescription) _then) = __$DrillPrescriptionCopyWithImpl;
@override @useResult
$Res call({
 int sets, int? reps, int? seconds, int restSeconds, String? targetLabel
});




}
/// @nodoc
class __$DrillPrescriptionCopyWithImpl<$Res>
    implements _$DrillPrescriptionCopyWith<$Res> {
  __$DrillPrescriptionCopyWithImpl(this._self, this._then);

  final _DrillPrescription _self;
  final $Res Function(_DrillPrescription) _then;

/// Create a copy of DrillPrescription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sets = null,Object? reps = freezed,Object? seconds = freezed,Object? restSeconds = null,Object? targetLabel = freezed,}) {
  return _then(_DrillPrescription(
sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,seconds: freezed == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SetLog {

 int get setIndex; int? get reps; int? get hits; int? get seconds; int? get streak; bool? get completed;@TimestampConverter() DateTime get loggedAt;
/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetLogCopyWith<SetLog> get copyWith => _$SetLogCopyWithImpl<SetLog>(this as SetLog, _$identity);

  /// Serializes this SetLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SetLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetLog&&(identical(other.setIndex, _this.setIndex) || other.setIndex == _this.setIndex)&&(identical(other.reps, _this.reps) || other.reps == _this.reps)&&(identical(other.hits, _this.hits) || other.hits == _this.hits)&&(identical(other.seconds, _this.seconds) || other.seconds == _this.seconds)&&(identical(other.streak, _this.streak) || other.streak == _this.streak)&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.loggedAt, _this.loggedAt) || other.loggedAt == _this.loggedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SetLog;
  return Object.hash(runtimeType,_this.setIndex,_this.reps,_this.hits,_this.seconds,_this.streak,_this.completed,_this.loggedAt);
}

@override
String toString() {
  final _this = this as SetLog;
  return 'SetLog(setIndex: ${_this.setIndex}, reps: ${_this.reps}, hits: ${_this.hits}, seconds: ${_this.seconds}, streak: ${_this.streak}, completed: ${_this.completed}, loggedAt: ${_this.loggedAt})';
}


}

/// @nodoc
abstract mixin class $SetLogCopyWith<$Res>  {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) _then) = _$SetLogCopyWithImpl;
@useResult
$Res call({
 int setIndex, int? reps, int? hits, int? seconds, int? streak, bool? completed,@TimestampConverter() DateTime loggedAt
});




}
/// @nodoc
class _$SetLogCopyWithImpl<$Res>
    implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._self, this._then);

  final SetLog _self;
  final $Res Function(SetLog) _then;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setIndex = null,Object? reps = freezed,Object? hits = freezed,Object? seconds = freezed,Object? streak = freezed,Object? completed = freezed,Object? loggedAt = null,}) {
  return _then(SetLog(
setIndex: null == setIndex ? _self.setIndex : setIndex // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,hits: freezed == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int?,seconds: freezed == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int?,streak: freezed == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SetLog].
extension SetLogPatterns on SetLog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetLog value)  $default,){
final _that = this;
switch (_that) {
case _SetLog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetLog value)?  $default,){
final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int setIndex,  int? reps,  int? hits,  int? seconds,  int? streak,  bool? completed, @TimestampConverter()  DateTime loggedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that.setIndex,_that.reps,_that.hits,_that.seconds,_that.streak,_that.completed,_that.loggedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int setIndex,  int? reps,  int? hits,  int? seconds,  int? streak,  bool? completed, @TimestampConverter()  DateTime loggedAt)  $default,) {final _that = this;
switch (_that) {
case _SetLog():
return $default(_that.setIndex,_that.reps,_that.hits,_that.seconds,_that.streak,_that.completed,_that.loggedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int setIndex,  int? reps,  int? hits,  int? seconds,  int? streak,  bool? completed, @TimestampConverter()  DateTime loggedAt)?  $default,) {final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that.setIndex,_that.reps,_that.hits,_that.seconds,_that.streak,_that.completed,_that.loggedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetLog implements SetLog {
  const _SetLog({required this.setIndex, this.reps, this.hits, this.seconds, this.streak, this.completed, @TimestampConverter() required this.loggedAt});
  factory _SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);

@override final  int setIndex;
@override final  int? reps;
@override final  int? hits;
@override final  int? seconds;
@override final  int? streak;
@override final  bool? completed;
@override@TimestampConverter() final  DateTime loggedAt;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetLogCopyWith<_SetLog> get copyWith => __$SetLogCopyWithImpl<_SetLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetLog&&(identical(other.setIndex, setIndex) || other.setIndex == setIndex)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,setIndex,reps,hits,seconds,streak,completed,loggedAt);
}

@override
String toString() {
    return 'SetLog(setIndex: $setIndex, reps: $reps, hits: $hits, seconds: $seconds, streak: $streak, completed: $completed, loggedAt: $loggedAt)';
}


}

/// @nodoc
abstract mixin class _$SetLogCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$SetLogCopyWith(_SetLog value, $Res Function(_SetLog) _then) = __$SetLogCopyWithImpl;
@override @useResult
$Res call({
 int setIndex, int? reps, int? hits, int? seconds, int? streak, bool? completed,@TimestampConverter() DateTime loggedAt
});




}
/// @nodoc
class __$SetLogCopyWithImpl<$Res>
    implements _$SetLogCopyWith<$Res> {
  __$SetLogCopyWithImpl(this._self, this._then);

  final _SetLog _self;
  final $Res Function(_SetLog) _then;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setIndex = null,Object? reps = freezed,Object? hits = freezed,Object? seconds = freezed,Object? streak = freezed,Object? completed = freezed,Object? loggedAt = null,}) {
  return _then(_SetLog(
setIndex: null == setIndex ? _self.setIndex : setIndex // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,hits: freezed == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int?,seconds: freezed == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int?,streak: freezed == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
