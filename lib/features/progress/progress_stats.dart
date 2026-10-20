import 'dart:math' as math;

import '../drills/models/drill.dart';
import '../drills/set_calculations.dart';

/// The most shots a person can plausibly take in a second; anything faster is a typo or a stuck timer.
const maxShotsPerSecond = 5;
const maxSessionSeconds = 3 * 3600;
const maxDaySeconds = 4 * 3600;

/// Hours of training for level 1, and how much more each level asks for. Level 10 is about 90 hours.
const levelOneSeconds = 3600.0;
const levelGrowth = 1.65;
const maxLevel = 10;

/// Seconds of training needed to reach [level] (1 to 10).
double secondsForLevel(int level) => levelOneSeconds * math.pow(levelGrowth, level - 1);

class SkillLevel {
  const SkillLevel({required this.level, required this.progress, required this.seconds});

  /// 0 before the first hour, up to 10.
  final int level;

  /// How far toward the next level, 0 up to (not including) 1. Always 0 at level 10.
  final double progress;
  final double seconds;

  /// Where the radar point sits: grows a little with every session and never shrinks.
  double get vertex => level + progress;

  double get hours => seconds / 3600;
}

SkillLevel skillLevelFor(double seconds) {
  var level = 0;
  while (level < maxLevel && seconds >= secondsForLevel(level + 1)) {
    level++;
  }
  if (level >= maxLevel) return SkillLevel(level: maxLevel, progress: 0, seconds: seconds);
  final floor = level == 0 ? 0.0 : secondsForLevel(level);
  final next = secondsForLevel(level + 1);
  return SkillLevel(level: level, progress: ((seconds - floor) / (next - floor)).clamp(0.0, 0.999999), seconds: seconds);
}

/// A set that can be trusted for stats. Impossible entries (too many shots too fast) are left out.
bool isCountableSet(Drill drill, SetLog log) {
  final seconds = log.seconds;
  if (seconds != null && (seconds <= 0 || seconds > 3600)) return false;
  final reps = log.reps;
  if (reps != null) {
    if (reps < 0 || reps > 10000) return false;
    final window = seconds ?? drill.estimatedSecondsPerSet;
    if (window > 0 && reps / window > maxShotsPerSecond) return false;
  }
  final streak = log.streak;
  if (streak != null && (streak < 0 || streak > 100000)) return false;
  return true;
}

/// Whether a drill is mostly shooting, so its reps count as shots.
bool isShootingDrill(Drill drill) => (drill.skillWeights[SkillPillar.shotAccuracy] ?? 0) + (drill.skillWeights[SkillPillar.shotPower] ?? 0) >= 0.5 && drill.trackingType != TrackingType.duration;

/// One kind of personal best, like "best accuracy in Pick your corner".
class PersonalBest {
  const PersonalBest({required this.key, required this.drillId, required this.title, required this.kind, required this.value, required this.achievedAt, required this.workoutId});

  final String key;
  final String drillId;
  final String title;
  final PersonalBestKind kind;
  final double value;
  final DateTime achievedAt;
  final String workoutId;

  String get valueLabel => switch (kind) {
    PersonalBestKind.accuracy => '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}%',
    PersonalBestKind.shotsPerMinute => '${value.round()} / min',
    PersonalBestKind.streak => '${value.round()}',
    PersonalBestKind.reps => '${value.round()} reps',
    PersonalBestKind.seconds => value >= 120 ? '${(value / 60).toStringAsFixed(1)} min' : '${value.round()} s',
  };

  Map<String, Object?> toJson() => {'key': key, 'drillId': drillId, 'title': title, 'kind': kind.name, 'value': value, 'achievedAt': achievedAt.toIso8601String(), 'workoutId': workoutId};

  static PersonalBest? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final kind = PersonalBestKind.values.where((k) => k.name == json['kind']).firstOrNull;
    final achieved = DateTime.tryParse('${json['achievedAt']}');
    if (kind == null || achieved == null || json['key'] is! String || json['drillId'] is! String || json['title'] is! String || json['value'] is! num || json['workoutId'] is! String) return null;
    return PersonalBest(
      key: json['key'] as String,
      drillId: json['drillId'] as String,
      title: json['title'] as String,
      kind: kind,
      value: (json['value'] as num).toDouble(),
      achievedAt: achieved,
      workoutId: json['workoutId'] as String,
    );
  }
}

enum PersonalBestKind { accuracy, shotsPerMinute, streak, reps, seconds }

/// What one finished workout adds up to, after dropping impossible sets and applying the time caps.
class WorkoutCredit {
  const WorkoutCredit({required this.seconds, required this.shots, required this.pillarSeconds, required this.bests});

  final double seconds;
  final int shots;
  final Map<SkillPillar, double> pillarSeconds;

  /// The best result in this workout for each personal-best key.
  final Map<String, PersonalBest> bests;
}

/// A finished workout, reduced to what stats need so this file doesn't depend on the session class.
class WorkoutRecord {
  const WorkoutRecord({required this.id, required this.startedAt, required this.drills, required this.logs, this.explicitTzOffsetMinutes});

