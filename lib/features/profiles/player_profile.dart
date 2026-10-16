import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_profile.freezed.dart';
part 'player_profile.g.dart';

/// One player's profile. An account can own several: its own, plus child profiles it manages.
@freezed
abstract class PlayerProfile with _$PlayerProfile {
  const factory PlayerProfile({required String id, required String ownerUid, required String displayName, required int birthYear, required bool isChild, @Default(<String>[]) List<String> teamIds}) =
      _PlayerProfile;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => _$PlayerProfileFromJson(json);
}

/// What an account may be used for. Written only by the server.
enum AccountRole { player, parent, coach }
