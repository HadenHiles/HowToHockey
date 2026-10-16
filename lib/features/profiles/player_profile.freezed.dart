// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerProfile {

 String get id; String get ownerUid; String get displayName; int get birthYear; bool get isChild; List<String> get teamIds;
/// Create a copy of PlayerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerProfileCopyWith<PlayerProfile> get copyWith => _$PlayerProfileCopyWithImpl<PlayerProfile>(this as PlayerProfile, _$identity);

  /// Serializes this PlayerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ownerUid, _this.ownerUid) || other.ownerUid == _this.ownerUid)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.birthYear, _this.birthYear) || other.birthYear == _this.birthYear)&&(identical(other.isChild, _this.isChild) || other.isChild == _this.isChild)&&const DeepCollectionEquality().equals(other.teamIds, _this.teamIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerProfile;
  return Object.hash(runtimeType,_this.id,_this.ownerUid,_this.displayName,_this.birthYear,_this.isChild,const DeepCollectionEquality().hash(_this.teamIds));
}

@override
String toString() {
  final _this = this as PlayerProfile;
  return 'PlayerProfile(id: ${_this.id}, ownerUid: ${_this.ownerUid}, displayName: ${_this.displayName}, birthYear: ${_this.birthYear}, isChild: ${_this.isChild}, teamIds: ${_this.teamIds})';
}


}

/// @nodoc
abstract mixin class $PlayerProfileCopyWith<$Res>  {
  factory $PlayerProfileCopyWith(PlayerProfile value, $Res Function(PlayerProfile) _then) = _$PlayerProfileCopyWithImpl;
@useResult
$Res call({
 String id, String ownerUid, String displayName, int birthYear, bool isChild, List<String> teamIds
});




}
/// @nodoc
class _$PlayerProfileCopyWithImpl<$Res>
    implements $PlayerProfileCopyWith<$Res> {
  _$PlayerProfileCopyWithImpl(this._self, this._then);

  final PlayerProfile _self;
  final $Res Function(PlayerProfile) _then;

/// Create a copy of PlayerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerUid = null,Object? displayName = null,Object? birthYear = null,Object? isChild = null,Object? teamIds = null,}) {
  return _then(PlayerProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,birthYear: null == birthYear ? _self.birthYear : birthYear // ignore: cast_nullable_to_non_nullable
as int,isChild: null == isChild ? _self.isChild : isChild // ignore: cast_nullable_to_non_nullable
as bool,teamIds: null == teamIds ? _self.teamIds : teamIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerProfile].
extension PlayerProfilePatterns on PlayerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerProfile value)  $default,){
final _that = this;
switch (_that) {
case _PlayerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerUid,  String displayName,  int birthYear,  bool isChild,  List<String> teamIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerProfile() when $default != null:
return $default(_that.id,_that.ownerUid,_that.displayName,_that.birthYear,_that.isChild,_that.teamIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerUid,  String displayName,  int birthYear,  bool isChild,  List<String> teamIds)  $default,) {final _that = this;
switch (_that) {
case _PlayerProfile():
return $default(_that.id,_that.ownerUid,_that.displayName,_that.birthYear,_that.isChild,_that.teamIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerUid,  String displayName,  int birthYear,  bool isChild,  List<String> teamIds)?  $default,) {final _that = this;
switch (_that) {
case _PlayerProfile() when $default != null:
return $default(_that.id,_that.ownerUid,_that.displayName,_that.birthYear,_that.isChild,_that.teamIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerProfile implements PlayerProfile {
  const _PlayerProfile({required this.id, required this.ownerUid, required this.displayName, required this.birthYear, required this.isChild,  List<String> teamIds = const <String>[]}): _teamIds = teamIds;
  factory _PlayerProfile.fromJson(Map<String, dynamic> json) => _$PlayerProfileFromJson(json);

@override final  String id;
@override final  String ownerUid;
@override final  String displayName;
@override final  int birthYear;
@override final  bool isChild;
 final  List<String> _teamIds;
@override@JsonKey() List<String> get teamIds {
  if (_teamIds is EqualUnmodifiableListView) return _teamIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamIds);
}


/// Create a copy of PlayerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerProfileCopyWith<_PlayerProfile> get copyWith => __$PlayerProfileCopyWithImpl<_PlayerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.birthYear, birthYear) || other.birthYear == birthYear)&&(identical(other.isChild, isChild) || other.isChild == isChild)&&const DeepCollectionEquality().equals(other.teamIds, _teamIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ownerUid,displayName,birthYear,isChild,const DeepCollectionEquality().hash(_teamIds));
}

@override
String toString() {
    return 'PlayerProfile(id: $id, ownerUid: $ownerUid, displayName: $displayName, birthYear: $birthYear, isChild: $isChild, teamIds: $teamIds)';
}


}

/// @nodoc
abstract mixin class _$PlayerProfileCopyWith<$Res> implements $PlayerProfileCopyWith<$Res> {
  factory _$PlayerProfileCopyWith(_PlayerProfile value, $Res Function(_PlayerProfile) _then) = __$PlayerProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerUid, String displayName, int birthYear, bool isChild, List<String> teamIds
});




}
/// @nodoc
class __$PlayerProfileCopyWithImpl<$Res>
    implements _$PlayerProfileCopyWith<$Res> {
  __$PlayerProfileCopyWithImpl(this._self, this._then);

  final _PlayerProfile _self;
  final $Res Function(_PlayerProfile) _then;

/// Create a copy of PlayerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerUid = null,Object? displayName = null,Object? birthYear = null,Object? isChild = null,Object? teamIds = null,}) {
  return _then(_PlayerProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,birthYear: null == birthYear ? _self.birthYear : birthYear // ignore: cast_nullable_to_non_nullable
as int,isChild: null == isChild ? _self.isChild : isChild // ignore: cast_nullable_to_non_nullable
as bool,teamIds: null == teamIds ? _self._teamIds : teamIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
