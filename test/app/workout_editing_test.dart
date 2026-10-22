import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/app/drill_picker.dart';
import 'package:how_to_hockey/app/routine_state.dart';
import 'package:how_to_hockey/app/sample_data.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/app/workout_sync.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/drills/set_calculations.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Drill withSets(Drill drill, int sets) => drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: sets));

final wrist = sampleDrills[0];
final hands = sampleDrills[1];
final corner = sampleDrills[3];

Future<ProviderContainer> open([Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues(saved);
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
      testTeamsOverride,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> flush() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('editing a workout in progress', () {
    test('adding drills skips repeats and reopens a finished workout', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 1)]);
      notifier.logSet(reps: 10);
      expect(container.read(trainingSessionProvider).finished, isTrue);

      expect(notifier.addDrills([wrist, hands]), 1);
      final session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [wrist.id, hands.id]);
      expect(session.finished, isFalse);
      expect(session.endedAt, isNull);
      expect(notifier.addDrills([hands]), 0);
    });

    test('moving a drill keeps the selected drill and every logged set', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands, corner]);
      notifier.selectDrill(1);
      notifier.logSet(seconds: 30);
      notifier.moveDrill(1, 0);
      var session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [hands.id, wrist.id, corner.id]);
      expect(session.drill.id, hands.id);
      expect(session.setsLogged(0), 1);
      notifier.moveDrill(0, 2);
      session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [wrist.id, corner.id, hands.id]);
      expect(session.drill.id, hands.id);
      expect(session.drillIndex, 2);
      expect(() => notifier.moveDrill(0, 3), throwsRangeError);
    });

    test('a drill with logged sets can\'t be removed or swapped, and the last drill stays', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands]);
      notifier.logSet(reps: 8);
      expect(() => notifier.removeDrill(0), throwsStateError);
      expect(() => notifier.swapDrill(0, corner), throwsStateError);
      notifier.removeDrill(1);
      expect(container.read(trainingSessionProvider).drills.map((d) => d.id), [wrist.id]);
      expect(() => notifier.removeDrill(0), throwsStateError);
      expect(container.read(trainingSessionProvider).logs, hasLength(1));
    });

    test('removing an earlier drill keeps the same drill selected', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands, corner]);
      notifier.selectDrill(2);
      notifier.removeDrill(0);
      expect(container.read(trainingSessionProvider).drill.id, corner.id);
    });

    test('sets can be added and unlogged sets taken away, within limits', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 2)]);
      notifier.addSet(0);
      expect(container.read(trainingSessionProvider).drills.single.defaultPrescription.sets, 3);
      notifier.logSet(reps: 10);
      notifier.removeUnloggedSet(0);
      notifier.removeUnloggedSet(0);
      expect(container.read(trainingSessionProvider).drills.single.defaultPrescription.sets, 1);
      expect(() => notifier.removeUnloggedSet(0), throwsStateError, reason: 'the only set is logged');
      expect(container.read(trainingSessionProvider).finished, isTrue, reason: 'nothing is left to do');

      for (var i = 1; i < TrainingSessionNotifier.maxSetsPerDrill; i++) {
        notifier.addSet(0);
      }
      expect(() => notifier.addSet(0), throwsStateError);
    });

    test('ending a drill early keeps its logged sets and skipped sets earn nothing', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 4), hands]);
      expect(() => notifier.endDrillEarly(0), throwsStateError, reason: 'nothing logged yet');
      notifier.logSet(reps: 9);
      notifier.logSet(reps: 11);
      final before = container.read(trainingSessionProvider).activeSeconds;
      notifier.endDrillEarly(0);
      final session = container.read(trainingSessionProvider);
      expect(session.drills.first.defaultPrescription.sets, 2);
      expect(session.logs.map((e) => e.log.reps), [9, 11]);
      expect(session.activeSeconds, before);
      expect(session.finished, isFalse, reason: 'the second drill is still to do');
    });

    test('finishing early drops unstarted drills, stops partial ones and records only what happened', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands, corner]);
      expect(() => notifier.finishEarly(), throwsStateError);
      notifier.selectDrill(1);
      notifier.logSet(seconds: 30);
      notifier.finishEarly();
      final session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [hands.id]);
      expect(session.drills.single.defaultPrescription.sets, 1);
      expect(session.finished, isTrue);
      expect(session.endedAt, isNotNull);
      expect(session.logs, hasLength(1));
      notifier.dismissFinishedWorkout();
      await flush();
      expect(container.read(workoutHistoryProvider).single.logs, hasLength(1));
    });

    test('undoing a set reopens a finished workout; editing keeps the time and validates', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(corner, 2)]);
      notifier.logSet(reps: 10, hits: 5);
      notifier.logSet(reps: 10, hits: 7);
      expect(container.read(trainingSessionProvider).finished, isTrue);

      notifier.undoLastSet(0);
      var session = container.read(trainingSessionProvider);
      expect(session.logs, hasLength(1));
      expect(session.finished, isFalse);
      expect(session.endedAt, isNull);
      expect(session.setIndex, 1);

      final loggedAt = session.logs.single.log.loggedAt;
      notifier.editSet(0, 0, reps: 10, hits: 6);
      session = container.read(trainingSessionProvider);
      expect(session.logs.single.log.hits, 6);
      expect(session.logs.single.log.loggedAt, loggedAt);
      expect(() => notifier.editSet(0, 0, reps: 10, hits: 11), throwsA(isA<InvalidSetEntry>()));
      expect(() => notifier.editSet(0, 1, reps: 10, hits: 5), throwsStateError, reason: 'set 2 was undone');
      expect(session.logs.single.log.hits, 6, reason: 'a rejected edit changes nothing');

      notifier.logSet(reps: 10, hits: 8);
      expect(container.read(trainingSessionProvider).finished, isTrue);
      expect(() => notifier.undoLastSet(1), throwsRangeError);
    });

    test('edits survive the app being killed', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands]);
      notifier.logSet(reps: 5);
      notifier.addDrills([corner]);
      notifier.moveDrill(2, 0);
      notifier.addSet(1);
      notifier.editSet(1, 0, reps: 7);
      await flush();

      final restored = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)), testAuthOverride, testProfilesOverride, testSessionsOverride],
      );
      addTearDown(restored.dispose);
      final session = restored.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [corner.id, wrist.id, hands.id]);
      expect(session.drills[1].defaultPrescription.sets, 3);
      expect(session.logs.single.log.reps, 7);
    });

    test('a saved workout can no longer be edited', () async {
      final container = await open();
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 1)]);
      notifier.logSet(reps: 10);
      notifier.dismissFinishedWorkout();
      expect(() => notifier.addSet(0), throwsStateError);
      expect(() => notifier.editSet(0, 0, reps: 3), throwsStateError);
      expect(() => notifier.addDrills([hands]), throwsStateError);
    });
  });

  group('my drills', () {
    test('template drills use only structured choices and read sensibly for each way of tracking', () {
      final timed = createTemplateDrill(SkillPillar.hands, sets: 3, seconds: 45, trackingType: TrackingType.duration);
      expect(timed.defaultPrescription.seconds, 45);
      expect(timed.defaultPrescription.reps, isNull);
      expect(timed.estimatedSecondsPerSet, 45);

      final accuracy = createTemplateDrill(SkillPillar.shotAccuracy, sets: 2, reps: 20, trackingType: TrackingType.accuracy);
      expect(accuracy.defaultPrescription.reps, 20);
      expect(accuracy.prescriptionLabel, '2 sets · 20 reps');

      final done = createTemplateDrill(SkillPillar.endurance, sets: 2, trackingType: TrackingType.binary);
      expect(done.defaultPrescription.reps, isNull);
      expect(done.targetLabel, 'complete');
      expect(createTemplateDrill(SkillPillar.hands, sets: 1, trackingType: TrackingType.streak).targetLabel, 'best streak');
      expect(() => createTemplateDrill(SkillPillar.hands, sets: 1, trackingType: TrackingType.density), throwsArgumentError);
    });

    test('titles stay distinct so two of a kind never read as the same drill', () {
      final first = createTemplateDrill(SkillPillar.hands, sets: 2);
      final second = createTemplateDrill(SkillPillar.hands, sets: 2, existingTitles: [first.title]);
      final third = createTemplateDrill(SkillPillar.hands, sets: 2, existingTitles: [first.title, second.title]);
      expect([first.title, second.title, third.title], ['Custom puck control', 'Custom puck control 2', 'Custom puck control 3']);
    });

    test('saved drills persist, are not duplicated, can be deleted and are capped', () async {
      final container = await open();
      final library = container.read(customDrillLibraryProvider.notifier);
      final drill = createTemplateDrill(SkillPillar.passing, sets: 2, trackingType: TrackingType.streak);
      await library.add(drill);
      await library.add(drill);
      expect(container.read(customDrillLibraryProvider), hasLength(1));

      final restored = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider))]);
      addTearDown(restored.dispose);
      final back = restored.read(customDrillLibraryProvider).single;
      expect(back.id, drill.id);
      expect(back.trackingType, TrackingType.streak);

      await library.remove(drill.id);
      expect(container.read(customDrillLibraryProvider), isEmpty);
      for (var i = 0; i < CustomDrillLibrary.maxDrills; i++) {
        await library.add(createTemplateDrill(SkillPillar.hands, sets: 2).copyWith(id: 'custom-$i'));
      }
      await expectLater(library.add(createTemplateDrill(SkillPillar.hands, sets: 2)), throwsStateError);
    });

    test('unreadable saved drills are reported and treated as empty', () async {
      final container = await open({'customDrills': 'not json'});
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);
      expect(container.read(customDrillLibraryProvider), isEmpty);
      expect(errors, hasLength(1));
    });
  });

  group('last results', () {
    test('show only the training player\'s own history, newest first', () async {
      const own = PlayerProfile(id: 'parent-uid', ownerUid: 'parent-uid', displayName: 'Pat H.', birthYear: 1985, isChild: false);
      const kid = PlayerProfile(id: 'child-1', ownerUid: 'parent-uid', displayName: 'Avery H.', birthYear: 2015, isChild: true);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      testAuth.signOutSilently(const GuestSession('guest'));
      testProfiles.own = own;
      testProfiles.children
        ..clear()
        ..add(kid);
      final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), testCatalogOverride, testAuthOverride, testProfilesOverride, testSessionsOverride]);
      addTearDown(container.dispose);
      container.listen(workoutSyncProvider, (_, _) {});
      container.listen(lastResultsProvider, (_, _) {});
      await flush();
      addTearDown(() => testAuth.signOutSilently(const GuestSession('guest')));
      testAuth.signInSilently(const SignedInAccount(uid: 'parent-uid', email: 'p@example.com', emailVerified: true));
      await flush();
      await flush();

      TrainingSession done(DateTime at, int reps) => TrainingSession(
        drills: [withSets(wrist, 1)],
        startedAt: at.toUtc(),
        endedAt: at.toUtc().add(const Duration(minutes: 3)),
        logs: [(drillId: wrist.id, log: SetLog(setIndex: 0, reps: reps, loggedAt: at.toUtc()))],
      );

      container.read(activePlayerIdProvider.notifier).choose(own.id);
      await flush();
      container.read(workoutHistoryProvider.notifier).add(done(DateTime(2026, 10, 1, 9), 11));
      container.read(workoutHistoryProvider.notifier).add(done(DateTime(2026, 10, 3, 9), 14));
      container.read(activePlayerIdProvider.notifier).choose(kid.id);
      await flush();
      container.read(workoutHistoryProvider.notifier).add(done(DateTime(2026, 10, 2, 9), 5));
      await flush();

      expect(container.read(lastResultsProvider)[wrist.id]!.sets.single.reps, 5, reason: 'the child sees only their own workout');
      container.read(activePlayerIdProvider.notifier).choose(own.id);
      await flush();
      expect(container.read(playerHistoryProvider).map((w) => w.logs.single.log.reps), [14, 11], reason: 'newest first');
      expect(container.read(lastResultsProvider)[wrist.id]!.sets.single.reps, 14, reason: 'the parent sees their newest, not the child\'s');
      expect(container.read(playerHistoryProvider), hasLength(2));
    });
  });

  group('screens', () {
    Future<ProviderContainer> mount(WidgetTester tester, {Size size = const Size(1000, 3000), double scale = 1}) async {
      final container = await open({'workoutStandardView': true});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> openOverview(WidgetTester tester, ProviderContainer container) async {
      container.read(appRouterProvider).go('/train/session');
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester, String key) => tester.widget<TextField>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField))).controller!.text;

    Future<void> typeInto(WidgetTester tester, String key, String text) async {
      final field = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('sets are logged in place from the list, in order, and a typed correction or undo works', (tester) async {
      final container = await mount(tester);
      container.read(trainingSessionProvider.notifier).start([wrist, hands]);
      await openOverview(tester, container);

      expect(find.text('Workout'), findsOneWidget);
      expect(fieldText(tester, 'set-quick-release-wrist-shots-0-reps'), '10', reason: 'the plan fills the set');
      await tapVisible(tester, find.byKey(const ValueKey('check-quick-release-wrist-shots-1')));
      expect(container.read(trainingSessionProvider).logs, isEmpty, reason: 'set 2 waits for set 1');

      await typeInto(tester, 'set-quick-release-wrist-shots-0-reps', '7');
      await tapVisible(tester, find.byKey(const ValueKey('check-quick-release-wrist-shots-0')));
      expect(container.read(trainingSessionProvider).logs.single.log.reps, 7);

      await typeInto(tester, 'set-quick-release-wrist-shots-0-reps', '12');
      expect(container.read(trainingSessionProvider).logs.single.log.reps, 12, reason: 'editing a logged set corrects it');

      await typeInto(tester, 'set-quick-release-wrist-shots-0-reps', '');
      expect(container.read(trainingSessionProvider).logs.single.log.reps, 12, reason: 'an invalid correction is explained, not applied');
      expect(find.text('Enter how many reps you did.'), findsOneWidget);
      expect(fieldText(tester, 'set-quick-release-wrist-shots-0-reps'), '12');

      await tapVisible(tester, find.byKey(const ValueKey('check-quick-release-wrist-shots-1')));
      expect(container.read(trainingSessionProvider).logs, hasLength(2));
      await tapVisible(tester, find.byKey(const ValueKey('check-quick-release-wrist-shots-0')));
      expect(container.read(trainingSessionProvider).logs, hasLength(2), reason: 'only the latest set can be undone');
      await tapVisible(tester, find.byKey(const ValueKey('check-quick-release-wrist-shots-1')));
      expect(container.read(trainingSessionProvider).logs.map((e) => e.log.reps), [12]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every kind of drill has the right inputs, rejects bad entries and finishes from the list', (tester) async {
      final container = await mount(tester);
      final drills = [for (final d in sampleDrills) withSets(d, 1)];
      container.read(trainingSessionProvider.notifier).start(drills);
      await openOverview(tester, container);

      Future<void> check(Drill drill) => tapVisible(tester, find.byKey(ValueKey('check-${drill.id}-0')));
      // Accuracy: shots and hits, hits can't exceed shots.
      expect(find.byKey(const ValueKey('set-pick-your-corner-0-reps')), findsOneWidget);
      await typeInto(tester, 'set-pick-your-corner-0-hits', '11');
      await check(corner);
      expect(find.text('Hits can\'t be more than the shots you took.'), findsOneWidget);
      expect(container.read(trainingSessionProvider).logs, isEmpty);
      await typeInto(tester, 'set-pick-your-corner-0-hits', '6');
      await check(corner);
      // Volume, timed, shots-per-minute, streak.
      await check(wrist);
      await check(hands);
      await typeInto(tester, 'set-shot-burst-30-0-reps', '14');
      await check(sampleDrills[2]);
      await typeInto(tester, 'set-pass-and-settle-0-streak', '9');
      await check(sampleDrills[4]);
      // Completion has no number to type.
      expect(find.byType(TextField), findsWidgets);
      expect(find.byKey(const ValueKey('set-athletic-stance-reset-0-reps')), findsNothing);
      await check(sampleDrills[5]);

      final session = container.read(trainingSessionProvider);
      expect(session.finished, isTrue);
      final byDrill = {for (final e in session.logs) e.drillId: e.log};
      expect(byDrill[corner.id]!.hits, 6);
      expect(byDrill[wrist.id]!.reps, 10);
      expect(byDrill[hands.id]!.seconds, 30);
      expect(byDrill['shot-burst-30']!.reps, 14);
      expect(byDrill['pass-and-settle']!.streak, 9);
      expect(byDrill['athletic-stance-reset']!.completed, isTrue);

      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).dismissed, isTrue);
      expect(container.read(workoutHistoryProvider), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('drills are added through the shared picker, which also makes and remembers your own drills', (tester) async {
      final container = await mount(tester);
      container.read(trainingSessionProvider.notifier).start([wrist]);
      await openOverview(tester, container);

      await tapVisible(tester, find.text('Add drills'));
      expect(find.text('Choose drills'), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-drill-quick-release-wrist-shots')), findsNothing, reason: 'already in the workout');
      await tester.enterText(find.descendant(of: find.byType(DrillPickerSheet), matching: find.byType(TextField)), 'corner');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('picker-drill-pick-your-corner')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('picker-drill-pick-your-corner')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create drill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timed'.replaceFirst('Timed', 'Duration')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save to My drills'));
      await tester.tap(find.text('Save to My drills'));
      await tester.pumpAndSettle();
      expect(find.text('Add 2 drills'), findsOneWidget, reason: 'the new drill is selected along with the one already ticked');
      await tester.tap(find.text('Add 2 drills'));
      await tester.pumpAndSettle();

      final session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.title), ['Quick-release wrist shots', 'Pick your corner', 'Custom puck control']);
      expect(session.drills.last.trackingType, TrackingType.duration);
      expect(container.read(customDrillLibraryProvider), hasLength(1));
      expect(find.text('Custom puck control'), findsWidgets);

      // The saved drill is offered again later, under My drills.
      container.read(trainingSessionProvider.notifier).removeDrill(2);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Add drills'));
      expect(find.text('My drills'), findsOneWidget);
      expect(find.text('Custom puck control'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete Custom puck control'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(container.read(customDrillLibraryProvider), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drills can be moved, replaced and removed from the overview, and the drill pages follow', (tester) async {
      final container = await mount(tester);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands, corner]);
      await openOverview(tester, container);

      await tapVisible(tester, find.byKey(const ValueKey('overview-menu-0')));
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      var session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [hands.id, wrist.id, corner.id]);
      expect(session.drill.id, wrist.id, reason: 'the drill being worked on stays selected');

      await tapVisible(tester, find.byKey(const ValueKey('overview-menu-2')));
      await tester.tap(find.text('Remove drill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [hands.id, wrist.id]);

      notifier.selectDrill(1);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('overview-menu-1')));
      await tester.tap(find.text('Simple view'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Drill 2 of 2'), findsOneWidget);
      expect(container.read(trainingSessionProvider).drill.id, wrist.id);
      expect(tester.takeException(), isNull);
    });

    testWidgets('finishing early explains what is kept, and logged work is saved without credit for skipped sets', (tester) async {
      final container = await mount(tester);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, hands]);
      notifier.logSet(reps: 6);
      await openOverview(tester, container);

      await tapVisible(tester, find.text('Finish workout early'));
      expect(find.textContaining('Drills you haven\'t started are left out: Quiet hands, quick feet.'), findsOneWidget);
      expect(find.textContaining('Skipped sets earn nothing.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).drills, hasLength(2));

      await tapVisible(tester, find.text('Finish workout early'));
      await tester.tap(find.text('Finish workout').last);
      await tester.pumpAndSettle();
      final session = container.read(trainingSessionProvider);
      expect(session.finished, isTrue);
      expect(session.logs.map((e) => e.log.reps), [6]);
      expect(find.text('Finish workout early'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('previous results appear beside the drill while training', (tester) async {
      final container = await mount(tester);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 1)]);
      notifier.logSet(reps: 19);
      notifier.dismissFinishedWorkout();
      await tester.pump();
      notifier.start([wrist]);
      await openOverview(tester, container);
      expect(fieldText(tester, 'set-quick-release-wrist-shots-0-reps'), '19', reason: 'the set starts from last time');
      expect(find.text('19'), findsWidgets, reason: 'and last time is shown in the PREVIOUS column');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a saved workout can be repeated or saved as a routine', (tester) async {
      final container = await mount(tester);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([withSets(wrist, 1), withSets(hands, 1)]);
      notifier.logSet(reps: 10);
      notifier.selectDrill(1);
      notifier.logSet(seconds: 30);
      notifier.dismissFinishedWorkout();
      await tester.pump();
      final saved = container.read(workoutHistoryProvider).single;

      container.read(appRouterProvider).go('/history/${workoutId(saved)}');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save as routine'));
      final routine = container.read(routineLibraryProvider).last;
      expect(routine.drills.map((d) => d.id), [wrist.id, hands.id]);

      container.read(trainingSessionProvider.notifier).start([corner]);
      await tapVisible(tester, find.text('Repeat this workout'));
      expect(find.text('Replace your current workout?'), findsOneWidget);
      await tester.tap(find.text('Keep current'));
      await tester.pumpAndSettle();
      expect(container.read(trainingSessionProvider).drills.single.id, corner.id);

      await tapVisible(tester, find.text('Repeat this workout'));
      await tester.tap(find.text('Start this one'));
      await tester.pumpAndSettle();
      final session = container.read(trainingSessionProvider);
      expect(session.drills.map((d) => d.id), [wrist.id, hands.id]);
      expect(session.logs, isEmpty, reason: 'a repeat starts fresh');
      expect(tester.takeException(), isNull);
    });

    testWidgets('routines can be duplicated, and their drills reordered and resized', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/routines');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Duplicate'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(container.read(routineLibraryProvider).map((r) => r.name), ['Foundation Builder', 'Foundation Builder copy']);
      final copy = container.read(routineLibraryProvider).last;
      expect(copy.id, isNot('foundation'));

      container.read(appRouterProvider).go('/routines/${copy.id}/edit');
      await tester.pumpAndSettle();
      final first = copy.drills.first;
      await tapVisible(tester, find.byTooltip('Move ${first.title} down'));
      await tapVisible(tester, find.byTooltip('More sets for ${first.title}'));
      await tapVisible(tester, find.text('Save routine'));
      final edited = container.read(routineLibraryProvider).firstWhere((r) => r.id == copy.id);
      expect(edited.drills[1].id, first.id);
      expect(edited.drills[1].defaultPrescription.sets, first.defaultPrescription.sets + 1);
      expect(container.read(routineLibraryProvider).firstWhere((r) => r.id == 'foundation').drills.first.id, first.id, reason: 'the original is untouched');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the new screens fit a 320 px phone at 2x text', (tester) async {
      final container = await mount(tester, size: const Size(640, 1136), scale: 2);
      final notifier = container.read(trainingSessionProvider.notifier);
      notifier.start([wrist, corner]);
      notifier.logSet(reps: 8);
      await openOverview(tester, container);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byKey(const ValueKey('overview-menu-0')));
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('check-pick-your-corner-0')));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Add drills'));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Create drill'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      container.read(appRouterProvider).go('/routines/new');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
