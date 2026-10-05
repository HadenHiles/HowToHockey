import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/models/drill.dart';
import 'sample_data.dart';
import '../features/settings/appearance_settings_controller.dart';

typedef DrillRestSettings = ({bool enabled, int seconds});

class DrillRestSettingsNotifier extends Notifier<Map<String, DrillRestSettings>> {
  @override
  Map<String, DrillRestSettings> build() {
    final preferences = ref.read(sharedPreferencesProvider);
    final result = <String, DrillRestSettings>{};
    for (final key in preferences.getKeys().where((key) => key.startsWith('drillRest.'))) {
      final id = key.substring('drillRest.'.length);
      final parts = preferences.getString(key)!.split(':');
      final seconds = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (seconds == null || seconds < 15 || seconds > 600 || !['on', 'off'].contains(parts[0])) {
        throw FormatException('Invalid rest settings for $id.');
      }
      result[id] = (enabled: parts[0] == 'on', seconds: seconds);
    }
    return Map.unmodifiable(result);
  }

  Future<void> configure(String id, DrillRestSettings settings) async {
    if (settings.seconds < 15 || settings.seconds > 600) throw RangeError.range(settings.seconds, 15, 600);
    final preferences = ref.read(sharedPreferencesProvider);
    if (!await preferences.setString('drillRest.$id', '${settings.enabled ? 'on' : 'off'}:${settings.seconds}')) {
      throw StateError('Could not save drill rest settings.');
    }
    state = Map.unmodifiable({...state, id: settings});
  }
}

final drillRestSettingsProvider = NotifierProvider<DrillRestSettingsNotifier, Map<String, DrillRestSettings>>(DrillRestSettingsNotifier.new);

// Back these providers with persistence when the session-engine milestone resumes.
typedef TrainingSetupState = ({LocationOption location, PuckInventory inventory, BallType? ball, PasserType? passer});

class TrainingSetup extends Notifier<TrainingSetupState> {
  @override
  TrainingSetupState build() => (location: LocationOption.drivewayGarage, inventory: PuckInventory.low, ball: null, passer: PasserType.partner);

  void selectLocation(LocationOption location) => state = (location: location, inventory: state.inventory, ball: state.ball, passer: state.passer);

  void selectInventory(PuckInventory inventory) => state = (location: state.location, inventory: inventory, ball: state.ball, passer: state.passer);

  void selectBall(BallType? ball) => state = (location: state.location, inventory: state.inventory, ball: ball, passer: state.passer);

  void selectPasser(PasserType? passer) => state = (location: state.location, inventory: state.inventory, ball: state.ball, passer: passer);
}

final trainingSetupProvider = NotifierProvider<TrainingSetup, TrainingSetupState>(TrainingSetup.new);

class TrainingFocus extends Notifier<Map<SkillPillar, int>> {
  @override
  Map<SkillPillar, int> build() => const {SkillPillar.shotAccuracy: 25, SkillPillar.hands: 20, SkillPillar.shotPower: 20, SkillPillar.passing: 15, SkillPillar.speedStrength: 10, SkillPillar.endurance: 10};

  void select(SkillPillar pillar, int value) {
    if (value < 0 || value > 100) {
      throw RangeError.range(value, 0, 100, 'focus');
    }
    final others = SkillPillar.values.where((item) => item != pillar).toList();
    final remaining = 100 - value;
    final total = others.fold(0, (sum, item) => sum + state[item]!);
    final shares = {for (final item in others) item: remaining * (total == 0 ? 1 / others.length : state[item]! / total)};
    final next = {pillar: value, for (final item in others) item: shares[item]!.floor()};
    final remainder = 100 - next.values.fold(0, (sum, share) => sum + share);
    others.sort((a, b) {
      final comparison = (shares[b]! - shares[b]!.floor()).compareTo(shares[a]! - shares[a]!.floor());
      return comparison == 0 ? a.index.compareTo(b.index) : comparison;
    });
    for (var index = 0; index < remainder; index++) {
      next[others[index]] = next[others[index]]! + 1;
    }
    state = Map.unmodifiable(next);
  }
}

final trainingFocusProvider = NotifierProvider<TrainingFocus, Map<SkillPillar, int>>(TrainingFocus.new);

