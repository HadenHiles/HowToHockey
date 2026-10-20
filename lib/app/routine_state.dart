import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/drill_catalog.dart';
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

  static const freeRoutineLimit = 3;

  bool get atLimit => !ref.read(drillFiltersUnlockedProvider) && state.length >= freeRoutineLimit;

  Future<void> save(RoutinePlan routine) async {
    if (routine.drills.isEmpty) throw ArgumentError('A routine must contain at least one drill.');
    if (atLimit && !state.any((item) => item.id == routine.id)) {
      throw StateError('You can keep up to $freeRoutineLimit saved routines. Delete one to save another.');
    }
    final next = [...state.where((item) => item.id != routine.id), routine];
    await _persist(next);
    state = List.unmodifiable(next);
  }

  /// Swaps a saved routine for a new one when the free limit is reached.
  Future<void> replace(String oldId, RoutinePlan routine) async {
    if (routine.drills.isEmpty) throw ArgumentError('A routine must contain at least one drill.');
    final next = [...state.where((item) => item.id != oldId && item.id != routine.id), routine];
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
    if (!saved) throw StateError('Couldn\'t save routines on this device.');
  }
}

final routineLibraryProvider = NotifierProvider<RoutineLibrary, List<RoutinePlan>>(RoutineLibrary.new);

/// How a template drill can be measured. Players choose from these; nothing here is typed in.
const templateTrackingTypes = [TrackingType.volume, TrackingType.accuracy, TrackingType.duration, TrackingType.streak, TrackingType.binary];

String _templateBaseTitle(SkillPillar pillar) => switch (pillar) {
  SkillPillar.shotAccuracy => 'Custom target accuracy',
  SkillPillar.hands => 'Custom puck control',
  SkillPillar.shotPower => 'Custom shot power',
  SkillPillar.passing => 'Custom passing reps',
  SkillPillar.speedStrength => 'Custom speed and strength',
  SkillPillar.endurance => 'Custom conditioning circuit',
};

/// Builds a drill from a skill and a way of measuring it. [existingTitles] keeps names distinct, so
/// two of the same kind read as "… 2", never as the same drill.
Drill createTemplateDrill(
  SkillPillar pillar, {
  required int sets,
  int reps = 10,
  int seconds = 30,
  int restSeconds = 45,
  TrackingType trackingType = TrackingType.volume,
  Iterable<String> existingTitles = const [],
}) {
  if (!templateTrackingTypes.contains(trackingType)) throw ArgumentError.value(trackingType, 'trackingType', 'Not offered for template drills.');
  final taken = existingTitles.toSet();
  final base = _templateBaseTitle(pillar);
  var title = base;
  for (var number = 2; taken.contains(title); number++) {
    title = '$base $number';
  }
  final timed = trackingType == TrackingType.duration;
  final counted = trackingType == TrackingType.volume || trackingType == TrackingType.accuracy;
  return Drill(
    id: 'custom-${pillar.name}-${DateTime.now().microsecondsSinceEpoch}',
    title: title,
    mediaAssetPath: 'placeholder/custom-${pillar.name}',
    formCues: const ['Pick a clear target before each rep.', 'Stay in control and repeat the same motion.'],
    trackingType: trackingType,
    allowedLocations: LocationOption.values,
    minPuckInventory: PuckInventory.low,
    requiresPasser: pillar == SkillPillar.passing,
    skillWeights: {pillar: 1},
    tier: AccessTier.free,
    supportedBalls: BallType.values,
    passerTypes: pillar == SkillPillar.passing ? PasserType.values : const [],
    defaultPrescription: DrillPrescription(sets: sets, reps: counted ? reps : null, seconds: timed ? seconds : null, restSeconds: restSeconds),
    estimatedSecondsPerSet: timed ? seconds : (counted ? reps * 5 : 30),
    difficulty: 2,
    tags: const ['Custom template'],
  );
}

/// Template drills the player has made, kept so they can be picked again for any workout or routine.
class CustomDrillLibrary extends Notifier<List<Drill>> {
  static const _storageKey = 'customDrills';
  static const maxDrills = 30;

  @override
  List<Drill> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (stored == null) return const [];
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) throw const FormatException('Saved drills must be a list.');
      return List.unmodifiable([for (final drill in decoded) Drill.fromJson(drill as Map<String, dynamic>)]);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'my drills', context: ErrorDescription('while reading saved drills')));
      return const [];
    }
  }

  Future<void> add(Drill drill) async {
    if (state.any((item) => item.id == drill.id)) return;
    if (state.length >= maxDrills) throw StateError('You can keep up to $maxDrills of your own drills. Delete one to make another.');
    final next = [drill, ...state];
    await _persist(next);
    state = List.unmodifiable(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((drill) => drill.id != id).toList();
    await _persist(next);
    state = List.unmodifiable(next);
  }

  Future<void> _persist(List<Drill> drills) async {
    final saved = await ref.read(sharedPreferencesProvider).setString(_storageKey, jsonEncode(drills.map((drill) => drill.toJson()).toList()));
    if (!saved) throw StateError('Couldn\'t save your drills on this device.');
  }
}

final customDrillLibraryProvider = NotifierProvider<CustomDrillLibrary, List<Drill>>(CustomDrillLibrary.new);
