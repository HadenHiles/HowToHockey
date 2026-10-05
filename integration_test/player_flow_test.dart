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
    await app.main();
    await tester.pumpAndSettle();

    expect(Firebase.apps, isNotEmpty);
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    expect(find.byType(HockeyApp), findsOneWidget);
    expect(find.text('View workout'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(HockeyApp)));
    final router = container.read(appRouterProvider);
    await container.read(drillRestSettingsProvider.notifier).configure(sampleDrills.first.id, (enabled: false, seconds: 45));
    router.go('/setup');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: choose your focus'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(5));
    await tester.tap(find.text('View my workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).logs.length, 2);
    expect(find.text('Skip rest'), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 1);
    await tester.tap(find.byTooltip('Workout overview'));
    await tester.pumpAndSettle();
    expect(find.text('Workout overview'), findsOneWidget);
    await tester.tap(find.text('Quick-release wrist shots'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 0);

    container.read(trainingSessionProvider.notifier).start([sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 1))]);
    router.go('/session');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect(find.text('Shots logged'), findsOneWidget);
    expect(container.read(trainingSessionProvider).finished, isTrue);
    expect(Firebase.apps, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}
