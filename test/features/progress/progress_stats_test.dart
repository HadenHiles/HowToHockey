import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';

final catalog = {for (final d in parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())) d.id: d};
Drill drill(String id) => catalog[id]!;

final noon = DateTime(2026, 10, 19, 12);

SetLog setLog({int? reps, int? hits, int? seconds, int? streak, bool? completed, DateTime? at}) =>
    SetLog(setIndex: 0, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: at ?? noon);

WorkoutRecord workout(String id, DateTime at, List<(String, SetLog)> sets) {
  final ids = {for (final s in sets) s.$1}.toList();
  return WorkoutRecord(id: id, startedAt: at, drills: [for (final i in ids) drill(i)], logs: [for (final s in sets) (drillId: s.$1, log: s.$2)]);
}

void main() {
  group('skill levels', () {
    test('level one is an hour and level ten is about ninety', () {
      expect(secondsForLevel(1), 3600);
      expect(secondsForLevel(10) / 3600, closeTo(90.3, 0.5));
      expect(skillLevelFor(0).level, 0);
      expect(skillLevelFor(3599).level, 0);
      expect(skillLevelFor(3600).level, 1);
      expect(skillLevelFor(3600 * 1.65).level, 2);
      expect(skillLevelFor(10 * 3600 * 1000).level, maxLevel);
      expect(skillLevelFor(10 * 3600 * 1000).progress, 0);
    });

    test('the radar point only ever grows with more time', () {
      var last = -1.0;
      for (var seconds = 0.0; seconds < 400000; seconds += 997) {
        final vertex = skillLevelFor(seconds).vertex;
        expect(vertex, greaterThanOrEqualTo(last));
        last = vertex;
      }
      expect(skillLevelFor(1800).vertex, closeTo(0.5, 0.01));
    });
  });

  group('what counts', () {
    test('impossible sets are dropped', () {
      final shooting = drill('pick-your-corner');
      expect(isCountableSet(shooting, setLog(reps: 10, hits: 5)), isTrue);
      expect(isCountableSet(shooting, setLog(reps: 500, hits: 5)), isFalse, reason: '500 shots in a minute');
      expect(isCountableSet(shooting, setLog(reps: 10, seconds: 1)), isFalse, reason: '10 shots in a second');
      expect(isCountableSet(shooting, setLog(reps: 10, seconds: 5000)), isFalse);
      expect(isCountableSet(shooting, setLog(reps: -1)), isFalse);
      expect(isCountableSet(drill('ball-bounce-streak'), setLog(streak: 999999)), isFalse);
    });

    test('shots come from shooting drills only', () {
      expect(isShootingDrill(drill('pick-your-corner')), isTrue);
      expect(isShootingDrill(drill('quick-release-wrist-shots')), isTrue);
      expect(isShootingDrill(drill('shot-burst-30')), isFalse, reason: 'mostly conditioning');
      expect(isShootingDrill(drill('toe-drag-reps')), isFalse);
    });

    test('time is split across skills by the drill weights, and rest is not counted', () {
      final credit = creditFor(workout('w', noon, [('pick-your-corner', setLog(reps: 10, hits: 6))]));
      final seconds = drill('pick-your-corner').estimatedSecondsPerSet;
      expect(credit.seconds, seconds);
      expect(credit.pillarSeconds[SkillPillar.shotAccuracy], closeTo(seconds * 0.8, 0.001));
      expect(credit.pillarSeconds[SkillPillar.shotPower], closeTo(seconds * 0.2, 0.001));
      expect(credit.shots, 10);
    });

    test('a timed set counts the time actually run', () {
      final credit = creditFor(workout('w', noon, [('quiet-hands-quick-feet', setLog(seconds: 20))]));
      expect(credit.seconds, 20);
    });

    test('a session and a day each have a cap', () {
      final sets = [for (var i = 0; i < 200; i++) ('quiet-hands-quick-feet', setLog(seconds: 3000))];
      final credit = creditFor(workout('w', noon, sets));
      expect(credit.seconds, ProgressTuning.defaults.maxSessionSeconds);
      expect(credit.pillarSeconds.values.fold(0.0, (a, b) => a + b), closeTo(ProgressTuning.defaults.maxSessionSeconds, 0.5));
      expect(creditFor(workout('w', noon, sets), daySecondsSoFar: ProgressTuning.defaults.maxDaySeconds - 600.0).seconds, 600);
      expect(creditFor(workout('w', noon, sets), daySecondsSoFar: ProgressTuning.defaults.maxDaySeconds.toDouble()).seconds, 0);
    });
  });

  group('tuning', () {
    test('caps, shot speed and level steps follow the tuning', () {
      const tuning = ProgressTuning(maxShotsPerSecond: 1, maxSessionSeconds: 600, maxDaySeconds: 900, levelOneSeconds: 1800, levelGrowth: 2);
      final sets = [for (var i = 0; i < 100; i++) ('quiet-hands-quick-feet', setLog(seconds: 100))];
      expect(creditFor(workout('w', noon, sets), tuning: tuning).seconds, 600);
      expect(creditFor(workout('w', noon, sets), daySecondsSoFar: 500, tuning: tuning).seconds, 400);
      expect(isCountableSet(drill('pick-your-corner'), setLog(reps: 100, seconds: 60), tuning), isFalse, reason: 'faster than 1 a second');
      expect(isCountableSet(drill('pick-your-corner'), setLog(reps: 100, seconds: 60)), isTrue);
      expect(secondsForLevel(1, tuning), 1800);
      expect(secondsForLevel(4, tuning), 14400);
      expect(skillLevelFor(1800, tuning).level, 1);
      expect(skillLevelFor(3599, tuning).level, 1);
      expect(skillLevelFor(3600, tuning).level, 2);
      final stats = const LifetimeStats().add(workout('a', noon, sets), tuning: tuning).stats;
      expect(stats.seconds, 600);
      expect(radarScores(LifetimeStats(pillarSeconds: {SkillPillar.hands: 1800}), tuning)[1], 10);
    });

    test('remote values are used when sensible and ignored when not', () {
      expect(ProgressTuning.fromValues(), ProgressTuning.defaults);
      final tuned = ProgressTuning.fromValues(maxShotsPerSecond: 8, maxSessionSeconds: 7200, maxDaySeconds: 10800, levelOneSeconds: 1200, levelGrowth: 1.5);
      expect(tuned.maxShotsPerSecond, 8);
      expect(tuned.maxSessionSeconds, 7200);
      expect(tuned.maxDaySeconds, 10800);
      expect(tuned.levelOneSeconds, 1200);
      expect(tuned.levelGrowth, 1.5);
      final bad = ProgressTuning.fromValues(maxShotsPerSecond: 0, maxSessionSeconds: -5, maxDaySeconds: double.nan, levelOneSeconds: 99999999, levelGrowth: 0.5);
      expect(bad, ProgressTuning.defaults);
    });
  });

  group('personal bests', () {
    test('keeps the best set for each kind of result', () {
      final credit = creditFor(
        workout('w', noon, [
          ('pick-your-corner', setLog(reps: 10, hits: 6)),
          ('pick-your-corner', setLog(reps: 10, hits: 8)),
          ('pick-your-corner', setLog(reps: 4, hits: 4)),
          ('ball-bounce-streak', setLog(streak: 12)),
          ('ball-bounce-streak', setLog(streak: 30)),
          ('quick-release-wrist-shots', setLog(reps: 15)),
          ('shot-burst-30', setLog(reps: 20, seconds: 30)),
          ('quiet-hands-quick-feet', setLog(seconds: 45)),
          ('athletic-stance-reset', setLog(completed: true)),
        ]),
      );
      expect(credit.bests['accuracy:pick-your-corner']!.value, 80, reason: 'a 4-for-4 set is too small to count');
      expect(credit.bests['streak:ball-bounce-streak']!.value, 30);
      expect(credit.bests['reps:quick-release-wrist-shots']!.value, 15);
      expect(credit.bests['density:shot-burst-30']!.value, 40);
      expect(credit.bests['seconds:quiet-hands-quick-feet']!.value, 45);
      expect(credit.bests.keys.any((k) => k.contains('athletic-stance-reset')), isFalse);
      expect(credit.bests['accuracy:pick-your-corner']!.valueLabel, '80%');
      expect(credit.bests['density:shot-burst-30']!.valueLabel, '40 / min');
    });
  });

  group('lifetime stats', () {
    test('adds workouts up, reports new personal bests, and ignores a repeat', () {
      var stats = const LifetimeStats();
      final first = stats.add(workout('a', noon, [('pick-your-corner', setLog(reps: 10, hits: 5))]));
      stats = first.stats;
      expect(first.newBests, hasLength(1));
      expect(stats.workouts, 1);
      expect(stats.shots, 10);

      final worse = stats.add(workout('b', noon.add(const Duration(hours: 1)), [('pick-your-corner', setLog(reps: 10, hits: 3))]));
      expect(worse.newBests, isEmpty);
      final better = worse.stats.add(workout('c', noon.add(const Duration(hours: 2)), [('pick-your-corner', setLog(reps: 10, hits: 9))]));
      expect(better.newBests.single.value, 90);
      expect(better.stats.bests['accuracy:pick-your-corner']!.workoutId, 'c');

      final again = better.stats.add(workout('c', noon, [('pick-your-corner', setLog(reps: 10, hits: 10))]));
      expect(again.stats, same(better.stats));
      expect(better.stats.workouts, 3);
    });

    test('the daily cap holds across several workouts in one day', () {
      var stats = const LifetimeStats();
      final long = [for (var i = 0; i < 100; i++) ('quiet-hands-quick-feet', setLog(seconds: 3500))];
      for (var i = 0; i < 4; i++) {
        stats = stats.add(workout('w$i', noon.add(Duration(minutes: i)), long)).stats;
      }
      expect(stats.days[dayKey(noon)]!.seconds, closeTo(ProgressTuning.defaults.maxDaySeconds, 0.5));
      expect(stats.seconds, closeTo(ProgressTuning.defaults.maxDaySeconds, 0.5));
    });

    test('streaks count consecutive days, allow today to still be open, and break on a gap', () {
      var stats = const LifetimeStats();
      var n = 0;
      for (final daysAgo in [0, 1, 2, 4, 5, 6, 7]) {
        stats = stats.add(workout('w${n++}', noon.subtract(Duration(days: daysAgo)), [('quiet-hands-quick-feet', setLog(seconds: 30))])).stats;
      }
      expect(stats.currentStreak(noon), 3);
      expect(stats.longestStreak(), 4);
      expect(stats.currentStreak(noon.add(const Duration(days: 1))), 3, reason: 'yesterday still counts until today ends');
      expect(stats.currentStreak(noon.add(const Duration(days: 2))), 0);
      expect(const LifetimeStats().currentStreak(noon), 0);
      expect(const LifetimeStats().longestStreak(), 0);
    });

    test('the week view lists seven days ending today, with their time and shots', () {
      var stats = const LifetimeStats();
      stats = stats.add(workout('a', noon, [('pick-your-corner', setLog(reps: 10, hits: 5))])).stats;
      stats = stats.add(workout('b', noon.subtract(const Duration(days: 2)), [('pick-your-corner', setLog(reps: 20, hits: 5))])).stats;
      stats = stats.add(workout('old', noon.subtract(const Duration(days: 9)), [('pick-your-corner', setLog(reps: 30, hits: 5))])).stats;
      final week = stats.lastSevenDays(noon);
      expect(week, hasLength(7));
      expect(week.last.day, DateTime(2026, 10, 19));
      expect(week.last.stats.shots, 10);
      expect(week[4].stats.shots, 20);
      expect(stats.weekShots(noon), 30);
      expect(stats.shots, 60);
      expect(stats.weekSeconds(noon), drill('pick-your-corner').estimatedSecondsPerSet * 2);
    });

    test('survives saving and loading, and refuses damaged data', () {
      var stats = const LifetimeStats();
      stats = stats.add(workout('a', noon, [('pick-your-corner', setLog(reps: 10, hits: 5)), ('ball-bounce-streak', setLog(streak: 9))])).stats;
      final restored = LifetimeStats.fromJson(stats.toJson())!;
      expect(restored.workouts, stats.workouts);
      expect(restored.shots, stats.shots);
      expect(restored.pillarSeconds, stats.pillarSeconds);
      expect(restored.bests.keys, stats.bests.keys);
      expect(restored.counted, stats.counted);
      expect(restored.days[dayKey(noon)]!.shots, 10);

      expect(LifetimeStats.fromJson(null), isNull);
      expect(LifetimeStats.fromJson({'workouts': 'x'}), isNull);
      expect(
        LifetimeStats.fromJson({
          ...stats.toJson(),
          'pillarSeconds': {'nope': 1},
        }),
        isNull,
      );
    });

    test('old days are trimmed but lifetime totals are not', () {
      var stats = const LifetimeStats();
      for (var i = 0; i < 420; i++) {
        stats = stats.add(workout('w$i', DateTime(2025, 1, 1).add(Duration(days: i)), [('pick-your-corner', setLog(reps: 10, hits: 5))])).stats;
      }
      expect(stats.days.length, 400);
      expect(stats.workouts, 420);
      expect(stats.shots, 4200);
    });

    test('radar scores follow the levels and stay between 0 and 100', () {
      expect(radarScores(const LifetimeStats()), [0, 0, 0, 0, 0, 0]);
      final stats = LifetimeStats(pillarSeconds: {SkillPillar.shotAccuracy: 1800, SkillPillar.hands: 10 * 3600 * 1000});
      final scores = radarScores(stats);
      expect(scores[0], 5);
      expect(scores[1], 100);
    });
  });
}
