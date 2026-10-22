import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/commerce/entitlements.dart';
import 'package:how_to_hockey/features/commerce/purchases_service.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  // Parent and Coach screens need a signed-in account.
  await testAuth.signInWithEmail(email: 'pat@example.com', password: 'password1');
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testAuthOverride,
      testProfilesOverride,
      testTeamsOverride,
      testSessionsOverride,
      testProgramsOverride,
      purchasesProvider.overrideWithValue(FakePurchases()),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('age gate blocks under-13 sign-up, allows adults, then role onboarding opens a shell', (tester) async {
    final router = (await mount(tester)).read(appRouterProvider);
    router.go('/welcome');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 10}').last);
    await tester.pumpAndSettle();
    expect(find.text('A parent needs to set this up'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 30}').last);
    await tester.pumpAndSettle();
    expect(find.text('Continue with Apple'), findsOneWidget);
    await tester.tap(find.text('Skip for now (look around)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coach'));
    await tester.tap(find.text('Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Coach'));
    await tester.pumpAndSettle();
    expect(find.text('Compliance'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paywall disclosures and program locked/owned states', (tester) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    router.go('/paywall');
    await tester.pumpAndSettle();
    expect(find.text('Paywall for player'), findsOneWidget);
    router.go('/paywall?plan=coach');
    await tester.pumpAndSettle();
    expect(find.text('Paywall for coach'), findsOneWidget);
    await tester.tap(find.text('Buy coach'));
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    router.go('/programs/hands-21/day/2');
    await tester.pumpAndSettle();
    expect(find.text('Unlock this day'), findsWidgets);

    router.go('/programs/hands-21');
    await tester.pumpAndSettle();
    expect(find.text('Try Day 1 free'), findsOneWidget);
    await tester.ensureVisible(find.text('Day 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 2'));
    await tester.pumpAndSettle();
    expect(find.text('Paywall for program_hands-21_pro'), findsOneWidget);
    await tester.tap(find.text('Buy program_hands-21_pro'));
    await tester.pumpAndSettle();
    expect(find.text('Start training'), findsOneWidget);

    router.go('/programs/hands-21/day/2');
    await tester.pumpAndSettle();
    expect(find.text('Today’s challenge'), findsOneWidget);
    expect(find.text('Quick feet'), findsOneWidget);
    await tester.tap(find.text('Start this workout'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drills.map((drill) => drill.id), ['quiet-hands-quick-feet', 'athletic-stance-reset']);

    router.go('/programs/shooting-30/day/1');
    await tester.pumpAndSettle();
    expect(find.text('Try Day 1 free'), findsNothing);
    expect(find.text('Today’s challenge'), findsOneWidget);
    expect(find.text('Beat your best'), findsOneWidget);
    router.go('/programs/shooting-30/day/1/lesson');
    await tester.pumpAndSettle();
    expect(find.text('Build a quick release. Coach Jeremy’s lesson videos are coming soon.'), findsOneWidget);
    router.go('/programs/hands-21/day/2/lesson');
    await tester.pumpAndSettle();
    expect(find.text('Day 2 lesson'), findsWidgets);
    router.go('/programs/nope');
    await tester.pumpAndSettle();
    expect(find.text('Program not found'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pro subscribers get the discounted one-time program offering', (tester) async {
    final container = await mount(tester);
    final purchases = container.read(purchasesProvider) as FakePurchases;
    purchases.setActive({playerProEntitlement});
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/programs/hands-21/purchase');
    await tester.pumpAndSettle();
    expect(find.text('Paywall for program_hands-21_pro'), findsOneWidget);
    await tester.tap(find.text('Buy program_hands-21_pro'));
    await tester.pumpAndSettle();
    expect(find.text('Start training'), findsOneWidget);
    expect(purchases.active, contains('program_hands-21'));
    expect(purchases.active, contains(playerProEntitlement));
  });
}