  final String id;
  final DateTime startedAt;
  final int? explicitTzOffsetMinutes;

  /// Minutes east of UTC on the player's phone when they trained, so a day means the same thing everywhere.
  int get tzOffsetMinutes => explicitTzOffsetMinutes ?? startedAt.toLocal().timeZoneOffset.inMinutes;
  final List<Drill> drills;
  final List<({String drillId, SetLog log})> logs;
}

/// Works out what a workout is worth. [daySecondsSoFar] is what that day already earned, for the daily cap.
WorkoutCredit creditFor(WorkoutRecord workout, {double daySecondsSoFar = 0}) {
  final byId = {for (final drill in workout.drills) drill.id: drill};
  final counted = <({Drill drill, SetLog log, int seconds})>[];
  for (final entry in workout.logs) {
    final drill = byId[entry.drillId];
    if (drill == null || !isCountableSet(drill, entry.log)) continue;
    counted.add((drill: drill, log: entry.log, seconds: activeSecondsForSet(entry.log, drill)));
  }
  final raw = counted.fold<int>(0, (sum, set) => sum + set.seconds);
  final allowed = math.min(math.min(raw.toDouble(), maxSessionSeconds.toDouble()), math.max(0.0, maxDaySeconds - daySecondsSoFar));
  final factor = raw == 0 ? 0.0 : allowed / raw;

  final pillarSeconds = <SkillPillar, double>{};
  var shots = 0;
  final bests = <String, PersonalBest>{};
  void consider(String key, Drill drill, PersonalBestKind kind, double value, DateTime when) {
    if (value <= 0) return;
    final current = bests[key];
    if (current == null || value > current.value) {
      bests[key] = PersonalBest(key: key, drillId: drill.id, title: drill.title, kind: kind, value: value, achievedAt: when, workoutId: workout.id);
    }
  }

  for (final set in counted) {
    final credited = set.seconds * factor;
    for (final weight in set.drill.skillWeights.entries) {
      pillarSeconds[weight.key] = (pillarSeconds[weight.key] ?? 0) + credited * weight.value;
    }
    final log = set.log;
    final when = log.loggedAt;
    if (isShootingDrill(set.drill)) shots += log.reps ?? 0;
    switch (set.drill.trackingType) {
      case TrackingType.accuracy:
        final fraction = accuracyFraction(log);
        if (fraction != null && (log.reps ?? 0) >= 10) consider('accuracy:${set.drill.id}', set.drill, PersonalBestKind.accuracy, fraction * 100, when);
      case TrackingType.density:
        final perMinute = shotsPerMinute(log);
        if (perMinute != null) consider('density:${set.drill.id}', set.drill, PersonalBestKind.shotsPerMinute, perMinute, when);
      case TrackingType.streak:
        consider('streak:${set.drill.id}', set.drill, PersonalBestKind.streak, (log.streak ?? 0).toDouble(), when);
      case TrackingType.volume:
        consider('reps:${set.drill.id}', set.drill, PersonalBestKind.reps, (log.reps ?? 0).toDouble(), when);
      case TrackingType.duration:
        consider('seconds:${set.drill.id}', set.drill, PersonalBestKind.seconds, (log.seconds ?? 0).toDouble(), when);
      case TrackingType.binary:
        break;
    }
  }
  return WorkoutCredit(seconds: allowed, shots: shots, pillarSeconds: pillarSeconds, bests: bests);
}

/// The calendar day of [when] for someone [tzOffsetMinutes] east of UTC, as `yyyy-MM-dd`.
String dayKeyAt(DateTime when, int tzOffsetMinutes) {
  final shifted = when.toUtc().add(Duration(minutes: tzOffsetMinutes));
  return '${shifted.year.toString().padLeft(4, '0')}-${shifted.month.toString().padLeft(2, '0')}-${shifted.day.toString().padLeft(2, '0')}';
}

/// The calendar day of [when] on this phone.
String dayKey(DateTime when) => dayKeyAt(when, when.toLocal().timeZoneOffset.inMinutes);

DateTime _dayFromKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

class DayStats {
  const DayStats({this.seconds = 0, this.shots = 0});

  final double seconds;
  final int shots;
}

const _keepDays = 400;

/// Everything the Progress tab shows, built up one finished workout at a time so it
/// still adds up after the workout history is trimmed.
class LifetimeStats {
  const LifetimeStats({this.workouts = 0, this.seconds = 0, this.shots = 0, this.pillarSeconds = const {}, this.bests = const {}, this.days = const {}, this.counted = const <String>{}});

  final int workouts;
  final double seconds;
  final int shots;
  final Map<SkillPillar, double> pillarSeconds;
  final Map<String, PersonalBest> bests;

  /// Time and shots per calendar day (`yyyy-MM-dd`), for the week chart, streaks and the daily cap.
  final Map<String, DayStats> days;

  /// Workouts already counted, so adding one twice changes nothing.
  final Set<String> counted;

