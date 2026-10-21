import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/hockey_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('normal app boots with Firebase and completes a local workout', (tester) async {
    // main() installs Crashlytics handlers that would hide test failures.
    final testErrorHandler = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrorHandler;
    await tester.pumpAndSettle();

    expect(Firebase.apps, isNotEmpty);
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    expect(find.byType(HockeyApp), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(HockeyApp)));
    final router = container.read(appRouterProvider);
    await container.read(drillRestSettingsProvider.notifier).configure(sampleDrills.first.id, (enabled: false, seconds: 45));
    router.go('/setup');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: choose your focus'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(6));
    await tester.tap(find.text('View my workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    await tapWorkoutAction(tester, 'Log set');
    expect(container.read(trainingSessionProvider).logs.length, 2);
    expect(find.text('Skip rest'), findsNothing);

    container.read(trainingSessionProvider.notifier).start([sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 1))]);
    router.go('/train/session');
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    await tapWorkoutAction(tester, 'Finish workout');
    expect(find.text('Shots logged'), findsOneWidget);
    expect(container.read(trainingSessionProvider).finished, isTrue);
    expect(Firebase.apps, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tapWorkoutAction(WidgetTester tester, String label) async {
  final scroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(scroll).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
