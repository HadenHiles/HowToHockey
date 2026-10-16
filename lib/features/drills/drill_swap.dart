import 'models/drill.dart';

/// What the player has set up today, used to keep swaps realistic.
typedef SwapSetup = ({LocationOption location, PuckInventory inventory, BallType? ball, PasserType? passer});

/// Drills the player can swap [current] for: same swap group, nothing already in the workout,
/// and still doable with today's setup.
List<Drill> swapCandidates({required Drill current, required List<Drill> catalog, required Iterable<String> alreadyInWorkout, required SwapSetup setup}) {
  final group = current.swapGroup;
  if (group == null) return const [];
  final taken = alreadyInWorkout.toSet();
  return [
    for (final drill in catalog)
      if (drill.swapGroup == group && drill.id != current.id && !taken.contains(drill.id) && drill.fits(setup)) drill,
  ];
}

extension DrillSetupFit on Drill {
  /// Whether this drill can be done with the given setup.
  bool fits(SwapSetup setup) {
    if (!allowedLocations.contains(setup.location)) return false;
    if (minPuckInventory.index > setup.inventory.index) return false;
    // Drills that list no balls need none.
    if (setup.ball != null && supportedBalls.isNotEmpty && !supportedBalls.contains(setup.ball)) return false;
    if (requiresPasser && (setup.passer == null || !passerTypes.contains(setup.passer))) return false;
    return true;
  }
}