  SkillLevel levelOf(SkillPillar pillar) => skillLevelFor(pillarSeconds[pillar] ?? 0);

  /// Adds a finished workout. Returns the new stats and the personal bests it set.
  ({LifetimeStats stats, List<PersonalBest> newBests}) add(WorkoutRecord workout) {
    if (counted.contains(workout.id)) return (stats: this, newBests: const []);
    final key = dayKeyAt(workout.startedAt, workout.tzOffsetMinutes);
    final credit = creditFor(workout, daySecondsSoFar: days[key]?.seconds ?? 0);

    final nextBests = {...bests};
    final newBests = <PersonalBest>[];
    for (final entry in credit.bests.entries) {
      final current = nextBests[entry.key];
      if (current == null || entry.value.value > current.value) {
        nextBests[entry.key] = entry.value;
        newBests.add(entry.value);
      }
    }
    final nextPillars = {...pillarSeconds};
    for (final entry in credit.pillarSeconds.entries) {
      nextPillars[entry.key] = (nextPillars[entry.key] ?? 0) + entry.value;
    }
    final day = days[key] ?? const DayStats();
    final nextDays = {...days, key: DayStats(seconds: day.seconds + credit.seconds, shots: day.shots + credit.shots)};
    final keep = nextDays.keys.toList()..sort();
    for (final old in keep.take(math.max(0, keep.length - _keepDays))) {
      nextDays.remove(old);
    }
    return (
      stats: LifetimeStats(
        workouts: workouts + 1,
        seconds: seconds + credit.seconds,
        shots: shots + credit.shots,
        pillarSeconds: nextPillars,
        bests: nextBests,
        days: nextDays,
        counted: {...counted, workout.id},
      ),
      newBests: newBests,
    );
  }

  /// Consecutive training days ending today, or ending yesterday if today hasn't happened yet.
  int currentStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var cursor = days.containsKey(dayKey(today)) ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.containsKey(dayKey(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  int longestStreak() {
    final keys = days.keys.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final key in keys) {
      final day = _dayFromKey(key);
      run = previous != null && DateTime(previous.year, previous.month, previous.day + 1) == day ? run + 1 : 1;
      best = math.max(best, run);
      previous = day;
    }
    return best;
  }

  /// The seven days ending today, oldest first.
  List<({DateTime day, DayStats stats})> lastSevenDays(DateTime now) => [
    for (var i = 6; i >= 0; i--) (day: DateTime(now.year, now.month, now.day - i), stats: days[dayKey(DateTime(now.year, now.month, now.day - i))] ?? const DayStats()),
  ];

  double weekSeconds(DateTime now) => lastSevenDays(now).fold(0.0, (sum, d) => sum + d.stats.seconds);

  int weekShots(DateTime now) => lastSevenDays(now).fold(0, (sum, d) => sum + d.stats.shots);

  Map<String, Object?> toJson() => {
    'workouts': workouts,
    'seconds': seconds,
    'shots': shots,
    'pillarSeconds': {for (final e in pillarSeconds.entries) e.key.name: e.value},
    'bests': [for (final b in bests.values) b.toJson()],
    'days': {
      for (final e in days.entries) e.key: [e.value.seconds, e.value.shots],
    },
    'counted': counted.toList(),
  };

  /// Reads saved stats, or returns null if they are damaged (the caller rebuilds from history).
  static LifetimeStats? fromJson(Object? json) {
    try {
      if (json is! Map<String, dynamic>) return null;
      final pillars = <SkillPillar, double>{};
      for (final entry in (json['pillarSeconds'] as Map).entries) {
        final pillar = SkillPillar.values.where((p) => p.name == entry.key).firstOrNull;
        if (pillar == null) return null;
        pillars[pillar] = (entry.value as num).toDouble();
      }
      final bests = <String, PersonalBest>{};
      for (final raw in json['bests'] as List) {
        final best = PersonalBest.fromJson(raw);
        if (best == null) return null;
        bests[best.key] = best;
      }
      final days = <String, DayStats>{};
      for (final entry in (json['days'] as Map).entries) {
        final value = entry.value as List;
        days['${entry.key}'] = DayStats(seconds: (value[0] as num).toDouble(), shots: (value[1] as num).toInt());
      }
      return LifetimeStats(
        workouts: (json['workouts'] as num).toInt(),
        seconds: (json['seconds'] as num).toDouble(),
        shots: (json['shots'] as num).toInt(),
        pillarSeconds: pillars,
        bests: bests,
        days: days,
        // Locally saved stats list every counted workout; the cloud copy lists only the latest few.
        counted: {for (final id in (json['counted'] as List?) ?? (json['recent'] as List?) ?? const []) '$id'},
      );
    } on Object {
      return null;
    }
  }
}

/// How the radar reads: each skill's level plus progress, on a 0 to 100 scale.
List<int> radarScores(LifetimeStats stats) => [for (final pillar in SkillPillar.values) (stats.levelOf(pillar).vertex * 10).round().clamp(0, 100)];
