import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {double scale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
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
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> signedInWithKids() async {
  await testAuth.signInWithEmail(email: 'parent@example.com', password: 'password1');
  testProfiles.children
    ..clear()
    ..addAll(const [
      PlayerProfile(id: 'child-1', ownerUid: 'u', displayName: 'Avery H.', birthYear: 2015, isChild: true),
      PlayerProfile(id: 'child-2', ownerUid: 'u', displayName: 'Riley H.', birthYear: 2017, isChild: true),
    ]);
}

void main() {
  testWidgets('Kids lists real child profiles and adds one with the cap enforced', (tester) async {
    await signedInWithKids();
    final container = await mount(tester);
    container.read(appRouterProvider).go('/parent/kids');
    await tester.pumpAndSettle();
    expect(find.text('Avery H.'), findsOneWidget);
    expect(find.text('Riley H.'), findsOneWidget);

    await tester.tap(find.text('Add child'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add child').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('first name'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'First name'), 'jordan');
    await tester.enterText(find.widgetWithText(TextField, 'Last initial'), 'p');
    await tester.tap(find.text('Add child').last);
    await tester.pumpAndSettle();
    expect(find.text('Pick your child\'s birth year.'), findsOneWidget);

    tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>)).onChanged!(2014);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add child').last);
    await tester.pumpAndSettle();
    expect(testProfiles.calls.last, 'child:Jordan P.:2014');
    expect(find.text('Jordan P.'), findsOneWidget);
    expect(find.textContaining('most child profiles'), findsOneWidget);
    expect(find.text('Add child'), findsNothing);

    await tester.tap(find.text('Jordan P.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Train as Jordan P.'));
    await tester.pumpAndSettle();
    expect(container.read(activePlayerIdProvider), 'child-3');
    expect(container.read(appRouterProvider).state.uri.path, '/train');
  });

  testWidgets('Me role switcher opens the Parent shell with only Parent navigation', (tester) async {
    await signedInWithKids();
    final container = await mount(tester);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Switch role'));
    await tester.tap(find.text('Switch role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();

    expect(find.text('Your players'), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Verify')), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Train')), findsNothing);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Player'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Train')), findsOneWidget);
  });

  testWidgets('child detail controls, pairing, approvals, and Train Together', (tester) async {
    await signedInWithKids();
    final container = await mount(tester, scale: 2);
    final router = container.read(appRouterProvider);
    router.go('/parent/kids');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avery H.'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    expect(find.text('Remove from team'), findsNothing);

    router.go('/parent/kids/child-1/pair');
    await tester.pumpAndSettle();
    expect(find.text('No code yet'), findsOneWidget);
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();
    expect(testProfiles.calls.last, 'pair:child-1');
    expect(find.text('1234 5678'), findsOneWidget);
    expect(find.textContaining('Expires in '), findsOneWidget);
    await tester.pump(const Duration(minutes: 11));
    expect(find.text('That code expired'), findsOneWidget);

    router.go('/parent/kids/approvals');
    await tester.pumpAndSettle();
    expect(find.textContaining('No requests waiting'), findsOneWidget);

    router.go('/parent/kids/train-together');
    await tester.pumpAndSettle();
    expect(find.text('Start together'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
