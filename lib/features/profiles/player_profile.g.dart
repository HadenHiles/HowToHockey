// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerProfile _$PlayerProfileFromJson(Map<String, dynamic> json) => _PlayerProfile(
  id: json['id'] as String,
  ownerUid: json['ownerUid'] as String,
  displayName: json['displayName'] as String,
  birthYear: (json['birthYear'] as num).toInt(),
  isChild: json['isChild'] as bool,
  teamIds: (json['teamIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
  pro: json['pro'] as bool? ?? false,
);

Map<String, dynamic> _$PlayerProfileToJson(_PlayerProfile instance) => <String, dynamic>{
  'id': instance.id,
  'ownerUid': instance.ownerUid,
  'displayName': instance.displayName,
  'birthYear': instance.birthYear,
  'isChild': instance.isChild,
  'teamIds': instance.teamIds,
  'pro': instance.pro,
};
