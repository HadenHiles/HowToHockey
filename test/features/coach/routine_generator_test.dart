import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/coach/routine_generator.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';

final catalog = parseDrillCatalog(File(drillCatalogAsset).readAsStringSync());

const balanced = {SkillPillar.shotAccuracy: 25, SkillPillar.hands: 20, SkillPillar.shotPower: 20, SkillPillar.passing: 15, SkillPillar.speedStrength: 10, SkillPillar.endurance: 10};

Map<SkillPillar, int> only(SkillPillar pillar) => {for (final p in SkillPillar.values) p: p == pillar ? 100 : 0};

GeneratorInput input({
  LocationOption location = LocationOption.drivewayGarage,
  PuckInventory inventory = PuckInventory.low,
  BallType? ball,
  PasserType? passer,
  Map<SkillPillar, int> focus = balanced,
  int minutes = 20,
  bool pro = false,
  List<List<String>> recent = const [],
  int seed = 0,
}) => GeneratorInput(catalog: catalog, location: location, inventory: inventory, ball: ball, passer: passer, focus: focus, minutes: minutes, pro: pro, recentSessions: recent, seed: seed);

List<String> ids(GeneratedRoutine routine) => [for (final drill in routine.drills) drill.id];

void main() {
  group('largestRemainder', () {
    test('always adds up to the total and follows the weights', () {
      expect(largestRemainder([25, 20, 20, 15, 10, 10], 6), [1, 1, 1, 1, 1, 1]);
      expect(largestRemainder([1, 1, 1], 4), [2, 1, 1]);
      for (final total in [0, 1, 3, 7, 8]) {
        for (final weights in [
          [25, 20, 20, 15, 10, 10],
          [100, 0, 0],
          [3, 3, 3, 3],
        ]) {
          expect(largestRemainder(weights, total).fold(0, (a, b) => a + b), weights.every((w) => w == 0) ? 0 : total);
        }
      }
      expect(largestRemainder([0, 0], 5), [0, 0]);
    });
  });

  group('hard filters', () {
    test('only drills that fit the location, pucks and passer are used', () {
      for (final location in LocationOption.values) {
        for (final inventory in PuckInventory.values) {
          for (final passer in [null, PasserType.partner, PasserType.rebounder]) {
            for (final ball in [null, BallType.trainingBall]) {
              final routine = generateRoutine(input(location: location, inventory: inventory, passer: passer, ball: ball, minutes: 30));
              for (final drill in routine.drills) {
                expect(drill.allowedLocations, contains(location), reason: drill.id);
                expect(drill.minPuckInventory.index <= inventory.index || (ball != null && drill.supportedBalls.contains(ball)), isTrue, reason: drill.id);
                if (drill.requiresPasser) expect(drill.passerTypes, contains(passer), reason: drill.id);
              }
            }
          }
        }
      }
    });

    test('a low puck count rules out medium and high drills, a supported ball brings them back', () {
      final medium = catalog.firstWhere((d) => d.minPuckInventory == PuckInventory.medium && !d.requiresPasser);
      final location = medium.allowedLocations.first;
      expect(eligibleDrills(input(location: location)).map((d) => d.id), isNot(contains(medium.id)));
      final ball = medium.supportedBalls.first;
      expect(eligibleDrills(input(location: location, ball: ball)).map((d) => d.id), contains(medium.id));
    });

    test('passer drills need a passer of a matching type', () {
      expect(eligibleDrills(input()).any((d) => d.requiresPasser), isFalse);
      expect(eligibleDrills(input(passer: PasserType.partner)).any((d) => d.requiresPasser), isTrue);
    });

    test('pro drills are only used by pro players', () {
      final pro = [for (final d in catalog) d.copyWith(tier: AccessTier.pro)];
      GeneratorInput withTier(bool isPro) => GeneratorInput(catalog: pro, location: LocationOption.drivewayGarage, inventory: PuckInventory.high, focus: balanced, minutes: 20, pro: isPro);
      expect(generateRoutine(withTier(false)).drills, isEmpty);
      expect(generateRoutine(withTier(true)).drills, isNotEmpty);
    });

    test('returns an empty routine when nothing fits', () {
      final routine = generateRoutine(input(location: LocationOption.ice, inventory: PuckInventory.low).copyWithCatalog([]));
      expect(routine.drills, isEmpty);
      expect(routine.estimatedSeconds, 0);
    });
  });

  group('focus', () {
    test('a single-skill focus makes that skill the biggest part of the workout', () {
      for (final pillar in [SkillPillar.shotAccuracy, SkillPillar.hands, SkillPillar.shotPower, SkillPillar.passing]) {
        final routine = generateRoutine(input(focus: only(pillar), passer: PasserType.partner, inventory: PuckInventory.medium, minutes: 30));
        final matching = routine.drills.where((d) => dominantPillar(d) == pillar).length;
        expect(matching, greaterThanOrEqualTo(2), reason: '$pillar -> ${ids(routine)}');
        expect(routine.drills.first.id.isNotEmpty, isTrue);
      }
    });

    test('a skill with no focus points is only trained through drills that also train a skill you chose', () {
      final focus = {...balanced, SkillPillar.passing: 0, SkillPillar.hands: 35};
      final routine = generateRoutine(input(focus: focus, passer: PasserType.partner, minutes: 30));
      for (final drill in routine.drills.where((d) => !d.tags.contains('recovery'))) {
        expect(focusScore(drill, focus), greaterThan(0), reason: drill.id);
      }
      expect(routine.drills.where((d) => dominantPillar(d) == SkillPillar.passing && d.skillWeights[SkillPillar.passing]! >= 1), isEmpty);
    });
  });

  group('routine shape', () {
    test('lands near the target time for every length', () {
      for (final minutes in routineLengthOptions) {
        for (final inventory in PuckInventory.values) {
          final routine = generateRoutine(input(minutes: minutes, inventory: inventory, passer: PasserType.partner));
          final target = minutes * 60;
          expect(routine.estimatedSeconds, inInclusiveRange(target * 0.6, target * 1.3), reason: '$minutes min, $inventory: ${routine.estimatedMinutes} min ${ids(routine)}');
          expect(routine.drills.length, inInclusiveRange(3, 9));
        }
      }
    });

    test('longer sessions have more drills, and never repeat a drill or use more than two from one swap group', () {
      final short = generateRoutine(input(minutes: 15, inventory: PuckInventory.medium));
      final long = generateRoutine(input(minutes: 45, inventory: PuckInventory.medium));
      expect(long.drills.length, greaterThan(short.drills.length));
      for (final routine in [short, long]) {
        expect(ids(routine).toSet().length, routine.drills.length);
        final groups = [for (final d in routine.drills) ?d.swapGroup];
        for (final group in groups.toSet()) {
          expect(groups.where((g) => g == group).length, lessThanOrEqualTo(2), reason: group);
        }
      }
    });

    test('warm-up first, recovery last, finishers late', () {
      final routine = generateRoutine(input(minutes: 45, inventory: PuckInventory.high, passer: PasserType.partner));
      expect(routine.drills.last.tags, contains('recovery'));
      final warmUp = routine.drills.indexWhere((d) => d.tags.contains('warm-up'));
      if (warmUp >= 0) expect(warmUp, 0);
      final firstFinisher = routine.drills.indexWhere((d) => d.trackingType == TrackingType.density || d.trackingType == TrackingType.streak);
      final lastShooting = routine.drills.lastIndexWhere((d) => dominantPillar(d) == SkillPillar.shotAccuracy || dominantPillar(d) == SkillPillar.shotPower);
      if (firstFinisher >= 0 && lastShooting >= 0) expect(firstFinisher, greaterThan(lastShooting));
    });

    test('mixes how drills are tracked', () {
      final routine = generateRoutine(input(minutes: 30, inventory: PuckInventory.medium));
      expect({for (final d in routine.drills) d.trackingType}.length, greaterThanOrEqualTo(3));
    });

    test('a low puck count adds pick-up time that a high count does not', () {
      final shooting = catalog.firstWhere((d) => d.trackingType == TrackingType.accuracy);
      expect(drillSeconds(shooting, PuckInventory.low), greaterThan(drillSeconds(shooting, PuckInventory.high)));
      final timed = catalog.firstWhere((d) => d.trackingType == TrackingType.duration);
      expect(drillSeconds(timed, PuckInventory.low), drillSeconds(timed, PuckInventory.high));
    });

    test('sets stay within one of the drill default', () {
      final defaults = {for (final d in catalog) d.id: d.defaultPrescription.sets};
      for (final minutes in routineLengthOptions) {
        for (final drill in generateRoutine(input(minutes: minutes)).drills) {
          expect((drill.defaultPrescription.sets - defaults[drill.id]!).abs(), lessThanOrEqualTo(1), reason: drill.id);
          expect(drill.defaultPrescription.sets, greaterThanOrEqualTo(1));
        }
      }
    });
  });

  group('variety and repeatability', () {
    test('the same input gives the same routine, in any order of the catalog', () {
      final a = generateRoutine(input(seed: 7));
      final b = generateRoutine(input(seed: 7));
      expect(ids(a), ids(b));
      final shuffled = GeneratorInput(catalog: catalog.reversed.toList(), location: LocationOption.drivewayGarage, inventory: PuckInventory.low, focus: balanced, minutes: 20, seed: 7);
      expect(ids(generateRoutine(shuffled)), ids(a));
    });

    test('different seeds can give different workouts', () {
      final variants = {for (var seed = 0; seed < 25; seed++) ids(generateRoutine(input(seed: seed, minutes: 30, inventory: PuckInventory.medium))).join(',')};
      expect(variants.length, greaterThan(1));
    });

    test('drills done in recent workouts are less likely to come back', () {
      final first = generateRoutine(input(minutes: 20));
      final recent = [ids(first)];
      final next = generateRoutine(input(minutes: 20, recent: recent));
      final repeated = ids(next).where(ids(first).contains).length;
      expect(repeated, lessThan(first.drills.length), reason: 'at least one drill is swapped out');
    });
  });

  group('known setups', () {
    test('garage, one puck, balanced, 20 minutes', () {
      expect(ids(generateRoutine(input())), _golden['garage-low-20']);
    });
    test('driveway, many pucks, a partner, shooting focus, 30 minutes', () {
      final focus = {SkillPillar.shotAccuracy: 40, SkillPillar.shotPower: 40, SkillPillar.hands: 10, SkillPillar.passing: 10, SkillPillar.speedStrength: 0, SkillPillar.endurance: 0};
      final r = generateRoutine(input(inventory: PuckInventory.high, passer: PasserType.partner, focus: focus, minutes: 30));
      expect(ids(r), _golden['driveway-high-shooting-30']);
    });
    test('basement, one puck, hands and conditioning, 15 minutes', () {
      final focus = {SkillPillar.shotAccuracy: 0, SkillPillar.shotPower: 0, SkillPillar.hands: 60, SkillPillar.passing: 0, SkillPillar.speedStrength: 20, SkillPillar.endurance: 20};
      final r = generateRoutine(input(location: LocationOption.basement, focus: focus, minutes: 15));
      expect(ids(r), _golden['basement-low-hands-15']);
    });
  });
}

extension on GeneratorInput {
  GeneratorInput copyWithCatalog(List<Drill> drills) => GeneratorInput(catalog: drills, location: location, inventory: inventory, focus: focus, minutes: minutes);
}

const _golden = <String, List<String>>{
  'garage-low-20': ['athletic-stance-reset', 'pick-your-corner', 'bottom-shelf-snaps', 'quick-release-wrist-shots', 'figure-eight-stickhandling', 'target-saucer-passes'],
  'driveway-high-shooting-30': [
    'pick-your-corner',
    'shoot-the-tarp',
    'quick-release-wrist-shots',
    'slap-shot-loads',
    'one-timer-reps',
    'figure-eight-stickhandling',
    'shot-burst-30',
    'pass-and-settle',
    'mobility-cooldown',
  ],
  'basement-low-hands-15': ['quiet-hands-quick-feet', 'athletic-stance-reset', 'figure-eight-stickhandling', 'toe-drag-reps', 'ball-bounce-streak'],
};
