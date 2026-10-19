import 'dart:math';

import '../drills/models/drill.dart';

/// Everything the generator needs. It is a plain value so the same input always gives the same routine.
class GeneratorInput {
  const GeneratorInput({
    required this.catalog,
    required this.location,
    required this.inventory,
    required this.focus,
    required this.minutes,
    this.ball,
    this.passer,
    this.pro = false,
    this.recentSessions = const [],
    this.seed = 0,
    this.variety = 0.06,
    this.avoid = const {},
  });

  final List<Drill> catalog;
  final LocationOption location;
  final PuckInventory inventory;
  final BallType? ball;
  final PasserType? passer;

  /// Focus points per skill; expected to total 100.
  final Map<SkillPillar, int> focus;

  /// Target session length: 15 to 60.
  final int minutes;
  final bool pro;

  /// Drill IDs from recent finished workouts, newest first.
  final List<List<String>> recentSessions;

  /// Varies the small random nudge between equally good drills. Same seed, same routine.
  final int seed;

  /// How far the random nudge can move a drill's score. "Try another" raises it.
  final double variety;

  /// Drills to steer away from, such as the workout the player just skipped with "Try another".
  final Set<String> avoid;
}

class GeneratedRoutine {
  const GeneratedRoutine({required this.drills, required this.estimatedSeconds});

  final List<Drill> drills;
  final int estimatedSeconds;

  int get estimatedMinutes => (estimatedSeconds / 60).round();

  int get totalSets => drills.fold(0, (sum, drill) => sum + drill.defaultPrescription.sets);
}

const minRoutineMinutes = 15;
const maxRoutineMinutes = 60;
const routineLengthOptions = [15, 20, 30, 45];

const _minDrills = 3;
const _setupSecondsPerDrill = 20;
const _retrievalSecondsPerSet = 20;
const _recoveryTag = 'recovery';
const _warmUpTag = 'warm-up';

/// Which drills can be done with this setup, before any ranking.
List<Drill> eligibleDrills(GeneratorInput input) => [
  for (final drill in input.catalog)
    if (_isEligible(drill, input)) drill,
];

bool _isEligible(Drill drill, GeneratorInput input) {
  if (drill.tier == AccessTier.pro && !input.pro) return false;
  if (!drill.allowedLocations.contains(input.location)) return false;
  // A ball stands in for pucks when the drill supports it, so a low puck count doesn't rule it out.
  final enoughPucks = drill.minPuckInventory.index <= input.inventory.index || (input.ball != null && drill.supportedBalls.contains(input.ball));
  if (!enoughPucks) return false;
  if (drill.requiresPasser && (input.passer == null || !drill.passerTypes.contains(input.passer))) return false;
  return true;
}

/// The skill a drill mostly trains.
SkillPillar dominantPillar(Drill drill) {
  final weights = drill.skillWeights.entries.toList()
    ..sort((a, b) {
      final byWeight = b.value.compareTo(a.value);
      return byWeight != 0 ? byWeight : a.key.index.compareTo(b.key.index);
    });
  return weights.first.key;
}

/// How well a drill matches the focus: each skill's share of the focus times the drill's weight for it.
double focusScore(Drill drill, Map<SkillPillar, int> focus) => drill.skillWeights.entries.fold(0.0, (sum, entry) => sum + (focus[entry.key] ?? 0) / 100 * entry.value);

/// How long one drill takes, including picking pucks back up when there are only a few.
int drillSeconds(Drill drill, PuckInventory inventory) {
  final retrieval = inventory == PuckInventory.low && const {TrackingType.volume, TrackingType.accuracy, TrackingType.density}.contains(drill.trackingType) ? _retrievalSecondsPerSet : 0;
  return drill.defaultPrescription.sets * (drill.estimatedSecondsPerSet + retrieval) + _setupSecondsPerDrill;
}

