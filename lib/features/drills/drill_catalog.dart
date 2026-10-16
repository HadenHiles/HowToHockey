import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/drill.dart';

/// The starter catalog ships inside the app so it can be browsed offline.
/// It is the same file the seed tool uploads, so there is a single source of truth.
const drillCatalogAsset = 'tool/seed/drills.json';

List<Drill> parseDrillCatalog(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1 || decoded['drills'] is! List) {
    throw const FormatException('The drill catalog is not in a supported format.');
  }
  return List.unmodifiable([for (final entry in decoded['drills'] as List) Drill.fromJson(entry as Map<String, dynamic>)]);
}

final drillCatalogProvider = FutureProvider<List<Drill>>((ref) async => parseDrillCatalog(await rootBundle.loadString(drillCatalogAsset)));

/// Local stand-in for the Player Pro entitlement until purchases are connected.
final drillFiltersUnlockedProvider = Provider<bool>((ref) => false);

class DrillFilters {
  const DrillFilters({this.location, this.puckInventory, this.ball, this.passer, this.pillar, this.trackingType});

  final LocationOption? location;
  final PuckInventory? puckInventory;
  final BallType? ball;
  final PasserType? passer;
  final SkillPillar? pillar;
  final TrackingType? trackingType;

  /// Filters other than the skill tabs, which are the Pro-only ones.
  bool get hasDetailedFilters => location != null || puckInventory != null || ball != null || passer != null || trackingType != null;

  DrillFilters copyWith({
    LocationOption? Function()? location,
    PuckInventory? Function()? puckInventory,
    BallType? Function()? ball,
    PasserType? Function()? passer,
    SkillPillar? Function()? pillar,
    TrackingType? Function()? trackingType,
  }) => DrillFilters(
    location: location != null ? location() : this.location,
    puckInventory: puckInventory != null ? puckInventory() : this.puckInventory,
    ball: ball != null ? ball() : this.ball,
    passer: passer != null ? passer() : this.passer,
    pillar: pillar != null ? pillar() : this.pillar,
    trackingType: trackingType != null ? trackingType() : this.trackingType,
  );

  bool matches(Drill drill) {
    if (pillar != null && primaryPillar(drill) != pillar) return false;
    if (trackingType != null && drill.trackingType != trackingType) return false;
    if (location != null && !drill.allowedLocations.contains(location)) return false;
    // A drill fits when its minimum puck count is no more than what the player has.
    if (puckInventory != null && drill.minPuckInventory.index > puckInventory!.index) return false;
    // Drills with no listed balls need no ball at all.
    if (ball != null && drill.supportedBalls.isNotEmpty && !drill.supportedBalls.contains(ball)) return false;
    // Drills that do not need a passer fit any passer choice.
    if (passer != null && drill.requiresPasser && !drill.passerTypes.contains(passer)) return false;
    return true;
  }
}

SkillPillar primaryPillar(Drill drill) => drill.skillWeights.entries.reduce((best, entry) => entry.value > best.value ? entry : best).key;

/// Free players see the free starter drills; Pro players see everything.
List<Drill> visibleDrills(List<Drill> catalog, {required bool pro}) => [
  for (final drill in catalog)
    if (pro || drill.tier == AccessTier.free) drill,
];

List<Drill> applyDrillFilters(List<Drill> drills, DrillFilters filters) => [
  for (final drill in drills)
    if (filters.matches(drill)) drill,
];
