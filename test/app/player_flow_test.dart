import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/routine_state.dart';
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

void returnWorkoutSheetToTop(WidgetTester tester) {
  final sessionScroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(sessionScroll).position.jumpTo(0);
}

Future<void> revealWorkoutDrill(WidgetTester tester) async {
  final sessionScroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(sessionScroll).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
}

Future<void> tapWorkoutAction(WidgetTester tester, String label) async {
  await revealWorkoutDrill(tester);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> openDrillDetails(WidgetTester tester) async {
  await revealWorkoutDrill(tester);
  await tester.ensureVisible(find.byTooltip('Drill details'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Drill details'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starting a workout from Train keeps navigator page keys unique', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    await tester.tap(find.text('View workout'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/train/session');
    expect(container.read(trainingSessionProvider).startedAt, isNotNull);
    for (final navigator in tester.widgetList<Navigator>(find.byType(Navigator, skipOffstage: false))) {
      final keys = navigator.pages.map((page) => page.key).toList();
      expect(keys.toSet().length, keys.length);
    }
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-status-header')).hitTestable(), findsOneWidget);
    expect(find.textContaining('Your session').hitTestable(), findsNothing);
    expect(find.text('View workout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    (route: '/routines', label: 'Start', drills: 6),
    (route: '/drills/quick-release', label: 'Try this drill', drills: 1),
    (route: '/train', label: 'Shot logger', drills: 1),
    (route: '/train', label: 'Timer', drills: 1),
  ]) {
    testWidgets('${entry.label} enters the existing Player shell without duplicate pages', (tester) async {
      phoneSize(tester);
      final container = await mountApp(tester);
      final router = container.read(appRouterProvider);
      if (entry.route != '/train') {
        router.push(entry.route);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text(entry.label).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.routeInformationProvider.value.uri.path, '/train/session');
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(container.read(trainingSessionProvider).drills.length, entry.drills);
      expect(container.read(trainingSessionProvider).startedAt, isNotNull);
      for (final navigator in tester.widgetList<Navigator>(find.byType(Navigator, skipOffstage: false))) {
        final keys = navigator.pages.map((page) => page.key).toList();
        expect(keys.toSet().length, keys.length);
      }
    });
  }

  test('the six requested skills are labeled and represented in sample drills', () {
    expect(SkillPillar.values.map((pillar) => pillar.label), ['Accuracy', 'Hands', 'Power', 'Passing', 'Speed/Strength', 'Endurance']);
    expect(sampleDrills.map((drill) => drill.pillar).toSet(), SkillPillar.values.toSet());
  });

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
    expect(() => controller.select(SkillPillar.shotAccuracy, 101), throwsRangeError);
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
    expect(find.byType(Slider), findsNWidgets(6));
    await tester.tap(find.text('View my workout'));
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
    await tester.ensureVisible(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('collapsed workout follows every Player tab and hides behind sub-screens', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final router = container.read(appRouterProvider);
    container.read(trainingSessionProvider.notifier).start(sampleDrills);
    router.go('/train/session');
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    final logs = container.read(trainingSessionProvider).logs;
    await tester.ensureVisible(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '7');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    final handle = find.byKey(const ValueKey('workout-sheet-handle'));
    final header = find.byKey(const ValueKey('workout-status-header'));
    await tester.drag(handle, const Offset(0, 900));
    await tester.pumpAndSettle();

    for (final tab in ['Progress', 'Team', 'Me', 'Train']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(header.hitTestable(), findsOneWidget, reason: tab);
      final navigation = find.byType(NavigationBar);
      expect(tester.getBottomLeft(header).dy, closeTo(tester.getTopLeft(navigation).dy, .01), reason: tab);
      expect(container.read(trainingSessionProvider).logs, logs);
    }

    router.push('/setup');
    await tester.pumpAndSettle();
    expect(header.hitTestable(), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(header.hitTestable(), findsOneWidget);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(header.hitTestable(), findsNothing);
    Navigator.of(tester.element(find.text('Connect an account'))).pop();
    await tester.pumpAndSettle();
    expect(header.hitTestable(), findsOneWidget);
    await tester.drag(handle, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your session').hitTestable(), findsOneWidget);
    await revealWorkoutDrill(tester);
    expect(find.text('Set 2 of 2'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a workout removes the shared panel without losing summary data', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final notifier = container.read(trainingSessionProvider.notifier);
    notifier.start([sampleDrills.first.copyWith(defaultPrescription: sampleDrills.first.defaultPrescription.copyWith(sets: 1))]);
    final router = container.read(appRouterProvider);
    router.go('/train/session');
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    final logs = container.read(trainingSessionProvider).logs;
    await tapWorkoutAction(tester, 'Finish workout');
    expect(find.text('You showed up.'), findsWidgets);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(container.read(trainingSessionProvider).logs, logs);
    router.go('/me');
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    notifier.start(sampleDrills);
    router.go('/train/session');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-status-header')).hitTestable(), findsOneWidget);
    expect(find.textContaining('Your session').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('workout carousel has one row of 9:16 cards and follows selection at ${scale}x', (tester) async {
      phoneSize(tester, scale: scale);
      final container = await mountApp(tester);
      container.read(trainingSessionProvider.notifier).start(sampleDrills);
      container.read(appRouterProvider).go('/train/session');
      await tester.pumpAndSettle();
      final carousel = find.byKey(const ValueKey('workout-drill-previews'));
      final visiblePreviews = find
          .byWidgetPredicate((widget) => widget is Semantics && widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith('workout-preview-'))
          .hitTestable();
      expect(visiblePreviews.evaluate().length, inInclusiveRange(4, 6));
      final top = tester.getTopLeft(visiblePreviews.first).dy;
      for (final element in visiblePreviews.evaluate()) {
        final card = find.byWidget(element.widget);
        final size = tester.getSize(card);
        expect(size.width / size.height, closeTo(9 / 16, .001));
        expect(tester.getTopLeft(card).dy, closeTo(top, .001));
      }
      final scrollable = find.descendant(of: carousel, matching: find.byType(Scrollable));
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, 0);
      await revealWorkoutDrill(tester);
      await tester.ensureVisible(find.byType(PageView));
      await tester.pumpAndSettle();
      for (var index = 1; index < sampleDrills.length; index++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(container.read(trainingSessionProvider).drillIndex, index);
      }
      returnWorkoutSheetToTop(tester);
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      final lastPreview = find.byKey(ValueKey('workout-preview-${sampleDrills.last.id}'));
      expect(lastPreview.hitTestable(), findsOneWidget);
      expect(tester.widget<Semantics>(lastPreview).properties.selected, isTrue);
      final previous = find.byKey(ValueKey('workout-preview-${sampleDrills[4].id}'));
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).drillIndex, 4);
      expect(tester.widget<Semantics>(previous).properties.selected, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

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
      await tapWorkoutAction(tester, 'Log set');
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
    await tapWorkoutAction(tester, 'Finish workout');
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

  testWidgets('library filters drills by the six-skill taxonomy', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/library');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endurance'));
    await tester.pumpAndSettle();
    expect(find.text('30-second shot burst'), findsOneWidget);
    expect(find.text('Quick-release wrist shots'), findsNothing);
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
    await tapWorkoutAction(tester, 'Log set');
    expect(container.read(trainingSessionProvider).logs.single.log.hits, 8);
  });

  testWidgets('optional rest is inline and does not block logging or swiping', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    await container.read(drillRestSettingsProvider.notifier).configure(sampleDrills.first.id, (enabled: true, seconds: 45));
    container.read(trainingSessionProvider.notifier).start(sampleDrills);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    await revealWorkoutDrill(tester);
    expect(find.text('Log set'), findsOneWidget);
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    expect(find.text('Skip rest'), findsOneWidget);
    await tester.ensureVisible(find.text('Skip rest'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PageView));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 1);
    await tester.ensureVisible(find.text('Skip rest'));
    await tester.pumpAndSettle();
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

  testWidgets('Team tab exposes member, empty, locked, and discovery states', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/team');
    await tester.pumpAndSettle();

    expect(find.text('Locker room'), findsOneWidget);
    expect(find.text('Weekly leaderboard'), findsOneWidget);
    expect(find.text('View assignment'), findsOneWidget);
    await tester.ensureVisible(find.text('8 stick taps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 stick taps'));
    await tester.pumpAndSettle();
    expect(find.text('9 stick taps'), findsOneWidget);
    expect(find.text('Sample preview only. Stick taps are not sent.'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.text('Locker room'))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    final pageScroll = find.descendant(of: find.byType(CustomScrollView).hitTestable(), matching: find.byType(Scrollable)).first;
    tester.state<ScrollableState>(pageScroll).position.jumpTo(100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('No team'));
    await tester.pumpAndSettle();
    expect(find.text('Your next team starts here'), findsOneWidget);
    expect(find.text('Pending invite'), findsOneWidget);
    await tester.ensureVisible(find.text('Find a team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find a team'));
    await tester.pumpAndSettle();
    expect(find.text('Discover teams'), findsOneWidget);
    expect(find.text('Westside Wolves'), findsWidgets);
    await tester.tap(find.text('Request to join').first);
    await tester.pumpAndSettle();
    expect(find.text('Join requests are not connected yet.'), findsOneWidget);

    tester.state<ScrollableState>(pageScroll).position.jumpTo(100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Locked'));
    await tester.pumpAndSettle();
    expect(find.text('Members only'), findsOneWidget);
    expect(find.textContaining('visible only to rostered members'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me tab exposes profile, role, account, and subscription entry points', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jamie H.'));
    await tester.pumpAndSettle();
    expect(find.text('Switch player'), findsWidgets);
    await tester.tap(find.text('Avery H.'));
    await tester.pumpAndSettle();
    expect(find.text('Avery H.'), findsOneWidget);

    await tester.ensureVisible(find.text('Switch role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch role'));
    await tester.pumpAndSettle();
    expect(find.text('Parent'), findsOneWidget);
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();
    expect(find.text('The Parent shell is not connected yet.'), findsOneWidget);

    await tester.ensureVisible(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Connect an account'), findsOneWidget);
    expect(find.textContaining('Account linking and deletion are not connected yet.'), findsOneWidget);
    Navigator.of(tester.element(find.text('Connect an account'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Player Pro'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom session drill details preserve logs and draft inputs on return', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final custom = sampleDrills.first.copyWith(id: 'routine-custom-power', title: 'Custom power drill', formCues: ['Keep your weight balanced.']);
    container.read(trainingSessionProvider.notifier).start([custom]);
    container.read(appRouterProvider).go('/train/session');
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    final loggedSession = container.read(trainingSessionProvider);
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '7');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    await openDrillDetails(tester);
    expect(find.text('Custom power drill'), findsOneWidget);
    expect(find.text('1. Keep your weight balanced.'), findsOneWidget);
    expect(find.text('Try this drill'), findsNothing);
    for (final navigator in tester.widgetList<Navigator>(find.byType(Navigator, skipOffstage: false))) {
      final keys = navigator.pages.map((page) => page.key).toList();
      expect(keys.toSet().length, keys.length);
    }
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).logs, loggedSession.logs);
    expect(container.read(trainingSessionProvider).startedAt, loggedSession.startedAt);
    await revealWorkoutDrill(tester);
    expect(find.text('7'), findsOneWidget);
    await tapWorkoutAction(tester, 'Log set');
    expect(container.read(trainingSessionProvider).logs.last.log.reps, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewing session drill details pauses its running timer', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    final timed = sampleDrills.firstWhere((drill) => drill.trackingType == TrackingType.duration);
    container.read(trainingSessionProvider.notifier).start([timed.copyWith(defaultPrescription: timed.defaultPrescription.copyWith(seconds: 120))]);
    container.read(appRouterProvider).go('/train/session');
    await tester.pumpAndSettle();
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 1));
    await openDrillDetails(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Back to workout'));
    await tester.pumpAndSettle();
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    // The five seconds spent on the details screen must not count down.
    expect(find.textContaining(RegExp(r'^1:5[89]$')), findsOneWidget);
    expect(find.text('Start timer'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    await tapWorkoutAction(tester, 'Log set');
    expect(container.read(trainingSessionProvider).setsLogged(1), 1);
    expect(find.text('Skip rest'), findsNothing);
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Workout overview'));
    await tester.pumpAndSettle();
    expect(find.text('Workout overview'), findsOneWidget);
    expect(find.text('0 / 2 sets · Reps'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Accuracy: Pick your corner, 1 of 2 sets')), findsOneWidget);
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('Quick-release wrist shots').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick-release wrist shots').last);
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    await tapWorkoutAction(tester, 'Log set');
    final session = container.read(trainingSessionProvider);
    expect(session.logs.map((entry) => entry.log.setIndex), [0, 0]);
    expect(session.logs.last.log.reps, 7);
    expect(session.finished, isFalse);
    expect(session.activeSeconds, sampleDrills.first.estimatedSecondsPerSet + sampleDrills[3].estimatedSecondsPerSet);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout previews switch drills while swipes highlight the active drill and diagonal drags collapse safely', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(trainingSessionProvider.notifier).start([sampleDrills.first, sampleDrills[1]]);
    final router = container.read(appRouterProvider);
    router.go('/routine');
    await tester.pumpAndSettle();
    router.go('/train/session');
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.textContaining('Your session'), findsOneWidget);
    final statusHeader = find.byKey(const ValueKey('workout-status-header'));
    final statusContainer = tester.widget<Container>(statusHeader);
    expect((statusContainer.decoration as BoxDecoration).color, Theme.of(tester.element(statusHeader)).colorScheme.primary);
    expect(find.bySemanticsLabel(RegExp('Hands: Quiet hands, quick feet')), findsOneWidget);
    await openDrillDetails(tester);

    expect(find.text('Coach’s cues'), findsOneWidget);
    expect(find.text('Back to workout'), findsOneWidget);
    expect(find.text('Try this drill'), findsNothing);
    expect(container.read(trainingSessionProvider).drillIndex, 0);
    await tester.tap(find.text('Back to workout'));
    await tester.pumpAndSettle();
    expect(find.text('Coach’s cues'), findsNothing);
    expect(find.text('Remember'), findsNothing);
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.byType(PageView));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 1);
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    final activePreview = tester.widget<Semantics>(find.byKey(ValueKey('workout-preview-${sampleDrills[1].id}')));
    expect(activePreview.properties.selected, isTrue);
    final activeMaterial = tester.widget<Material>(find.descendant(of: find.byKey(ValueKey('workout-preview-${sampleDrills[1].id}')), matching: find.byType(Material)));
    expect((activeMaterial.shape as RoundedRectangleBorder).side.width, 2);
    final previousPreview = tester.widget<Semantics>(find.byKey(ValueKey('workout-preview-${sampleDrills.first.id}')));
    expect(previousPreview.properties.selected, isFalse);
    final previousMaterial = tester.widget<Material>(find.descendant(of: find.byKey(ValueKey('workout-preview-${sampleDrills.first.id}')), matching: find.byType(Material)));
    expect((previousMaterial.shape as RoundedRectangleBorder).side.width, 1);
    await tester.tap(find.byKey(ValueKey('workout-preview-${sampleDrills.first.id}')));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 0);
    expect(find.text('Coach’s cues'), findsNothing);
    expect(find.text('Quiet hands, quick feet'), findsWidgets);
    final handle = find.byKey(const ValueKey('workout-sheet-handle'));
    expect(find.text('Log set').hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Log set')).dy, lessThanOrEqualTo(700));
    final sessionScroll = find.descendant(of: find.byKey(const ValueKey('workout-session-scroll')), matching: find.byType(Scrollable)).first;
    tester.state<ScrollableState>(sessionScroll).position.jumpTo(tester.state<ScrollableState>(sessionScroll).position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Log set').hitTestable(), findsOneWidget);
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    final expandedHeaderTop = tester.getTopLeft(find.byKey(const ValueKey('workout-status-header'))).dy;
    await tester.drag(handle, const Offset(40, 900));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your session').hitTestable(), findsNothing);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey('workout-status-header'))).dy, greaterThan(expandedHeaderTop));
    final navigationMotion = tester.widget<Transform>(find.byKey(const ValueKey('player-navigation-motion')));
    expect(navigationMotion.transform.getTranslation().y, 0);
    await tester.drag(handle, const Offset(-30, -300));
    await tester.pumpAndSettle();
    expect(container.read(workoutSheetProgressProvider), greaterThan(0));
    expect(tester.widget<Transform>(find.byKey(const ValueKey('player-navigation-motion'))).transform.getTranslation().y, greaterThan(0));
    final canceledDrag = await tester.startGesture(tester.getCenter(handle));
    await canceledDrag.moveBy(const Offset(20, 400));
    await canceledDrag.cancel();
    await tester.pumpAndSettle();
    expect(container.read(workoutSheetProgressProvider), closeTo(0, .001));
    expect(tester.takeException(), isNull);
    await tester.drag(handle, const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Me')));
    await tester.pumpAndSettle();
    expect(find.text('Jamie H.'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Train')));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('routine builder combines library drills and custom skill templates', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/routines');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create routine'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a drill from a template'));
    await tester.pumpAndSettle();
    expect(find.text('Create a drill'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.ensureVisible(find.text('Add drill'));
    await tester.tap(find.text('Add drill'));
    await tester.pumpAndSettle();
    expect(find.text('Create a drill'), findsNothing);
    expect(find.textContaining('Custom puck control'), findsOneWidget);

    final libraryDrill = find.widgetWithText(CheckboxListTile, 'Pick your corner');
    await tester.ensureVisible(libraryDrill);
    await tester.pumpAndSettle();
    await tester.tap(libraryDrill);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();

    final saved = container.read(routineLibraryProvider).last;
    expect(saved.drills.map((drill) => drill.title), ['Custom puck control', 'Pick your corner']);
    final restored = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider))]);
    addTearDown(restored.dispose);
    final restoredRoutine = restored.read(routineLibraryProvider).last;
    expect(restoredRoutine.id, saved.id);
    expect(restoredRoutine.name, saved.name);
    expect(restoredRoutine.drills.map((drill) => drill.title), saved.drills.map((drill) => drill.title));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest settings persist per drill and survive a new provider container', (tester) async {
    phoneSize(tester, scale: 2);
    final container = await mountApp(tester);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    final settingsButton = find.byTooltip('Drill settings · Rest off');
    await revealWorkoutDrill(tester);
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
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:02'), findsOneWidget);
    returnWorkoutSheetToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Workout overview'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await revealWorkoutDrill(tester);
    final overviewDrill = find.text('Quiet hands, quick feet').last;
    await tester.ensureVisible(overviewDrill);
    await tester.pumpAndSettle();
    await tester.tap(overviewDrill);
    await tester.pumpAndSettle();
    expect(find.text('0:02'), findsOneWidget);
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start timer'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('0:00'), findsWidgets);
    await tapWorkoutAction(tester, 'Log set');
    expect(container.read(trainingSessionProvider).logs.single.log.seconds, 3);
  });

  testWidgets('completing the last drill first offers the next unfinished drill', (tester) async {
    phoneSize(tester);
    final container = await mountApp(tester);
    container.read(trainingSessionProvider.notifier).start([
      for (final drill in [sampleDrills.first, sampleDrills[3]]) drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: 1)),
    ]);
    container.read(appRouterProvider).go('/session');
    await tester.pumpAndSettle();
    await revealWorkoutDrill(tester);
    await tester.ensureVisible(find.byType(PageView));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tapWorkoutAction(tester, 'Log set');
    await tester.tap(find.text('Next drill'));
    await tester.pumpAndSettle();
    expect(container.read(trainingSessionProvider).drillIndex, 0);
    await tapWorkoutAction(tester, 'Log set');
    expect(find.text('Finish workout'), findsOneWidget);
    expect(find.text('Next drill'), findsNothing);
    expect(container.read(trainingSessionProvider).finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