/// Splits [total] across [weights] in proportion, whole numbers only, always adding up to [total].
/// The biggest leftover fractions get the extra units; ties go to the earlier entry.
List<int> largestRemainder(List<num> weights, int total) {
  final sum = weights.fold<num>(0, (a, b) => a + b);
  if (total <= 0 || sum <= 0) return List.filled(weights.length, 0);
  final exact = [for (final weight in weights) weight / sum * total];
  final result = [for (final value in exact) value.floor()];
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byFraction = (exact[b] - result[b]).compareTo(exact[a] - result[a]);
      return byFraction != 0 ? byFraction : a.compareTo(b);
    });
  final leftover = total - result.fold(0, (a, b) => a + b);
  for (var i = 0; i < leftover; i++) {
    result[order[i]]++;
  }
  return result;
}

double _jitter(int seed, String id, double variety) {
  var hash = 2166136261 ^ seed;
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
  }
  return (Random(hash).nextDouble() - 0.5) * variety;
}

/// Builds a workout from the catalog, the player's setup and their focus. Pure and deterministic.
GeneratedRoutine generateRoutine(GeneratorInput input) {
  final minutes = input.minutes.clamp(minRoutineMinutes, maxRoutineMinutes);
  final budget = minutes * 60;
  final pool = eligibleDrills(input);
  final recovery = pool.where((d) => d.tags.contains(_recoveryTag)).toList();
  final trainable = pool.where((d) => !d.tags.contains(_recoveryTag)).toList();
  if (trainable.isEmpty) return const GeneratedRoutine(drills: [], estimatedSeconds: 0);

  final baseScore = <String, double>{};
  for (final drill in trainable) {
    var score = focusScore(drill, input.focus) + _jitter(input.seed, drill.id, input.variety);
    final recentIndex = input.recentSessions.indexWhere((session) => session.contains(drill.id));
    if (recentIndex >= 0) score -= 0.18 / (recentIndex + 1);
    if (input.avoid.contains(drill.id)) score -= 0.5;
    if (input.inventory == PuckInventory.low && drill.minPuckInventory == PuckInventory.low) score += 0.08;
    if (input.inventory == PuckInventory.high && drill.trackingType == TrackingType.density) score += 0.08;
    baseScore[drill.id] = score;
  }

  final averageSeconds = trainable.fold(0, (sum, d) => sum + drillSeconds(d, input.inventory)) / trainable.length;
  final reserved = minutes >= 30 && recovery.isNotEmpty ? drillSeconds(recovery.first, input.inventory) : 0;
  final slots = ((budget - reserved) / averageSeconds).round().clamp(3, 8).clamp(1, trainable.length);

  final pillars = SkillPillar.values.where((p) => (input.focus[p] ?? 0) > 0 && trainable.any((d) => dominantPillar(d) == p)).toList();
  final focusOrder = [...pillars]..sort((a, b) => (input.focus[b] ?? 0).compareTo(input.focus[a] ?? 0) == 0 ? a.index.compareTo(b.index) : (input.focus[b] ?? 0).compareTo(input.focus[a] ?? 0));
  final quota = pillars.isEmpty
      ? <SkillPillar, int>{}
      : {
          for (final (i, share) in largestRemainder([for (final p in pillars) input.focus[p]!], slots).indexed) pillars[i]: share,
        };

  final chosen = <Drill>[];
  final usedGroups = <String, int>{};
  var groupLimit = 1;
  final usedTracking = <TrackingType>{};

  Drill? pick(Iterable<Drill> candidates, {bool onlyFocused = false}) {
    Drill? best;
    var bestScore = double.negativeInfinity;
    for (final drill in candidates) {
      if (chosen.contains(drill)) continue;
      if (onlyFocused && focusScore(drill, input.focus) <= 0) continue;
      if (drill.swapGroup != null && (usedGroups[drill.swapGroup] ?? 0) >= groupLimit) continue;
      final score = baseScore[drill.id]! - (usedTracking.contains(drill.trackingType) ? 0.08 : 0);
      if (score > bestScore || (score == bestScore && best != null && drill.id.compareTo(best.id) < 0)) {
        best = drill;
        bestScore = score;
      }
    }
    return best;
  }

  void take(Drill drill) {
    chosen.add(drill);
    if (drill.swapGroup != null) usedGroups[drill.swapGroup!] = (usedGroups[drill.swapGroup] ?? 0) + 1;
    usedTracking.add(drill.trackingType);
  }

  // First pass keeps drills from the same swap group out of one workout. A skill whose quota is still
  // unfilled (its drills are mostly interchangeable, like the accuracy targets) may then use a second.
  final unfilled = <SkillPillar, int>{};
  for (final pillar in focusOrder) {
    var missing = quota[pillar] ?? 0;
    while (missing > 0) {
      final drill = pick(trainable.where((d) => dominantPillar(d) == pillar));
      if (drill == null) break;
      take(drill);
      missing--;
    }
    if (missing > 0) unfilled[pillar] = missing;
  }
  groupLimit = 2;
  for (final entry in unfilled.entries) {
    for (var i = 0; i < entry.value; i++) {
      final drill = pick(trainable.where((d) => dominantPillar(d) == entry.key));
      if (drill == null) break;
      take(drill);
    }
  }
  groupLimit = 1;
  // Slots a skill couldn't fill (all its drills used or swappable with one already chosen) go to the best remaining drills.
  while (chosen.length < slots) {
    final drill = pick(trainable, onlyFocused: true);
    if (drill == null) break;
    take(drill);
  }
  // A very narrow focus can leave fewer than three drills; a workout needs at least that many.
  while (chosen.length < _minDrills && chosen.length < trainable.length) {
    final drill = pick(trainable) ?? pick(trainable.where((d) => !chosen.contains(d)).map((d) => d));
    if (drill == null) break;
    take(drill);
  }

  var ordered = _order(chosen, baseScore);
  var seconds = ordered.fold(0, (sum, d) => sum + drillSeconds(d, input.inventory));
  if (reserved > 0 && seconds + reserved <= budget * 1.15) {
    ordered = [...ordered, recovery.first];
    seconds += reserved;
  }
  return _fitSets(ordered, baseScore, input.inventory, budget);
}

