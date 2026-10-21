import '../drills/models/drill.dart';

/// Something a player wants to get better at, in the words they use. Each one is a way of pointing the
/// workout at one of the six skills, so the skill radar and progress keep working unchanged.
class Outcome {
  const Outcome({required this.pillar, required this.label, required this.headline});

  final SkillPillar pillar;

  /// Short, for a button: "Harder shot".
  final String label;

  /// For a title: "Get a harder shot".
  final String headline;
}

/// In the order a player meets them: shooting first, then the rest.
const outcomes = [
  Outcome(pillar: SkillPillar.shotPower, label: 'Harder shot', headline: 'Get a\nharder shot'),
  Outcome(pillar: SkillPillar.shotAccuracy, label: 'Better accuracy', headline: 'Get more\naccurate'),
  Outcome(pillar: SkillPillar.hands, label: 'Quicker hands', headline: 'Get quicker\nhands'),
  Outcome(pillar: SkillPillar.speedStrength, label: 'Faster & more explosive', headline: 'Get faster and\nmore explosive'),
  Outcome(pillar: SkillPillar.passing, label: 'Sharper passing', headline: 'Get sharper\npassing'),
  Outcome(pillar: SkillPillar.endurance, label: 'More stamina', headline: 'Build\nstamina'),
];

/// How many of the 100 focus points an outcome puts on its skill; the rest are shared by the other five.
const outcomeFocusPoints = 55;

/// The 100-point focus for an outcome: its skill gets [outcomeFocusPoints], and the other skills keep their
/// proportions from [base] (the balanced default) in what is left.
Map<SkillPillar, int> focusForOutcome(SkillPillar pillar, Map<SkillPillar, int> base) {
  final others = SkillPillar.values.where((item) => item != pillar).toList();
  final remaining = 100 - outcomeFocusPoints;
  final total = others.fold(0, (sum, item) => sum + (base[item] ?? 0));
  final shares = {for (final item in others) item: remaining * (total == 0 ? 1 / others.length : (base[item] ?? 0) / total)};
  final result = {pillar: outcomeFocusPoints, for (final item in others) item: shares[item]!.floor()};
  final leftover = 100 - result.values.fold(0, (sum, value) => sum + value);
  others.sort((a, b) {
    final comparison = (shares[b]! - shares[b]!.floor()).compareTo(shares[a]! - shares[a]!.floor());
    return comparison == 0 ? a.index.compareTo(b.index) : comparison;
  });
  for (var index = 0; index < leftover; index++) {
    result[others[index]] = result[others[index]]! + 1;
  }
  return Map.unmodifiable(result);
}

/// The outcome a focus is pointed at, or null for a balanced or hand-tuned mix. Derived rather than stored,
/// so moving the focus sliders by hand can never leave a stale choice highlighted.
Outcome? outcomeFor(Map<SkillPillar, int> focus) {
  for (final outcome in outcomes) {
    if ((focus[outcome.pillar] ?? 0) >= outcomeFocusPoints) return outcome;
  }
  return null;
}
