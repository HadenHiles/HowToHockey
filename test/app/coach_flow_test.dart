import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Finder navLabel(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('Coach shell exposes only coach navigation and disclosed actions at 200% text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Parent and Coach screens need a signed-in account.
    await testAuth.signInWithEmail(email: 'pat@example.com', password: 'password1');
    testTeams.teams = const [Team(id: 't1', name: 'North Stars', memberCount: 0, joinCode: 'ABCDEF0123456789')];
    testTeams.requests = const [];
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

    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Switch role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch role'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Players'), findsOneWidget);
    for (final label in ['Roster', 'Homework', 'Compliance', 'Team']) {
      expect(navLabel(label), findsOneWidget);
    }
    expect(navLabel('Train'), findsNothing);

    await tester.tap(find.text('Join requests'));
    await tester.pumpAndSettle();
    expect(find.text('No requests waiting.'), findsOneWidget);

    await tester.tap(navLabel('Homework'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign homework'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Casey L.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casey L.'));
    await tester.pumpAndSettle();
    expect(find.text('Assign to 4 players'), findsOneWidget);
    await tester.tap(find.text('Assign to 4 players'));
    await tester.pump();
    expect(find.textContaining('Nothing was sent'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(navLabel('Compliance'));
    await tester.pumpAndSettle();
    expect(find.text('By player'), findsOneWidget);

    await tester.tap(navLabel('Team'));
    await tester.pumpAndSettle();
    expect(find.text('ABCDEF0123456789'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Make public'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make public'));
    await tester.pumpAndSettle();
    expect(testTeams.calls, contains('public:t1:true'));
    await tester.ensureVisible(find.text('Switch to Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Player'));
    await tester.pumpAndSettle();
    expect(navLabel('Train'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
