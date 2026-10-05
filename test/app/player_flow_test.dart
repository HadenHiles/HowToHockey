import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> mountApp(WidgetTester tester, {String appearance = 'light'}) async {
  SharedPreferences.setMockInitialValues({'appearance': appearance});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  return container;
}

void phoneSize(WidgetTester tester, {double scale = 1}) {
  tester.view.physicalSize = const Size(640, 1400);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  test('focus sliders rebalance to exactly 100 including all-zero remainder', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(trainingFocusProvider.notifier);
    for (final pillar in SkillPillar.values) {
      for (final value in [100, 0, 33, 74, 1]) {
        controller.select(pillar, value);
        final focus = container.read(trainingFocusProvider);
        expect(focus[pillar], value);
        expect(focus.values.fold(0, (sum, points) => sum + points), 100);
        expect(focus.values.every((points) => points >= 0 && points <= 100), isTrue);
      }
    }
    expect(() => controller.select(SkillPillar.shooting, 101), throwsRangeError);
  });

  testWidgets('setup, focus, routine and local theme controls are navigable without Firebase', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final router = container.read(appRouterProvider);
    router.go('/setup');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basement'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSetupProvider).location, LocationOption.basement);
    await tester.tap(find.text('Next: choose your focus'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(5));
    await tester.tap(find.text('View my workout'));
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
    router.go('/me');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider), AppAppearance.dark);
    router.go('/train');
    await tester.pumpAndSettle();
    expect(find.text('Basement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all six input types log local sets through rest and summary', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final router = container.read(appRouterProvider);
    final fixtures = sampleDrills.map((drill) => drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: 1))).toList();
    container.read(trainingSessionProvider.notifier).start(fixtures);
    router.go('/session');
    await tester.pumpAndSettle();
    for (final drill in fixtures) {
      if (drill.trackingType == TrackingType.duration || drill.trackingType == TrackingType.density) {
        final startTimer = find.text('Start timer');
        await tester.ensureVisible(startTimer);
        await tester.pumpAndSettle();
        await tester.tap(startTimer);
        await tester.pump(Duration(seconds: drill.defaultPrescription.seconds!));
        await tester.pumpAndSettle();
      }
      if (drill.trackingType == TrackingType.binary) {
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Log set'));
      await tester.pumpAndSettle();
      if (drill != fixtures.last) {
        await tester.tap(find.text('Skip rest'));
        await tester.pumpAndSettle();
      }
    }
    final session = container.read(trainingSessionProvider);
    expect(session.finished, isTrue);
    expect(session.logs.length, 6);
    expect(session.logs[0].log.reps, 10);
    expect(session.logs[1].log.seconds, 30);
    expect(session.logs[2].log.seconds, 30);
    expect(session.logs[3].log.reps, 10);
    expect(session.logs[3].log.hits, 0);
    expect(session.logs[4].log.streak, 0);
    expect(session.logs[5].log.completed, isTrue);
    expect(find.text('You showed up.'), findsWidgets);
    expect(find.text('Shots logged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final appearance in ['light', 'dark']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('app routes fit a small phone in $appearance at ${scale}x', (tester) async {
        phoneSize(tester, scale: scale);
        final container = await mountApp(tester, appearance: appearance);
        final router = container.read(appRouterProvider);
        for (final route in ['/train', '/setup', '/focus', '/routine', '/library', '/drills/quick-release', '/session', '/rest', '/progress', '/team', '/me', '/summary', '/drills/not-a-drill']) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route in $appearance at $scale');
        }
      });
    }
  }

  testWidgets('library filtering exposes a deliberate empty state', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/library');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hockey IQ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No sample drills'), findsOneWidget);
    await tester.tap(find.text('All drills'));
    await tester.pumpAndSettle();
    expect(find.text('Quick-release wrist shots'), findsOneWidget);
  });

  testWidgets('direct accuracy input rejects hits above total and logs valid hits', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final drill = sampleDrills[3].copyWith(defaultPrescription: sampleDrills[3].defaultPrescription.copyWith(sets: 1));
    container.read(trainingSessionProvider.notifier).start([drill]);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '11');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 0 to 10.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '8');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('80% accuracy'), findsOneWidget);
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).logs.single.log.hits, 8);
  });

  testWidgets('rest resumes counting after reaching zero and adding time', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/rest', extra: 1);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Next set'), findsOneWidget);
    await tester.ensureVisible(find.text('+15s'));
    await tester.pump();
    await tester.tap(find.text('+15s'));
    await tester.pump();
    expect(find.text('Skip rest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:14'), findsOneWidget);
  });

  testWidgets('Player tabs preserve Train scroll position', (tester) async {
    phoneSize(tester);
    await mountApp(tester);
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    final trainPosition = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect(trainPosition, greaterThan(0));
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Me')));
    await tester.pumpAndSettle();
    expect(find.text('Jamie H.'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Train')));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, trainPosition);
  });
}
