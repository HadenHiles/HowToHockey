import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/auth_service.dart';
import '../features/drills/models/drill.dart';
import '../features/drills/set_calculations.dart';
import 'sample_data.dart';
import 'workout_history.dart';
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
      throw StateError('Couldn\'t save drill settings.');
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
  Map<SkillPillar, int> build() => const {
    SkillPillar.shotAccuracy: 25,
    SkillPillar.hands: 20,
    SkillPillar.shotPower: 20,
    SkillPillar.passing: 15,
    SkillPillar.speedStrength: 10,
    SkillPillar.endurance: 10,
  };

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
  const TrainingSession({required this.drills, this.drillIndex = 0, this.setIndex = 0, this.logs = const [], this.startedAt, this.restEndsAt, this.endedAt, this.dismissed = false});

  final List<Drill> drills;
  final int drillIndex;
  final int setIndex;
  final List<({String drillId, SetLog log})> logs;
  final DateTime? startedAt;
  final DateTime? restEndsAt;
  final DateTime? endedAt;
  final bool dismissed;
  int get elapsedSeconds => startedAt == null ? 0 : (endedAt ?? clock.now().toUtc()).difference(startedAt!).inSeconds;

  int setsLogged(int index) => logs.where((entry) => entry.drillId == drills[index].id).length;
  bool get finished => drills.asMap().entries.every((entry) => setsLogged(entry.key) >= entry.value.defaultPrescription.sets);
  Drill get drill => drills[drillIndex];
  bool get hasEstimatedTime => logs.any((entry) => entry.log.seconds == null);
  int get activeSeconds => logs.fold(0, (sum, entry) => sum + activeSecondsForSet(entry.log, drills.firstWhere((drill) => drill.id == entry.drillId)));

  Map<String, Object?> toJson() => {
    'drills': drills.map((drill) => drill.toJson()).toList(),
    'drillIndex': drillIndex,
    'startedAt': startedAt?.toIso8601String(),
    'restEndsAt': restEndsAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'dismissed': dismissed,
    'logs': [
      for (final entry in logs)
        {
          'drillId': entry.drillId,
          'setIndex': entry.log.setIndex,
          'reps': entry.log.reps,
          'hits': entry.log.hits,
          'seconds': entry.log.seconds,
          'streak': entry.log.streak,
          'completed': entry.log.completed,
          'loggedAt': entry.log.loggedAt.toIso8601String(),
        },
    ],
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final drills = [for (final drill in json['drills'] as List) Drill.fromJson(drill as Map<String, dynamic>)];
    if (drills.isEmpty) throw const FormatException('A saved session needs at least one drill.');
    final drillIndex = json['drillIndex'] as int;
    if (drillIndex < 0 || drillIndex >= drills.length) throw const FormatException('Saved drill position is out of range.');
    DateTime? time(String key) => json[key] == null ? null : DateTime.parse(json[key] as String).toUtc();
    final logs = [
      for (final entry in json['logs'] as List)
        (
          drillId: (entry as Map<String, dynamic>)['drillId'] as String,
          log: SetLog(
            setIndex: entry['setIndex'] as int,
            reps: entry['reps'] as int?,
            hits: entry['hits'] as int?,
            seconds: entry['seconds'] as int?,
            streak: entry['streak'] as int?,
            completed: entry['completed'] as bool?,
            loggedAt: DateTime.parse(entry['loggedAt'] as String).toUtc(),
          ),
        ),
    ];
    final ids = drills.map((drill) => drill.id).toSet();
    if (logs.any((entry) => !ids.contains(entry.drillId))) throw const FormatException('A saved set belongs to a drill that is not in the session.');
    return TrainingSession(
      drills: List.unmodifiable(drills),
      drillIndex: drillIndex,
      setIndex: logs.where((entry) => entry.drillId == drills[drillIndex].id).length,
      logs: List.unmodifiable(logs),
      startedAt: time('startedAt'),
      restEndsAt: time('restEndsAt'),
      endedAt: time('endedAt'),
      dismissed: json['dismissed'] as bool,
    );
  }

  TrainingSession copyWith({int? drillIndex, List<({String drillId, SetLog log})>? logs, DateTime? restEndsAt, DateTime? endedAt, bool clearRest = false, bool? dismissed}) => TrainingSession(
    drills: drills,
    drillIndex: drillIndex ?? this.drillIndex,
    logs: logs ?? this.logs,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    restEndsAt: clearRest ? null : restEndsAt ?? this.restEndsAt,
    setIndex: (logs ?? this.logs).where((entry) => entry.drillId == drills[drillIndex ?? this.drillIndex].id).length,
    dismissed: dismissed ?? this.dismissed,
  );
}

class TrainingSessionNotifier extends Notifier<TrainingSession> {
  static const storageKey = 'activeTrainingSession';

