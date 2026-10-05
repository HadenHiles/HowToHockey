import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:how_to_hockey/preview/preview_data.dart';
import 'package:how_to_hockey/preview/preview_state.dart';
import 'package:how_to_hockey/preview/ux_preview_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real preview entrypoint boots offline and completes a local workout', (tester) async {
    expect(const bool.fromEnvironment('UX_PREVIEW'), isTrue, reason: 'Run this device test with --dart-define=UX_PREVIEW=true.');
    await app.main();
    await tester.pumpAndSettle();

    expect(Firebase.apps, isEmpty);
    expect(find.byType(UxPreviewApp), findsOneWidget);
    expect(find.text('View workout'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(UxPreviewApp)));
    final router = container.read(previewRouterProvider);
    router.go('/setup');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: choose your focus'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(5));
    await tester.tap(find.text('Preview my workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(container.read(previewSessionProvider).logs.length, 2);

    container.read(previewSessionProvider.notifier).start([previewDrills.first.copyWith(defaultPrescription: previewDrills.first.defaultPrescription.copyWith(sets: 1))]);
    router.go('/session');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(find.text('Shots logged'), findsOneWidget);
    expect(container.read(previewSessionProvider).finished, isTrue);
    expect(Firebase.apps, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
