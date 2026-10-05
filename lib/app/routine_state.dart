import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/models/drill.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'sample_data.dart';

class RoutinePlan {
  RoutinePlan({required this.id, required this.name, required List<Drill> drills}) : drills = List.unmodifiable(drills);

  final String id;
  final String name;
  final List<Drill> drills;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'drills': drills.map((drill) => drill.toJson()).toList()};

  factory RoutinePlan.fromJson(Map<String, dynamic> json) {
    final drills = json['drills'];
    if (json['id'] is! String || json['name'] is! String || drills is! List) {
      throw const FormatException('Saved routine data is invalid.');
    }
    return RoutinePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      drills: drills.map((drill) {
        if (drill is! Map<String, dynamic>) throw const FormatException('Saved routine drill data is invalid.');
        return Drill.fromJson(drill);
      }).toList(),
    );
  }
}

class RoutineLibrary extends Notifier<List<RoutinePlan>> {
  static const _storageKey = 'savedRoutines';

  @override
  List<RoutinePlan> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (stored == null) {
      return List.unmodifiable([RoutinePlan(id: 'foundation', name: 'Foundation Builder', drills: sampleDrills)]);
    }
    final decoded = jsonDecode(stored);
    if (decoded is! List) throw const FormatException('Saved routine library must be a list.');
    return List.unmodifiable(
      decoded.map((routine) {
        if (routine is! Map<String, dynamic>) throw const FormatException('Saved routine data is invalid.');
        return RoutinePlan.fromJson(routine);
      }),
    );
  }

  Future<void> save(RoutinePlan routine) async {
    if (routine.drills.isEmpty) throw ArgumentError('A routine must contain at least one drill.');
    final next = [...state.where((item) => item.id != routine.id), routine];
    await _persist(next);
    state = List.unmodifiable(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((routine) => routine.id != id).toList();
    await _persist(next);
    state = List.unmodifiable(next);
  }

  Future<void> _persist(List<RoutinePlan> routines) async {
    final preferences = ref.read(sharedPreferencesProvider);
    final saved = await preferences.setString(_storageKey, jsonEncode(routines.map((routine) => routine.toJson()).toList()));
    if (!saved) throw StateError('Could not save routines on this device.');
  }
}

final routineLibraryProvider = NotifierProvider<RoutineLibrary, List<RoutinePlan>>(RoutineLibrary.new);

Drill createTemplateDrill(SkillPillar pillar, {required int sets, required int reps}) => Drill(
  id: 'custom-${pillar.name}-${DateTime.now().microsecondsSinceEpoch}',
  title: switch (pillar) {
    SkillPillar.shotAccuracy => 'Custom target accuracy',
    SkillPillar.hands => 'Custom puck control',
    SkillPillar.shotPower => 'Custom shot power',
    SkillPillar.passing => 'Custom passing reps',
    SkillPillar.speedStrength => 'Custom speed and strength',
    SkillPillar.endurance => 'Custom conditioning circuit',
  },
  mediaAssetPath: 'placeholder/custom-${pillar.name}',
  formCues: const ['Set a clear target before each rep.', 'Keep your movement controlled and repeatable.'],
  trackingType: TrackingType.volume,
  allowedLocations: LocationOption.values,
  minPuckInventory: PuckInventory.low,
  requiresPasser: pillar == SkillPillar.passing,
  skillWeights: {pillar: 1},
  tier: AccessTier.free,
  supportedBalls: BallType.values,
  passerTypes: pillar == SkillPillar.passing ? PasserType.values : const [],
  defaultPrescription: DrillPrescription(sets: sets, reps: reps),
  estimatedSecondsPerSet: reps * 5,
  difficulty: 2,
  tags: const ['Custom template'],
);
