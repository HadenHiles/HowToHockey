import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/coach/routine_generator.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'sample_data.dart';
import 'training_state.dart';
import 'workout_history.dart';

const maxSetupPresets = 5;
const maxPresetNameLength = 20;

/// A named setup, such as "Garage" or "Rink Tuesday": what you have, what you're working on, how long.
class SetupPreset {
  const SetupPreset({required this.id, required this.name, required this.setup, required this.focus, required this.minutes});

  final String id;
  final String name;
  final TrainingSetupState setup;
  final Map<SkillPillar, int> focus;
  final int minutes;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'setup': setupToJson(setup), 'focus': focusToJson(focus), 'minutes': minutes};

  static SetupPreset? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    final setup = json['setup'];
    final minutes = json['minutes'];
    if (id is! String || name is! String || setup is! Map<String, dynamic> || minutes is! int || !routineLengthOptions.contains(minutes)) return null;
    return SetupPreset(id: id, name: name, setup: setupFromJson(setup), focus: focusFromJson(json['focus']), minutes: minutes);
  }
}

/// Setups the player saved to come back to, kept on this device.
class SetupPresets extends Notifier<List<SetupPreset>> {
  static const storageKey = 'setupPresets';

  @override
  List<SetupPreset> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (stored == null) return const [];
    try {
      return List.unmodifiable([for (final entry in jsonDecode(stored) as List) ?SetupPreset.fromJson(entry)]);
    } on Object {
      return const [];
    }
  }

  /// Saves the current setup under [name]. A name that already exists is replaced.
  /// Returns a message for the player if it can't be saved.
  String? save(String name) {
    final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'Give this setup a name.';
    if (trimmed.length > maxPresetNameLength) return 'Keep the name to $maxPresetNameLength characters.';
    final existing = state.where((p) => p.name.toLowerCase() == trimmed.toLowerCase()).firstOrNull;
    if (existing == null && state.length >= maxSetupPresets) return 'You can keep up to $maxSetupPresets saved setups. Remove one first.';
    final preset = SetupPreset(
      id: existing?.id ?? 'preset-${clock.now().microsecondsSinceEpoch}',
      name: trimmed,
      setup: ref.read(trainingSetupProvider),
      focus: ref.read(trainingFocusProvider),
      minutes: ref.read(trainingLengthProvider),
    );
    _store([...state.where((p) => p.id != preset.id), preset]);
    return null;
  }

  void apply(SetupPreset preset) {
    ref.read(trainingSetupProvider.notifier).apply(preset.setup);
    ref.read(trainingFocusProvider.notifier).apply(preset.focus);
    ref.read(trainingLengthProvider.notifier).select(preset.minutes);
  }

  void remove(String id) => _store(state.where((p) => p.id != id).toList());

  void _store(List<SetupPreset> next) {
    state = List.unmodifiable(next);
    unawaited(ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode([for (final p in next) p.toJson()])));
  }
}

final setupPresetsProvider = NotifierProvider<SetupPresets, List<SetupPreset>>(SetupPresets.new);

/// "Try another": how many times it was pressed and which drills were just skipped.
typedef RoutineShuffleState = ({int count, Set<String> avoid});

class RoutineShuffle extends Notifier<RoutineShuffleState> {
  @override
  RoutineShuffleState build() => (count: 0, avoid: const {});

  void next(Iterable<String> skipped) => state = (count: state.count + 1, avoid: Set.unmodifiable(skipped));
}

final routineShuffleProvider = NotifierProvider<RoutineShuffle, RoutineShuffleState>(RoutineShuffle.new);

/// Today's workout: built from the catalog, the setup, the focus and the length, and steered away from
/// what was done in the last few workouts. It stays the same all day unless the player asks for another.
final generatedRoutineProvider = Provider<AsyncValue<GeneratedRoutine>>((ref) {
  final catalog = ref.watch(drillCatalogProvider);
  final setup = ref.watch(trainingSetupProvider);
  final focus = ref.watch(trainingFocusProvider);
  final minutes = ref.watch(trainingLengthProvider);
  final pro = ref.watch(drillFiltersUnlockedProvider);
  final recent = [
    for (final workout in ref.watch(workoutHistoryProvider).take(3))
      [
        for (final (index, drill) in workout.drills.indexed)
          if (workout.setsLogged(index) > 0) drill.id,
      ],
  ];
  final day = clock.now();
  final shuffle = ref.watch(routineShuffleProvider);
  final shuffles = shuffle.count;
  final seed = day.year * 1000 + day.difference(DateTime(day.year)).inDays + shuffles * 100003;
  return catalog.whenData(
    (drills) => generateRoutine(
      GeneratorInput(
        catalog: drills,
        location: setup.location,
        inventory: setup.inventory,
        ball: setup.ball,
        passer: setup.passer,
        focus: focus,
        minutes: minutes,
        pro: pro,
        recentSessions: recent,
        seed: seed,
      ),
    ),
  );
});

/// The skill getting the most focus points; ties go to the earlier skill.
SkillPillar topPillar(Map<SkillPillar, int> focus) => SkillPillar.values.reduce((best, next) => (focus[next] ?? 0) > (focus[best] ?? 0) ? next : best);

String routineTitle(Map<SkillPillar, int> focus) {
  final values = focus.values.toList()..sort();
  final balanced = values.isNotEmpty && values.last - values.first <= 15;
  return balanced ? 'A balanced\nworkout' : '${topPillar(focus).label}\nfocus';
}

String routineDetail(Map<SkillPillar, int> focus) {
  final ranked = SkillPillar.values.where((p) => (focus[p] ?? 0) > 0).toList()..sort((a, b) => (focus[b] ?? 0).compareTo(focus[a] ?? 0));
  if (ranked.isEmpty) return 'Your workout, built from what you have.';
  final names = ranked.take(2).map((p) => p.label.toLowerCase()).toList();
  return 'Built around ${names.join(' and ')}.';
}