/// Warm-up first, recovery last, finishers (streaks, density, conditioning) near the end,
/// and the rest in the middle with the best matches first.
List<Drill> _order(List<Drill> drills, Map<String, double> score) {
  int phase(Drill d) {
    if (d.tags.contains(_recoveryTag)) return 3;
    if (d.tags.contains(_warmUpTag) || (d.difficulty <= 1 && dominantPillar(d) != SkillPillar.endurance)) return 0;
    if (d.trackingType == TrackingType.streak || d.trackingType == TrackingType.density || dominantPillar(d) == SkillPillar.endurance) return 2;
    return 1;
  }

  return [...drills]..sort((a, b) {
    final byPhase = phase(a).compareTo(phase(b));
    if (byPhase != 0) return byPhase;
    final byScore = (score[b.id] ?? 0).compareTo(score[a.id] ?? 0);
    return byScore != 0 ? byScore : a.id.compareTo(b.id);
  });
}

/// Nudges set counts (one up or down from the drill's default) so the total lands near the target time.
GeneratedRoutine _fitSets(List<Drill> drills, Map<String, double> score, PuckInventory inventory, int budget) {
  final working = [...drills];
  int total() => working.fold(0, (sum, d) => sum + drillSeconds(d, inventory));
  final defaults = {for (final d in drills) d.id: d.defaultPrescription.sets};

  Drill withSets(Drill d, int sets) => d.copyWith(defaultPrescription: d.defaultPrescription.copyWith(sets: sets));

  final byPriority = [...working.indexed]..sort((a, b) => (score[b.$2.id] ?? 0).compareTo(score[a.$2.id] ?? 0));
  for (final (index, drill) in byPriority) {
    if (total() >= budget * 0.9) break;
    if (drill.defaultPrescription.sets < defaults[drill.id]! + 1 && drill.tags.contains(_recoveryTag) == false) working[index] = withSets(drill, drill.defaultPrescription.sets + 1);
  }
  for (final (index, drill) in byPriority.reversed) {
    if (total() <= budget * 1.1) break;
    if (drill.defaultPrescription.sets > 1 && drill.defaultPrescription.sets > defaults[drill.id]! - 1) working[index] = withSets(drill, drill.defaultPrescription.sets - 1);
  }
  return GeneratedRoutine(drills: List.unmodifiable(working), estimatedSeconds: total());
}
