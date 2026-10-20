import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Walks the scrolling workout list on a real device against the local emulators, printing `SHOT name`
/// lines. A host script watches for them and takes screenshots, so the screens can be checked by eye:
///   rules_test/node_modules/.bin/firebase emulators:exec --project how-to-hockey --only auth,functions,firestore \
///     "flutter test integration_test/workout_editing_visual_test.dart -d DEVICE_ID --dart-define=USE_EMULATORS=true"
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('workout list, step by step', (tester) async {
    expect(const bool.fromEnvironment('USE_EMULATORS'), isTrue, reason: 'Run against the local emulators only.');
    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      debugPrint('SHOT $name');
      await Future<void>.delayed(const Duration(seconds: 4));
    }

    Future<void> tapKey(String key) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> type(String key, String text) async {
      final field = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    final container = ProviderScope.containerOf(tester.element(find.byType(HockeyApp)));
    final router = container.read(appRouterProvider);
    final catalog = await container.read(drillCatalogProvider.future);
    final free = visibleDrills(catalog, pro: false);
    final accuracy = free.firstWhere((d) => d.trackingType == TrackingType.accuracy);
    final timed = free.firstWhere((d) => d.trackingType == TrackingType.duration);
    final streak = free.firstWhere((d) => d.trackingType == TrackingType.streak);
    final volume = free.firstWhere((d) => d.trackingType == TrackingType.volume);
    container.read(trainingSessionProvider.notifier).start([accuracy, timed, streak, volume]);
    router.go('/train/session');
    await shot('01-list');

    await tapKey('check-${accuracy.id}-0');
    await shot('02-hits-missing');
    await type('set-${accuracy.id}-0-hits', '6');
    await tapKey('check-${accuracy.id}-0');
    await shot('03-set-logged');
    await tapKey('check-${accuracy.id}-1');
    await shot('04-second-set-logged');

    await tapKey('overview-menu-1');
    await shot('05-drill-menu');
    await tester.tap(find.text('Focus view'));
    await shot('06-focus-view');
    await tester.tap(find.byTooltip('Workout overview'));
    await shot('07-back-to-list');

    final addDrills = find.text('Add drills');
    await tester.ensureVisible(addDrills);
    await tester.pumpAndSettle();
    await tester.tap(addDrills);
    await shot('08-picker');
    debugPrint('SHOT done');
  });
}
