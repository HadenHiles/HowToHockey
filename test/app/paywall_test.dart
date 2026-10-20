import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/commerce/entitlements.dart';
import 'package:how_to_hockey/features/commerce/purchases_service.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, FakePurchases purchases, {bool signedIn = true}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  if (signedIn) {
    await testAuth.signInWithEmail(email: 'pat@example.com', password: 'password1');
  } else {
    testAuth.signInSilently(const GuestSession('guest-1'));
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testAuthOverride,
      testProfilesOverride,
      testSessionsOverride,
      purchasesProvider.overrideWithValue(purchases),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go('/paywall');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a guest is sent to create an account instead of seeing plans', (tester) async {
    await mount(tester, FakePurchases(), signedIn: false);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.textContaining('Paywall for'), findsNothing);
  });

  testWidgets('a signed-in player sees the Player Pro paywall from RevenueCat and buying closes it', (tester) async {
    final purchases = FakePurchases();
    final container = await mount(tester, purchases);
    expect(find.text('Paywall for player'), findsOneWidget);
    await tester.tap(find.text('Buy player'));
    await tester.pumpAndSettle();
    expect(purchases.bought, ['player']);
    expect(container.read(effectiveProProvider), isTrue);
    expect(find.text('Paywall for player'), findsNothing);
  });

  testWidgets('the coach entry shows the Coach Pro paywall', (tester) async {
    final container = await mount(tester, FakePurchases());
    container.read(appRouterProvider).go('/paywall?plan=coach');
    await tester.pumpAndSettle();
    expect(find.text('Paywall for coach'), findsOneWidget);
  });

  testWidgets('a plan the account already has shows manage instead of the paywall', (tester) async {
    final purchases = FakePurchases()..active = {playerProEntitlement};
    final container = await mount(tester, purchases);
    purchases.setActive({playerProEntitlement});
    await tester.pumpAndSettle();
    expect(container.read(effectiveProProvider), isTrue);
    expect(find.text('You have Player Pro. Thank you!'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(find.textContaining('Paywall for'), findsNothing);
  });

  testWidgets('restore tells the person whether anything was found', (tester) async {
    final purchases = FakePurchases()..active = {playerProEntitlement};
    await mount(tester, purchases);
    purchases.setActive({playerProEntitlement});
    await tester.pumpAndSettle();
    purchases.restorable = {};
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();
    expect(find.text('No purchases found for this account.'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    purchases.restorable = {playerProEntitlement};
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();
    expect(find.text('Your plan is back.'), findsOneWidget);
  });

  testWidgets('a failed restore says so', (tester) async {
    final purchases = FakePurchases()..active = {playerProEntitlement};
    await mount(tester, purchases);
    purchases.setActive({playerProEntitlement});
    purchases.failWith = const PurchaseFailure('Couldn\'t restore purchases. Check your connection and try again.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn\'t restore purchases'), findsOneWidget);
  });

  testWidgets('without a store the screen is honest and offers nothing to buy', (tester) async {
    await mount(tester, FakePurchases(available: false));
    expect(find.textContaining('Plans aren\'t available right now'), findsOneWidget);
    expect(find.textContaining('Paywall for'), findsNothing);
  });
}
