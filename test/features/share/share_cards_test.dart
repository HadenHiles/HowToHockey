import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/design/theme/app_theme.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';
import 'package:how_to_hockey/features/share/share_card.dart';
import 'package:how_to_hockey/features/share/share_data.dart';
import 'package:how_to_hockey/features/share/share_service.dart';

final corner = parseDrillCatalog(File(drillCatalogAsset).readAsStringSync()).firstWhere((d) => d.id == 'pick-your-corner');

PersonalBest best(String title, PersonalBestKind kind, double value, DateTime at) =>
    PersonalBest(key: 'k:$title', drillId: title, title: title, kind: kind, value: value, achievedAt: at, workoutId: 'w');

Future<ui.Image> decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

void main() {
  final now = DateTime(2026, 10, 20, 12);

  group('card contents', () {
    test('a workout card leads with shots, then time, drills and sets, and lists the bests it set', () {
      final data = workoutCard(shots: 42, activeSeconds: 1500, drills: 6, sets: 15, bests: [best('Pick your corner', PersonalBestKind.accuracy, 80, now)], streakDays: 3, dateLabel: 'Today');
      expect(data.heroValue, '42');
      expect(data.heroLabel, 'shots');
      expect(data.stats.map((s) => '${s.value} ${s.label}'), ['25 min active', '6 drills', '15 sets']);
      expect(data.badges, ['Pick your corner · 80%']);
      expect(data.streakDays, 3);
      expect(data.semanticLabel, allOf(contains('42 shots'), contains('3 day streak'), contains('Personal best: Pick your corner · 80%')));
    });

    test('a workout with no shots leads with the time instead, and singulars read right', () {
      final data = workoutCard(shots: 0, activeSeconds: 600, drills: 1, sets: 1, bests: const [], streakDays: 0, dateLabel: 'Today');
      expect(data.heroValue, '10 min');
      expect(data.heroLabel, 'active training');
      expect(data.stats.map((s) => '${s.value} ${s.label}'), ['1 drill', '1 set']);
      expect(workoutCard(shots: 1, activeSeconds: 60, drills: 1, sets: 1, bests: const [], streakDays: 0, dateLabel: 'x').heroLabel, 'shot');
      expect(data.semanticLabel, isNot(contains('streak')));
      expect(workoutCard(shots: 5, activeSeconds: 7200, drills: 2, sets: 3, bests: const [], streakDays: 0, dateLabel: 'x').stats.first.value, '2.0 h');
    });

    test('a weekly card adds up the last seven days, with only this week\'s bests', () {
      var stats = const LifetimeStats();
      WorkoutRecord workout(String id, DateTime at, int reps, int hits) {
        final drill = corner;
        return WorkoutRecord(
          id: id,
          startedAt: at,
          drills: [drill],
          logs: [(drillId: drill.id, log: SetLog(setIndex: 0, reps: reps, hits: hits, loggedAt: at))],
        );
      }

      stats = stats.add(workout('a', now.subtract(const Duration(days: 20)), 10, 9)).stats;
      stats = stats.add(workout('b', now.subtract(const Duration(days: 1)), 10, 5)).stats;
      stats = stats.add(workout('c', now, 20, 10)).stats;
      final data = weekCard(stats: stats, now: now, dateLabel: 'Last 7 days');
      expect(data.heroValue, '30');
      expect(data.heroLabel, 'shots this week');
      expect(data.stats.map((s) => '${s.value} ${s.label}').last, '2 days trained');
      expect(data.streakDays, 2);
      expect(data.badges, isEmpty, reason: 'the 90% from 20 days ago is not this week\'s');
      expect(weekCard(stats: const LifetimeStats(), now: now, dateLabel: 'x').heroValue, '0 min');
    });

    test('cards carry no name or other identity', () {
      final text = workoutCard(shots: 5, activeSeconds: 60, drills: 1, sets: 1, bests: const [], streakDays: 1, dateLabel: 'Today').semanticLabel;
      expect(text, isNot(contains('Avery')));
      expect(text, startsWith('How To Hockey.'));
    });
  });

  group('rendering', () {
    final data = workoutCard(
      shots: 42,
      activeSeconds: 1500,
      drills: 6,
      sets: 15,
      bests: [
        best('Pick your corner', PersonalBestKind.accuracy, 80, now),
        best('Ball bounce', PersonalBestKind.streak, 22, now),
        best('Wrist shots', PersonalBestKind.reps, 19, now),
        best('Fourth', PersonalBestKind.reps, 1, now),
      ],
      streakDays: 5,
      dateLabel: 'Today',
    );

    for (final format in ShareFormat.values) {
      testWidgets('${format.label} renders without overflow and exports at 1080 pixels wide', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: HockeyTheme.light,
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: ShareCard(data: data, format: format),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ShareCard)), Size(format.width, format.height));
        expect(find.text('42'), findsOneWidget);
        expect(find.text('SHOTS'), findsOneWidget);
        expect(find.text('5-day streak'), findsOneWidget);
        expect(find.textContaining('Pick your corner'), findsOneWidget);
        expect(find.textContaining('Fourth'), findsNothing, reason: 'at most ${format == ShareFormat.story ? 3 : 2} badges fit');

        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
        final png = (await tester.runAsync(() => renderShareImage(boundary, format)))!;
        final image = (await tester.runAsync(() => decode(png)))!;
        expect(image.width, 1080);
        expect(image.height, format == ShareFormat.story ? 1920 : 1080);
        expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: 'a PNG');
      });
    }

    testWidgets('looks the same at any text size and in a dark theme, with long numbers', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final long = workoutCard(
        shots: 1234567,
        activeSeconds: 360000,
        drills: 40,
        sets: 120,
        bests: [best('A really quite long drill title that keeps going', PersonalBestKind.reps, 120, now)],
        streakDays: 365,
        dateLabel: 'Mon, Oct 12',
      );
      for (final format in ShareFormat.values) {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: HockeyTheme.dark,
            home: Scaffold(
              body: Center(
                child: ShareCard(data: long, format: format),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: format.label);
        expect(tester.getSize(find.byType(ShareCard)), Size(format.width, format.height));
      }
    });
  });
}
