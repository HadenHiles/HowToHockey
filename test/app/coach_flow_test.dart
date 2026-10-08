import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder navLabel(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('Coach shell exposes only coach navigation and disclosed actions at 200% text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
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
    await tester.tap(find.text('Approve').first);
    await tester.pump();
    expect(find.textContaining('Nothing was approved'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pumpAndSettle();

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
    expect(find.textContaining('NOT VALID'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.ensureVisible(find.text('Switch to Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Player'));
    await tester.pumpAndSettle();
    expect(navLabel('Train'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
