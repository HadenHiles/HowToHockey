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

  testWidgets('all six input types log without forced rest and reach summary', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final router = container.read(appRouterProvider);
    final fixtures = sampleDrills.map((drill) => drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: 1))).toList();
    container.read(trainingSessionProvider.notifier).start(fixtures);
    router.go('/session');
    await tester.pumpAndSettle();
    for (final (index, drill) in fixtures.indexed) {
      if (index > 0) {
        await tester.tap(find.text('Next drill').first);
        await tester.pumpAndSettle();
      }
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
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
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

  testWidgets('optional rest is inline and does not block logging or swiping', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    await container.read(drillRestSettingsProvider.notifier).configure(sampleDrills.first.id, (enabled: true, seconds: 45));
    container.read(trainingSessionProvider.notifier).start(sampleDrills);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(find.text('Skip rest'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 1);
    await tester.tap(find.text('Skip rest'));
    await tester.pumpAndSettle();
    expect(find.text('Skip rest'), findsNothing);
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

  testWidgets('drill drafts survive swiping and overview, with out-of-order progress', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(trainingSessionProvider.notifier).start([sampleDrills.first, sampleDrills[3]]);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    expect(find.text('Skip rest'), findsNothing);
    await tester.ensureVisible(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '7');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 1);
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).setsLogged(1), 1);
    expect(find.text('Skip rest'), findsNothing);
    await tester.tap(find.byTooltip('Workout overview'));
    await tester.pumpAndSettle();
    expect(find.text('Workout overview'), findsOneWidget);
    expect(find.text('0 / 2 sets · Reps'), findsOneWidget);
    expect(find.text('1 / 2 sets · Accuracy'), findsOneWidget);
    await tester.tap(find.text('Quick-release wrist shots'));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    final session = container.read(trainingSessionProvider);
    expect(session.logs.map((entry) => entry.log.setIndex), [0, 0]);
    expect(session.logs.last.log.reps, 7);
    expect(session.finished, isFalse);
    expect(session.activeSeconds, sampleDrills.first.estimatedSecondsPerSet + sampleDrills[3].estimatedSecondsPerSet);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest settings persist per drill and survive a new provider container', (tester) async {
    phoneSize(tester, scale: 2);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    final settingsButton = find.text('Drill settings · Rest off');
    await tester.ensureVisible(settingsButton);
    await tester.pumpAndSettle();
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    expect(find.text('Rest duration: 45 seconds'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    expect(container.read(drillRestSettingsProvider)[sampleDrills.first.id], (enabled: true, seconds: 45));
    expect(container.read(drillRestSettingsProvider)[sampleDrills[1].id], isNull);
    final restored = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider))]);
    addTearDown(restored.dispose);
    expect(restored.read(drillRestSettingsProvider)[sampleDrills.first.id], (enabled: true, seconds: 45));
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed drill pauses in overview and resumes from its retained countdown', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(trainingSessionProvider.notifier).start([sampleDrills[1].copyWith(defaultPrescription: sampleDrills[1].defaultPrescription.copyWith(seconds: 3))]);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:02'), findsOneWidget);
    await tester.tap(find.byTooltip('Workout overview'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Quiet hands, quick feet'));
    await tester.pumpAndSettle();
    expect(find.text('0:02'), findsOneWidget);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).logs.single.log.seconds, 3);
  });

  testWidgets('completing the last drill first offers the next unfinished drill', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(trainingSessionProvider.notifier).start([
      for (final drill in [sampleDrills.first, sampleDrills[3]])
        drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: 1)),
    ]);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next drill'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 0);
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    expect(find.text('Finish workout'), findsOneWidget);
    expect(find.text('Next drill'), findsNothing);
    expect(container.read(trainingSessionProvider).finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
