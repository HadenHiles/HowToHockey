import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_catalog.dart';

List<Drill> loadCatalog() => parseDrillCatalog(File(drillCatalogAsset).readAsStringSync());

void main() {
  test('rejects unsupported catalog formats', () {
    expect(() => parseDrillCatalog('{"schemaVersion": 2, "drills": []}'), throwsFormatException);
    expect(() => parseDrillCatalog('[]'), throwsFormatException);
  });

  test('free players see every free starter drill', () {
    final catalog = loadCatalog();
    expect(visibleDrills(catalog, pro: false), hasLength(20));
    final withPro = [...catalog, catalog.first.copyWith(id: 'pro-only', tier: AccessTier.pro)];
    expect(visibleDrills(withPro, pro: false), hasLength(20));
    expect(visibleDrills(withPro, pro: true), hasLength(21));
  });

  test('filters narrow by skill, tracking, location, pucks, ball, and passer', () {
    final catalog = loadCatalog();
    List<String> ids(DrillFilters f) => applyDrillFilters(catalog, f).map((d) => d.id).toList();

    expect(ids(const DrillFilters(pillar: SkillPillar.passing)), containsAll(['pass-and-settle', 'target-saucer-passes', 'backhand-passes']));
    expect(applyDrillFilters(catalog, const DrillFilters(trackingType: TrackingType.binary)).map((d) => d.trackingType).toSet(), {TrackingType.binary});
    // Basement drills exclude ones that need a driveway or ice.
    expect(ids(const DrillFilters(location: LocationOption.basement)), isNot(contains('slap-shot-loads')));
    // Low puck counts exclude drills that need more pucks.
    expect(ids(const DrillFilters(puckInventory: PuckInventory.low)), isNot(contains('shot-burst-30')));
    expect(ids(const DrillFilters(puckInventory: PuckInventory.high)), contains('shot-burst-30'));
    // No-ball drills fit any ball choice; golf-ball-only filtering drops puck-and-ball drills that do not list it.
    expect(ids(const DrillFilters(ball: BallType.golfBall)), contains('squat-jumps'));
    expect(ids(const DrillFilters(ball: BallType.golfBall)), isNot(contains('slap-shot-loads')));
    // Drills that need no passer fit any passer choice.
    final withRebounder = ids(const DrillFilters(passer: PasserType.rebounder));
    expect(withRebounder, contains('pick-your-corner'));
    expect(withRebounder, contains('one-timer-reps'));
  });

  test('primary skill is the highest weighted skill', () {
    final drill = loadCatalog().firstWhere((d) => d.id == 'quiet-hands-quick-feet');
    expect(primaryPillar(drill), SkillPillar.hands);
  });

  Future<ProviderContainer> mount(WidgetTester tester, {bool pro = false}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        testCatalogOverride,
        testMediaOverride,
        testCuesOverride,
        testRemindersOverride,
        testAuthOverride,
        testProfilesOverride,
        testSessionsOverride,
        drillFiltersUnlockedProvider.overrideWithValue(pro),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/library');
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('library lists the starter drills and filters stay behind Player Pro for free players', (tester) async {
    await mount(tester);
    expect(find.textContaining('20 drills'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(7));

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('See Player Pro'), findsOneWidget);
    expect(find.text('Where you train'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pro players can filter by setup and clear filters', (tester) async {
    await mount(tester, pro: true);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Where you train'), findsOneWidget);
    await tester.tap(find.text('Basement').last);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Where you train'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Filters on'), findsOneWidget);
    expect(find.text('Slap-shot loads'), findsNothing);

    await tester.tap(find.text('Filters on'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Where you train'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('a catalog drill opens its detail page and unknown ids are handled', (tester) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    router.push('/drills/toe-drag-reps');
    await tester.pumpAndSettle();
    expect(find.text('Toe-drag reps'), findsWidgets);
    expect(find.text('Try this drill'), findsOneWidget);

    router.push('/drills/not-a-drill');
    await tester.pumpAndSettle();
    expect(find.text('Drill not found'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
