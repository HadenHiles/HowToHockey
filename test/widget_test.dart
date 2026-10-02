import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('appearance setting switches and persists the app theme', (WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
    expect(find.text('Train with purpose.'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider), AppAppearance.dark);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(preferences.getString(AppearanceSettingsNotifier.preferenceKey), 'dark');
  });

  testWidgets('appearance setting remains usable at 200 percent text scale', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('saved appearance is restored on provider startup', () async {
    SharedPreferences.setMockInitialValues({'appearance': 'light'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);

    expect(container.read(appearanceProvider), AppAppearance.light);
    expect(container.read(appearanceProvider).themeMode, ThemeMode.light);
  });

  test('invalid saved appearance fails explicitly', () async {
    SharedPreferences.setMockInitialValues({'appearance': 'sepia'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);

    expect(() => container.read(appearanceProvider), throwsA(predicate<Object>((error) => error.toString().contains('Unrecognized saved appearance preference: sepia'))));
  });
}
