import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/auth_service.dart';
import '../profiles/active_player.dart';
import 'purchases_service.dart';

/// The store connection. Tests and builds without store keys use the unavailable one.
final purchasesProvider = Provider<PurchasesService>((ref) => const UnavailablePurchases());

/// Entitlements the signed-in account holds right now, as the store reports them.
final purchasedEntitlementsProvider = StreamProvider<Set<String>>((ref) => ref.watch(purchasesProvider).entitlements);

/// Keeps purchases tied to the signed-in account. Guests and kid devices can't buy, so they stay unidentified.
final purchasesIdentityProvider = Provider<void>((ref) {
  final service = ref.watch(purchasesProvider);
  ref.listen(authStateProvider, (_, next) {
    final state = next.value;
    if (state == null) return;
    unawaited(service.identify(state is SignedInAccount ? state.uid : null).catchError((Object _) {}));
  }, fireImmediately: true);
});

/// Whether the signed-in account itself has bought a plan. A plan on the account covers every profile it owns.
final accountPlansProvider = Provider<({bool player, bool coach})>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final purchased = auth is SignedInAccount ? ref.watch(purchasedEntitlementsProvider).value ?? const <String>{} : const <String>{};
  final coach = purchased.contains(coachProEntitlement);
  return (player: coach || purchased.contains(playerProEntitlement), coach: coach);
});

/// Effective Pro for the player this device is training as: the account's own plan, or the flag the server keeps
/// on the profile. The flag is what a paired kid device relies on, since it can't hold a plan itself.
final effectiveProProvider = Provider<bool>((ref) => ref.watch(accountPlansProvider).player || (ref.watch(activePlayerProvider)?.pro ?? false));

final coachProProvider = Provider<bool>((ref) => ref.watch(accountPlansProvider).coach);
