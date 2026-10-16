import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

const routes = [
  '/train',
  '/progress',
  '/team',
  '/me',
  '/setup',
  '/focus',
  '/routine',
  '/routines',
  '/routines/new',
  '/library',
  '/summary',
  '/parent/kids',
  '/parent/kids/avery',
  '/parent/kids/avery/pair',
  '/parent/kids/approvals',
  '/parent/kids/train-together',
  '/parent/verify',
  '/parent/account',
  '/coach/roster',
  '/coach/roster/requests',
  '/coach/homework',
  '/coach/homework/new',
  '/coach/compliance',
  '/coach/team',
  '/welcome',
  '/signup',
  '/onboarding/role',
  '/paywall',
  '/paywall?plan=coach',
  '/programs',
  '/programs/shooting-30',
  '/programs/hands-21',
  '/programs/hands-21/day/1',
  '/programs/shooting-30/day/3/lesson',
  '/missing-screen',
];

void main() {
  for (final appearance in ['light', 'dark']) {
    testWidgets('every screen renders at 320x568, 200% text, Reduce Motion ($appearance)', (tester) async {
      SharedPreferences.setMockInitialValues({'appearance': appearance});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testMediaOverride, testCuesOverride, testRemindersOverride]);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
      await tester.pumpAndSettle();

      final failures = <String>[];
      for (final route in routes) {
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        final error = tester.takeException();
        if (error != null) failures.add('$route: ${error.toString().split('\n').first}');
      }
      expect(failures, isEmpty);
    });
  }
}
