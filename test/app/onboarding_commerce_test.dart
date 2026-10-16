import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride]);
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
    final router = (await mount(tester)).read(appRouterProvider);
    router.go('/paywall');
    await tester.pumpAndSettle();
    expect(find.textContaining(r'$49.99 / year'), findsOneWidget);
    await tester.tap(find.text('Coach Pro').first);
    await tester.pumpAndSettle();
    expect(find.textContaining(r'$99.99 / year'), findsOneWidget);
    await tester.tap(find.textContaining('Start Coach Pro'));
    await tester.pump();
    expect(find.textContaining('You weren\'t charged'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    router.go('/programs/hands-21');
    await tester.pumpAndSettle();
    expect(find.textContaining('Buy for'), findsOneWidget);
    await tester.ensureVisible(find.text('Day 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 2'));
    await tester.pump();
    expect(find.textContaining('Buy this program'), findsOneWidget);

    router.go('/programs/shooting-30');
    await tester.pumpAndSettle();
    expect(find.text('Continue · Day 3'), findsOneWidget);
    router.go('/programs/shooting-30/day/3/lesson');
    await tester.pumpAndSettle();
    expect(find.text('Key cues'), findsOneWidget);
    router.go('/programs/nope');
    await tester.pumpAndSettle();
    expect(find.text('Program not found'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
