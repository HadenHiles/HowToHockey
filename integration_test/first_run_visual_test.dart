import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Walks first launch on a real device against the local emulators, printing `SHOT name` lines for a host
/// screenshot loop. Start from a fresh install so the welcome walkthrough opens by itself:
///   rules_test/node_modules/.bin/firebase emulators:exec --project how-to-hockey --only auth,functions,firestore \
///     "flutter test integration_test/first_run_visual_test.dart -d DEVICE_ID --dart-define=USE_EMULATORS=true"
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('first launch, step by step', (tester) async {
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
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    await shot('01-welcome-player');
    await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
    await shot('02-welcome-parent');
    await tester.drag(find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
    await shot('03-welcome-coach');
    await tester.ensureVisible(find.text('Look around first'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look around first'));
    await shot('04-train');
    await tester.tap(find.text('Harder shot'));
    await shot('05-train-harder-shot');
    final customize = find.text('Customize');
    await tester.ensureVisible(customize);
    await shot('06-train-lower');
    debugPrint('SHOT done');
  });
}
