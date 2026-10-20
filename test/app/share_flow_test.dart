import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/features/share/share_service.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

class FakeShareService implements ShareService {
  final shared = <({Uint8List png, String fileName})>[];
  Object? failWith;

  @override
  Future<void> shareImage(Uint8List png, {required String fileName, Rect? origin}) async {
    if (failWith != null) throw failWith!;
    shared.add((png: png, fileName: fileName));
  }
}

final catalog = {for (final d in parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())) d.id: d};
final now = DateTime(2026, 10, 20, 12);

TrainingSession workout() {
  final drill = catalog['pick-your-corner']!.copyWith(defaultPrescription: catalog['pick-your-corner']!.defaultPrescription.copyWith(sets: 1));
  return TrainingSession(
    drills: [drill],
    startedAt: now.toUtc(),
    endedAt: now.toUtc().add(const Duration(minutes: 5)),
    logs: [(drillId: drill.id, log: SetLog(setIndex: 0, reps: 20, hits: 16, loggedAt: now.toUtc()))],
  );
}

Future<(ProviderContainer, FakeShareService)> mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final share = FakeShareService();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      testAuthOverride,
      testProfilesOverride,
      testSessionsOverride,
      shareServiceProvider.overrideWithValue(share),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return (container, share);
}

Future<ui.Image> decode(Uint8List png) async => (await (await ui.instantiateImageCodec(png)).getNextFrame()).image;

void main() {
  testWidgets('a workout summary shares a story card, then a square one, as real PNGs', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final (container, share) = await mount(tester);
      final session = workout();
      container.read(workoutHistoryProvider.notifier).add(session);
      container.read(appRouterProvider).go('/history/${workoutId(session)}');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share this workout'));
      await tester.pumpAndSettle();
      expect(find.text('Share your work'), findsOneWidget);
      expect(find.text('The picture is made on your phone. Nothing is uploaded.'), findsOneWidget);
      expect(find.text('20'), findsWidgets, reason: 'the shots on the card');
      expect(find.textContaining('Pick your corner · 80%'), findsWidgets, reason: 'the best it set');

      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        for (var i = 0; i < 100 && share.shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(share.shared, hasLength(1));
      expect(share.shared.single.fileName, 'how-to-hockey-workout-story.png');
      final story = (await tester.runAsync(() => decode(share.shared.single.png)))!;
      expect((story.width, story.height), (1080, 1920));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Square'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        for (var i = 0; i < 100 && share.shared.length < 2; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(share.shared.last.fileName, 'how-to-hockey-workout-square.png');
      final square = (await tester.runAsync(() => decode(share.shared.last.png)))!;
      expect((square.width, square.height), (1080, 1080));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Progress shares the week, and a failure says so and can be retried', (tester) async {
    await withClock(Clock.fixed(now), () async {
      final (container, share) = await mount(tester);
      container.read(workoutHistoryProvider.notifier).add(workout());
      container.read(appRouterProvider).go('/progress');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Share your progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share your progress'));
      await tester.pumpAndSettle();
      expect(find.text('Share your work'), findsOneWidget);
      expect(find.text('WEEKLY RECAP'), findsOneWidget);
      expect(find.text('20'), findsWidgets);

      share.failWith = Exception('no share sheet');
      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pump();
      });
      await tester.pump();
      expect(find.text('We couldn\'t make the picture. Try again.'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget, reason: 'the button comes back');

      share.failWith = null;
      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        for (var i = 0; i < 100 && share.shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(share.shared.single.fileName, 'how-to-hockey-week-story.png');
    });
  });
}
