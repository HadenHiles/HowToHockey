import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/auth_service.dart';
import '../settings/appearance_settings_controller.dart';
import 'player_profile.dart';
import 'profile_repository.dart';

const _activePlayerKey = 'activePlayerId';

/// The player profile this device is training as, saved on the device.
class ActivePlayerId extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_activePlayerKey);

  void choose(String profileId) {
    state = profileId;
    ref.read(sharedPreferencesProvider).setString(_activePlayerKey, profileId);
  }

  void clear() {
    state = null;
    ref.read(sharedPreferencesProvider).remove(_activePlayerKey);
  }
}

final activePlayerIdProvider = NotifierProvider<ActivePlayerId, String?>(ActivePlayerId.new);

/// The signed-in account's own player profile, or the one profile a paired kid device is locked to.
final ownProfileProvider = StreamProvider<PlayerProfile?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repository = ref.watch(profileRepositoryProvider);
  return switch (auth) {
    SignedInAccount(:final uid) => repository.watchProfile(uid),
    KidDeviceSession(:final profileId) => repository.watchProfile(profileId),
    _ => Stream.value(null),
  };
});

/// Everyone this device may train as: the account's own profile first, then its children.
/// A kid device only ever has its one profile.
final switchablePlayersProvider = Provider<List<PlayerProfile>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final loaded = ref.watch(ownProfileProvider).asData?.value;
  // While a different account's profile is still loading, the last one shown must not be treated as theirs.
  final own = switch (auth) {
    SignedInAccount(:final uid) when loaded?.ownerUid == uid => loaded,
    KidDeviceSession(:final profileId) when loaded?.id == profileId => loaded,
    _ => null,
  };
  final children = auth is SignedInAccount ? (ref.watch(childProfilesProvider).asData?.value ?? const <PlayerProfile>[]).where((p) => p.ownerUid == auth.uid).toList() : const <PlayerProfile>[];
  return [?own, ...children];
});

/// The player to train as: the saved choice if it is still available, otherwise the first one.
/// Null for guests, who train without a profile.
final activePlayerProvider = Provider<PlayerProfile?>((ref) {
  final players = ref.watch(switchablePlayersProvider);
  final chosen = ref.watch(activePlayerIdProvider);
  return players.where((p) => p.id == chosen).firstOrNull ?? players.firstOrNull;
});
