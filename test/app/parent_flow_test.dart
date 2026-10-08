import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> mount(WidgetTester tester, {double scale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
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

void main() {
  testWidgets('Me role switcher opens the Parent shell with only Parent navigation', (tester) async {
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

    await tester.ensureVisible(find.text('Remove from team'));
    await tester.tap(find.text('Remove from team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing was removed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    router.go('/parent/kids/avery/pair');
    await tester.pumpAndSettle();
    expect(find.textContaining('NOT VALID'), findsOneWidget);

    router.go('/parent/kids/approvals');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').first);
    await tester.pump();
    expect(find.textContaining('Nothing was approved'), findsOneWidget);

    router.go('/parent/kids/train-together');
    await tester.pumpAndSettle();
    expect(find.text('Start together'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