  @override
  TrainingSession build() {
    // A workout belongs to whoever started it: signing out, switching accounts or pairing a kid's
    // device must not hand it to the next person.
    ref.listen(authStateProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (before == null || after == null) return;
      if (identityOf(before) == identityOf(after)) return;
      // A guest who signs in to an existing account keeps the workout they were doing.
      if (before is GuestSession && after is SignedInAccount) return;
      state = TrainingSession(drills: sampleDrills);
      unawaited(ref.read(sharedPreferencesProvider).remove(storageKey));
    });
    return _restore() ?? TrainingSession(drills: sampleDrills);
  }

  /// Brings back a session that was in progress when the app was closed or killed.
  TrainingSession? _restore() {
    final preferences = ref.read(sharedPreferencesProvider);
    final stored = preferences.getString(storageKey);
    if (stored == null) return null;
    try {
      final session = TrainingSession.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      return session.startedAt == null || session.dismissed ? null : session;
    } on Object catch (error, stackTrace) {
      // Corrupt or outdated data must not block the app; start fresh and report it.
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'training session', context: ErrorDescription('while restoring a saved workout')));
      unawaited(preferences.remove(storageKey));
      return null;
    }
  }

  /// Every change goes through here so progress is saved after each set, rest, and drill change.
  void _update(TrainingSession next) {
    state = next;
    final preferences = ref.read(sharedPreferencesProvider);
    final Future<bool> write = next.dismissed ? preferences.remove(storageKey) : preferences.setString(storageKey, jsonEncode(next.toJson()));
    unawaited(
      write.then((saved) {
        if (!saved) FlutterError.reportError(FlutterErrorDetails(exception: StateError('Couldn\'t save workout progress.'), library: 'training session'));
      }),
    );
  }

  void start(List<Drill> drills) {
    if (drills.isEmpty) throw ArgumentError('A session needs at least one drill.');
    if (drills.map((drill) => drill.id).toSet().length != drills.length) throw ArgumentError('Session drills must have unique IDs.');
    _update(TrainingSession(drills: List.unmodifiable(drills), startedAt: clock.now().toUtc()));
  }

  void selectDrill(int index) {
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    _update(state.copyWith(drillIndex: index));
  }

  void skipRest() => _update(state.copyWith(clearRest: true));

  /// Starts a rest by hand, for example between drills or when a drill has automatic rest off.
  void startRest(int seconds) {
    if (state.finished) throw StateError('This session is already complete.');
    if (seconds < 15 || seconds > 600) throw RangeError.range(seconds, 15, 600, 'seconds');
    _update(state.copyWith(restEndsAt: clock.now().toUtc().add(Duration(seconds: seconds))));
  }

  /// Replaces a drill that has no logged sets yet with another one.
  void swapDrill(int index, Drill replacement) {
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    if (state.setsLogged(index) > 0) throw StateError('Sets are already logged for this drill, so it can\'t be swapped.');
    if (state.drills.any((drill) => drill.id == replacement.id)) throw ArgumentError('That drill is already in this workout.');
    final drills = [...state.drills]..[index] = replacement;
    _update(
      TrainingSession(
        drills: List.unmodifiable(drills),
        drillIndex: state.drillIndex,
        setIndex: state.setIndex,
        logs: state.logs,
        startedAt: state.startedAt,
        restEndsAt: state.restEndsAt,
        endedAt: state.endedAt,
        dismissed: state.dismissed,
      ),
    );
  }

  void dismissFinishedWorkout() {
    if (!state.finished) throw StateError('Finish all sets before dismissing the workout.');
    final finished = state;
    _update(state.copyWith(dismissed: true));
    ref.read(workoutHistoryProvider.notifier).add(finished);
  }

  void adjustRest(int seconds) {
    final now = clock.now().toUtc();
    final deadline = state.restEndsAt;
    if (deadline == null) throw StateError('There is no rest countdown to adjust.');
    final adjusted = (deadline.isBefore(now) ? now : deadline).add(Duration(seconds: seconds));
    final maximum = now.add(const Duration(minutes: 10));
    _update(
      state.copyWith(
        restEndsAt: adjusted.isBefore(now)
            ? now
            : adjusted.isAfter(maximum)
            ? maximum
            : adjusted,
      ),
    );
  }

  void logSet({int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
    if (state.finished) throw StateError('This session is already complete.');
    final drill = state.drill;
    if (state.setsLogged(state.drillIndex) >= drill.defaultPrescription.sets) throw StateError('All sets for this drill are logged.');
    validateSetEntry(drill.trackingType, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed);
    final log = SetLog(setIndex: state.setIndex, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: clock.now().toUtc());
    final settings = ref.read(drillRestSettingsProvider)[drill.id];
    var next = state.copyWith(
      logs: List.unmodifiable([...state.logs, (drillId: drill.id, log: log)]),
      restEndsAt: settings?.enabled == true ? clock.now().toUtc().add(Duration(seconds: settings!.seconds)) : null,
      clearRest: settings?.enabled != true,
    );
    if (next.finished) next = next.copyWith(clearRest: true, endedAt: clock.now().toUtc());
    _update(next);
  }
}

final trainingSessionProvider = NotifierProvider<TrainingSessionNotifier, TrainingSession>(TrainingSessionNotifier.new);

class WorkoutSheetProgress extends Notifier<double> {
  @override
  double build() => 0;

  void update(double progress) => state = progress.clamp(0, 1).toDouble();
}

final workoutSheetProgressProvider = NotifierProvider<WorkoutSheetProgress, double>(WorkoutSheetProgress.new);
