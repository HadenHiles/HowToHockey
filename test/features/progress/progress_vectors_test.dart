import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';

/// The same cases the Cloud Function is tested with (`functions/test/progress.test.ts`), so the
/// device and the server always agree. To refresh the expected values after changing a rule on
/// purpose, run this test with `--dart-define=WRITE_VECTORS=true` and review the diff.
const vectorFile = 'functions/test/vectors/progress.json';
const writeVectors = bool.fromEnvironment('WRITE_VECTORS');

Drill drillFrom(Map<String, dynamic> d) => Drill(
  id: d['id'] as String,
  title: d['title'] as String,
  mediaAssetPath: 'x',
  formCues: const [],
  trackingType: TrackingType.values.firstWhere((t) => t.name == d['tracking']),
  allowedLocations: const [],
  minPuckInventory: PuckInventory.low,
  requiresPasser: false,
  skillWeights: {for (final e in (d['weights'] as Map).entries) SkillPillar.values.firstWhere((p) => p.name == e.key): (e.value as num).toDouble()},
  tier: AccessTier.free,
  supportedBalls: const [],
  passerTypes: const [],
  defaultPrescription: const DrillPrescription(sets: 1),
  estimatedSecondsPerSet: d['estimatedSecondsPerSet'] as int,
  difficulty: 1,
  tags: const [],
);

WorkoutRecord recordFrom(Map<String, dynamic> workout, Map<String, Drill> library) {
  final used = <String, Drill>{};
  final logs = <({String drillId, SetLog log})>[];
  for (final set in workout['sets'] as List) {
    final drill = library[set['drill']]!;
    used[drill.id] = drill;
    final l = set['log'] as Map<String, dynamic>;
    logs.add((
      drillId: drill.id,
      log: SetLog(
        setIndex: 0,
        reps: l['reps'] as int?,
        hits: l['hits'] as int?,
        seconds: l['seconds'] as int?,
        streak: l['streak'] as int?,
        completed: l['completed'] as bool?,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(l['loggedAtMs'] as int, isUtc: true),
      ),
    ));
  }
  return WorkoutRecord(
    id: workout['id'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(workout['startedAtMs'] as int, isUtc: true),
    drills: used.values.toList(),
    logs: logs,
    explicitTzOffsetMinutes: workout['tzOffsetMinutes'] as int,
  );
}

double round6(double v) => (v * 1e6).round() / 1e6;

Map<String, Object?> creditJson(WorkoutCredit credit) => {
  'seconds': round6(credit.seconds),
  'shots': credit.shots,
  'pillarSeconds': {for (final e in credit.pillarSeconds.entries) e.key.name: round6(e.value)},
  'bests': {for (final e in credit.bests.entries) e.key: round6(e.value.value)},
};

Map<String, Object?> statsJson(LifetimeStats stats, List<List<String>> newBestKeys) => {
  'workouts': stats.workouts,
  'seconds': round6(stats.seconds),
  'shots': stats.shots,
  'pillarSeconds': {for (final e in stats.pillarSeconds.entries) e.key.name: round6(e.value)},
  'bests': {for (final e in stats.bests.entries) e.key: round6(e.value.value)},
  'days': {
    for (final e in stats.days.entries) e.key: [round6(e.value.seconds), e.value.shots],
  },
  'newBestKeys': newBestKeys,
};

void main() {
  final vectors = jsonDecode(File(vectorFile).readAsStringSync()) as Map<String, dynamic>;
  final library = {for (final e in (vectors['drills'] as Map<String, dynamic>).entries) e.key: drillFrom(e.value as Map<String, dynamic>)};
  final computed = <String, Object?>{};

  for (final c in vectors['cases'] as List) {
    test('credit: ${c['name']}', () {
      final actual = creditJson(creditFor(recordFrom(c['workout'], library), daySecondsSoFar: (c['daySecondsSoFar'] as num).toDouble()));
      computed['case:${c['name']}'] = actual;
      if (!writeVectors) expect(jsonDecode(jsonEncode(actual)), c['expected']);
    });
  }
  for (final s in vectors['sequences'] as List) {
    test('stats: ${s['name']}', () {
      var stats = const LifetimeStats();
      final newKeys = <List<String>>[];
      for (final w in s['workouts'] as List) {
        final result = stats.add(recordFrom(w, library));
        stats = result.stats;
        newKeys.add([for (final b in result.newBests) b.key]..sort());
      }
      final actual = statsJson(stats, newKeys);
      computed['seq:${s['name']}'] = actual;
      if (!writeVectors) expect(jsonDecode(jsonEncode(actual)), s['expected']);
    });
  }

  tearDownAll(() {
    if (!writeVectors) return;
    for (final c in vectors['cases'] as List) {
      c['expected'] = jsonDecode(jsonEncode(computed['case:${c['name']}']));
    }
    for (final s in vectors['sequences'] as List) {
      s['expected'] = jsonDecode(jsonEncode(computed['seq:${s['name']}']));
    }
    File(vectorFile).writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(vectors)}\n');
  });
}