class TrainingSession {
  const TrainingSession({required this.drills, this.drillIndex = 0, this.setIndex = 0, this.logs = const [], this.startedAt, this.restEndsAt, this.endedAt});

  final List<Drill> drills;
  final int drillIndex;
  final int setIndex;
  final List<({String drillId, SetLog log})> logs;
  final DateTime? startedAt;
  final DateTime? restEndsAt;
  final DateTime? endedAt;
  int get elapsedSeconds => startedAt == null ? 0 : (endedAt ?? DateTime.now().toUtc()).difference(startedAt!).inSeconds;

  int setsLogged(int index) => logs.where((entry) => entry.drillId == drills[index].id).length;
  bool get finished => drills.asMap().entries.every((entry) => setsLogged(entry.key) >= entry.value.defaultPrescription.sets);
  Drill get drill => drills[drillIndex];
  bool get hasEstimatedTime => logs.any((entry) => entry.log.seconds == null);
  int get activeSeconds => logs.fold(0, (sum, entry) => sum + (entry.log.seconds ?? drills.firstWhere((drill) => drill.id == entry.drillId).estimatedSecondsPerSet));

  TrainingSession copyWith({int? drillIndex, List<({String drillId, SetLog log})>? logs, DateTime? restEndsAt, DateTime? endedAt, bool clearRest = false}) =>
      TrainingSession(drills: drills, drillIndex: drillIndex ?? this.drillIndex, logs: logs ?? this.logs, startedAt: startedAt, endedAt: endedAt ?? this.endedAt, restEndsAt: clearRest ? null : restEndsAt ?? this.restEndsAt, setIndex: (logs ?? this.logs).where((entry) => entry.drillId == drills[drillIndex ?? this.drillIndex].id).length);
}

class TrainingSessionNotifier extends Notifier<TrainingSession> {
  @override
  TrainingSession build() => TrainingSession(drills: sampleDrills);

  void start(List<Drill> drills) {
    if (drills.isEmpty) throw ArgumentError('A session needs at least one drill.');
    if (drills.map((drill) => drill.id).toSet().length != drills.length) throw ArgumentError('Session drills must have unique IDs.');
    state = TrainingSession(drills: List.unmodifiable(drills), startedAt: DateTime.now().toUtc());
  }

  void selectDrill(int index) {
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    state = state.copyWith(drillIndex: index);
  }

  void skipRest() => state = state.copyWith(clearRest: true);

  void adjustRest(int seconds) {
    final now = DateTime.now().toUtc();
    final deadline = state.restEndsAt;
    if (deadline == null) throw StateError('There is no rest countdown to adjust.');
    final adjusted = (deadline.isBefore(now) ? now : deadline).add(Duration(seconds: seconds));
    final maximum = now.add(const Duration(minutes: 10));
    state = state.copyWith(
      restEndsAt: adjusted.isBefore(now)
          ? now
          : adjusted.isAfter(maximum)
          ? maximum
          : adjusted,
    );
  }

  void logSet({int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
    if (state.finished) throw StateError('This session is already complete.');
    final drill = state.drill;
    if (state.setsLogged(state.drillIndex) >= drill.defaultPrescription.sets) throw StateError('All sets for this drill are logged.');
    final log = SetLog(setIndex: state.setIndex, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: DateTime.now().toUtc());
    final settings = ref.read(drillRestSettingsProvider)[drill.id];
    state = state.copyWith(
      logs: List.unmodifiable([...state.logs, (drillId: drill.id, log: log)]),
      restEndsAt: settings?.enabled == true ? DateTime.now().toUtc().add(Duration(seconds: settings!.seconds)) : null,
      clearRest: settings?.enabled != true,
    );
    if (state.finished) state = state.copyWith(clearRest: true, endedAt: DateTime.now().toUtc());
  }
}

final trainingSessionProvider = NotifierProvider<TrainingSessionNotifier, TrainingSession>(TrainingSessionNotifier.new);

class WorkoutSheetProgress extends Notifier<double> {
  @override
  double build() => 0;

  void update(double progress) => state = progress.clamp(0, 1).toDouble();
}

final workoutSheetProgressProvider = NotifierProvider<WorkoutSheetProgress, double>(WorkoutSheetProgress.new);
