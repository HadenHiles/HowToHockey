import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/commerce/entitlements.dart';
import 'package:how_to_hockey/features/commerce/purchases_service.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_catalog.dart';

Future<(ProviderContainer, FakePurchases, FakeAuthService, FakeProfileRepository)> setUpContainer(AuthState auth, {PlayerProfile? profile}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final purchases = FakePurchases();
  final authService = FakeAuthService(auth);
  final profiles = FakeProfileRepository()..own = profile;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      purchasesProvider.overrideWithValue(purchases),
      authServiceProvider.overrideWithValue(authService),
      profileRepositoryProvider.overrideWithValue(profiles),
    ],
  );
  addTearDown(container.dispose);
  return (container, purchases, authService, profiles);
}

Future<void> settle(ProviderContainer container) async {
  container.listen(effectiveProProvider, (_, _) {});
  container.listen(accountPlansProvider, (_, _) {});
  container.listen(purchasedEntitlementsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  const account = SignedInAccount(uid: 'parent-1', email: 'pat@example.com', emailVerified: true);
  const ownProfile = PlayerProfile(id: 'parent-1', ownerUid: 'parent-1', displayName: 'Pat', birthYear: 1985, isChild: false);

  test('a Player Pro plan on the account unlocks Pro for the account and not Coach Pro', () async {
    final (container, purchases, _, _) = await setUpContainer(account, profile: ownProfile);
    await settle(container);
    expect(container.read(effectiveProProvider), isFalse);

    purchases.setActive({playerProEntitlement});
    await settle(container);
    expect(container.read(effectiveProProvider), isTrue);
    expect(container.read(coachProProvider), isFalse);
  });

  test('Coach Pro includes Player Pro', () async {
    final (container, purchases, _, _) = await setUpContainer(account, profile: ownProfile);
    await settle(container);
    purchases.setActive({coachProEntitlement});
    await settle(container);
    expect(container.read(coachProProvider), isTrue);
    expect(container.read(effectiveProProvider), isTrue);
  });

  test('a plan on the parent account covers the child being trained', () async {
    final (container, purchases, _, profiles) = await setUpContainer(account, profile: ownProfile);
    profiles.children.add(const PlayerProfile(id: 'child-1', ownerUid: 'parent-1', displayName: 'Avery H.', birthYear: 2015, isChild: true));
    await settle(container);
    purchases.setActive({playerProEntitlement});
    await settle(container);
    expect(container.read(effectiveProProvider), isTrue);
  });

  test('a paired kid device is Pro only when the server flags its profile', () async {
    var (container, _, _, _) = await setUpContainer(
      const KidDeviceSession('child-1'),
      profile: const PlayerProfile(id: 'child-1', ownerUid: 'parent-1', displayName: 'Avery H.', birthYear: 2015, isChild: true),
    );
    await settle(container);
    expect(container.read(effectiveProProvider), isFalse);

    (container, _, _, _) = await setUpContainer(
      const KidDeviceSession('child-1'),
      profile: const PlayerProfile(id: 'child-1', ownerUid: 'parent-1', displayName: 'Avery H.', birthYear: 2015, isChild: true, pro: true),
    );
    await settle(container);
    expect(container.read(effectiveProProvider), isTrue);
    expect(container.read(coachProProvider), isFalse);
  });

  test('a guest never counts as having a plan, even if the store reports one', () async {
    final (container, purchases, _, _) = await setUpContainer(const GuestSession('guest-1'));
    await settle(container);
    purchases.setActive({playerProEntitlement});
    await settle(container);
    expect(container.read(effectiveProProvider), isFalse);
  });

  test('purchases follow the signed-in account, and guests and kid devices stay unidentified', () async {
    final (container, purchases, auth, _) = await setUpContainer(const GuestSession('guest-1'));
    container.listen(purchasesIdentityProvider, (_, _) {});
    await settle(container);
    auth.signInSilently(account);
    await settle(container);
    auth.signInSilently(const KidDeviceSession('child-1'));
    await settle(container);
    expect(purchases.identified, [null, 'parent-1', null]);
  });
}
