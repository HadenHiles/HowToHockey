import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/progress/drill_trends.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';

final catalog = {for (final d in parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())) d.id: d};

WorkoutRecord workout(int day, List<(String, SetLog)> sets) {
  final at = DateTime.utc(2026, 10, day, 12);
  return WorkoutRecord(
    id: 'w$day',
    startedAt: at,
    drills: [
      for (final id in {for (final s in sets) s.$1}) catalog[id]!,
    ],
    logs: [for (final s in sets) (drillId: s.$1, log: s.$2)],
  );
}

SetLog log({int? reps, int? hits, int? seconds, int? streak, bool? completed}) =>
    SetLog(setIndex: 0, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: DateTime.utc(2026, 10, 1));

void main() {
  test('each drill gets one value per workout, oldest first, whatever order they arrive in', () {
    final trends = drillTrends([
      workout(20, [('pick-your-corner', log(reps: 10, hits: 9))]),
      workout(18, [('pick-your-corner', log(reps: 10, hits: 5)), ('pick-your-corner', log(reps: 10, hits: 7))]),
      workout(19, [('pick-your-corner', log(reps: 10, hits: 6))]),
    ]);
    expect(trends, hasLength(1));
    final trend = trends.single;
    expect(trend.points.map((p) => p.value), [60, 60, 90]);
    expect(trend.points.map((p) => p.at.day), [18, 19, 20]);
    expect(trend.totalSets, 4);
    expect(trend.latest, 90);
    expect(trend.best, 90);
    expect(trend.format(90), '90%');
  });

  test('every kind of drill is measured the way it should be', () {
    final trends = {
      for (final t in drillTrends([
        workout(20, [
          ('quick-release-wrist-shots', log(reps: 12)),
          ('quick-release-wrist-shots', log(reps: 13)),
          ('shot-burst-30', log(reps: 20, seconds: 30)),
          ('ball-bounce-streak', log(streak: 9)),
          ('ball-bounce-streak', log(streak: 21)),
          ('quiet-hands-quick-feet', log(seconds: 30)),
          ('quiet-hands-quick-feet', log(seconds: 45)),
          ('athletic-stance-reset', log(completed: true)),
          ('athletic-stance-reset', log(completed: false)),
        ]),
      ]))
        t.drillId: t,
    };
    expect(trends['quick-release-wrist-shots']!.latest, 25);
    expect(trends['quick-release-wrist-shots']!.format(25), '25 reps');
    expect(trends['shot-burst-30']!.latest, 40);
    expect(trends['shot-burst-30']!.format(40), '40 / min');
    expect(trends['ball-bounce-streak']!.latest, 21);
    expect(trends['quiet-hands-quick-feet']!.latest, 75);
    expect(trends['quiet-hands-quick-feet']!.format(75), '75 s');
    expect(trends['quiet-hands-quick-feet']!.format(150), '2.5 min');
    expect(trends['athletic-stance-reset']!.latest, 50);
    expect(trends['athletic-stance-reset']!.format(50), '50% done');
    for (final t in trends.values) {
      expect(t.metricLabel, isNotEmpty);
    }
  });

  test('impossible sets are left out, and a drill with nothing usable does not appear', () {
    final trends = drillTrends([
      workout(20, [('pick-your-corner', log(reps: 500, hits: 5)), ('quick-release-wrist-shots', log(reps: 15))]),
    ]);
    expect(trends.map((t) => t.drillId), ['quick-release-wrist-shots']);
    expect(drillTrends(const []), isEmpty);
  });

  test('most-trained drills come first, then by name', () {
    final trends = drillTrends([
      workout(18, [('toe-drag-reps', log(reps: 10)), ('pick-your-corner', log(reps: 10, hits: 5))]),
      workout(19, [('pick-your-corner', log(reps: 10, hits: 6))]),
      workout(20, [('bottom-shelf-snaps', log(reps: 10, hits: 6))]),
    ]);
    expect(trends.map((t) => t.title).first, 'Pick your corner');
    expect(trends.skip(1).map((t) => t.title), [...trends.skip(1).map((t) => t.title)]..sort());
  });
}
