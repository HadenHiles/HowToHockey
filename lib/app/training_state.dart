import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/auth_service.dart';
import '../features/coach/routine_generator.dart';
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

typedef TrainingSetupState = ({LocationOption location, PuckInventory inventory, BallType? ball, PasserType? passer});

const defaultTrainingSetup = (location: LocationOption.drivewayGarage, inventory: PuckInventory.low, ball: null, passer: null);

const defaultTrainingFocus = {SkillPillar.shotAccuracy: 25, SkillPillar.hands: 20, SkillPillar.shotPower: 20, SkillPillar.passing: 15, SkillPillar.speedStrength: 10, SkillPillar.endurance: 10};

T? _byName<T extends Enum>(List<T> values, String? name) => values.where((value) => value.name == name).firstOrNull;

Map<String, Object?> setupToJson(TrainingSetupState setup) => {'location': setup.location.name, 'inventory': setup.inventory.name, 'ball': setup.ball?.name, 'passer': setup.passer?.name};

TrainingSetupState setupFromJson(Map<String, dynamic> json) => (
  location: _byName(LocationOption.values, json['location'] as String?) ?? defaultTrainingSetup.location,
  inventory: _byName(PuckInventory.values, json['inventory'] as String?) ?? defaultTrainingSetup.inventory,
  ball: _byName(BallType.values, json['ball'] as String?),
  passer: _byName(PasserType.values, json['passer'] as String?),
);

/// Focus points that add up to exactly 100, or the defaults if what was saved doesn't.
Map<SkillPillar, int> focusFromJson(Object? json) {
  if (json is! Map) return defaultTrainingFocus;
  final result = <SkillPillar, int>{};
  for (final pillar in SkillPillar.values) {
    final value = json[pillar.name];
    if (value is! int || value < 0 || value > 100) return defaultTrainingFocus;
    result[pillar] = value;
  }
  return result.values.fold(0, (a, b) => a + b) == 100 ? Map.unmodifiable(result) : defaultTrainingFocus;
}

Map<String, Object?> focusToJson(Map<SkillPillar, int> focus) => {for (final entry in focus.entries) entry.key.name: entry.value};

/// What the player has to train with. Remembered on the device so the next workout starts from it.
class TrainingSetup extends Notifier<TrainingSetupState> {
  static const storageKey = 'trainingSetup';

  @override
  TrainingSetupState build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (stored == null) return defaultTrainingSetup;
    try {
      return setupFromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on Object {
      return defaultTrainingSetup;
    }
  }

  void _set(TrainingSetupState next) {
    state = next;
    unawaited(ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(setupToJson(next))));
  }

  void apply(TrainingSetupState setup) => _set(setup);

  void selectLocation(LocationOption location) => _set((location: location, inventory: state.inventory, ball: state.ball, passer: state.passer));

  void selectInventory(PuckInventory inventory) => _set((location: state.location, inventory: inventory, ball: state.ball, passer: state.passer));

  void selectBall(BallType? ball) => _set((location: state.location, inventory: state.inventory, ball: ball, passer: state.passer));

  void selectPasser(PasserType? passer) => _set((location: state.location, inventory: state.inventory, ball: state.ball, passer: passer));
}

final trainingSetupProvider = NotifierProvider<TrainingSetup, TrainingSetupState>(TrainingSetup.new);

/// How long the player wants to train, in minutes.
class TrainingLength extends Notifier<int> {
  static const storageKey = 'trainingMinutes';

  @override
  int build() {
    final stored = ref.read(sharedPreferencesProvider).getInt(storageKey);
    return stored != null && routineLengthOptions.contains(stored) ? stored : 20;
  }

  void select(int minutes) {
    if (!routineLengthOptions.contains(minutes)) throw RangeError.value(minutes, 'minutes', 'Not an offered length.');
    state = minutes;
    unawaited(ref.read(sharedPreferencesProvider).setInt(storageKey, minutes));
  }
}

final trainingLengthProvider = NotifierProvider<TrainingLength, int>(TrainingLength.new);

class TrainingFocus extends Notifier<Map<SkillPillar, int>> {
  static const storageKey = 'trainingFocus';

  @override
  Map<SkillPillar, int> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (stored == null) return defaultTrainingFocus;
    try {
      return focusFromJson(jsonDecode(stored));
    } on Object {
      return defaultTrainingFocus;
    }
  }

  void apply(Map<SkillPillar, int> focus) => _store(focusFromJson(focusToJson(focus)));

  void _store(Map<SkillPillar, int> focus) {
    state = focus;
    unawaited(ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(focusToJson(focus))));
  }

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
    _store(Map.unmodifiable(next));
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

  TrainingSession copyWith({
    List<Drill>? drills,
    int? drillIndex,
    List<({String drillId, SetLog log})>? logs,
    DateTime? restEndsAt,
    DateTime? endedAt,
    bool clearRest = false,
    bool clearEnded = false,
    bool? dismissed,
  }) {
    final nextDrills = drills ?? this.drills;
    final nextLogs = logs ?? this.logs;
    final nextIndex = drillIndex ?? this.drillIndex;
    return TrainingSession(
      drills: nextDrills,
      drillIndex: nextIndex,
      logs: nextLogs,
      startedAt: startedAt,
      endedAt: clearEnded ? null : endedAt ?? this.endedAt,
      restEndsAt: clearRest ? null : restEndsAt ?? this.restEndsAt,
      setIndex: nextLogs.where((entry) => entry.drillId == nextDrills[nextIndex].id).length,
      dismissed: dismissed ?? this.dismissed,
    );
  }
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
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    if (state.setsLogged(index) > 0) throw StateError('Sets are already logged for this drill, so it can\'t be swapped.');
    if (state.drills.any((drill) => drill.id == replacement.id)) throw ArgumentError('That drill is already in this workout.');
    final drills = [...state.drills]..[index] = replacement;
    _update(state.copyWith(drills: List.unmodifiable(drills)));
  }

  void _checkEditable() {
    if (state.dismissed) throw StateError('This workout is already saved.');
  }

  /// Adds drills that aren't in the workout yet. Finishing is undone, since there is more to do.
  int addDrills(List<Drill> additions) {
    _checkEditable();
    final present = state.drills.map((drill) => drill.id).toSet();
    final fresh = <Drill>[];
    for (final drill in additions) {
      if (present.add(drill.id)) fresh.add(drill);
    }
    if (fresh.isEmpty) return 0;
    _update(state.copyWith(drills: List.unmodifiable([...state.drills, ...fresh]), clearEnded: true));
    return fresh.length;
  }

  /// Removes a drill with no logged sets. Logged results are never discarded; end the drill early instead.
  void removeDrill(int index) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    if (state.setsLogged(index) > 0) throw StateError('This drill has logged sets. End it early to keep them.');
    if (state.drills.length == 1) throw StateError('A workout needs at least one drill.');
    final current = state.drill.id;
    final drills = [...state.drills]..removeAt(index);
    final nextIndex = drills.indexWhere((drill) => drill.id == current);
    _update(state.copyWith(drills: List.unmodifiable(drills), drillIndex: nextIndex >= 0 ? nextIndex : index.clamp(0, drills.length - 1)));
  }

  /// Moves a drill to a new position without losing its sets. The drill being worked on stays selected.
  void moveDrill(int from, int to) {
    _checkEditable();
    if (from < 0 || from >= state.drills.length) throw RangeError.index(from, state.drills);
    if (to < 0 || to >= state.drills.length) throw RangeError.index(to, state.drills);
    if (from == to) return;
    final current = state.drill.id;
    final drills = [...state.drills];
    drills.insert(to, drills.removeAt(from));
    _update(state.copyWith(drills: List.unmodifiable(drills), drillIndex: drills.indexWhere((drill) => drill.id == current)));
  }

  static const maxSetsPerDrill = 12;

  Drill _withSets(Drill drill, int sets) => drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: sets));

  /// Adds one more set to a drill, reopening a workout that was finished.
  void addSet(int index) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    final drill = state.drills[index];
    if (drill.defaultPrescription.sets >= maxSetsPerDrill) throw StateError('A drill can have up to $maxSetsPerDrill sets.');
    final drills = [...state.drills]..[index] = _withSets(drill, drill.defaultPrescription.sets + 1);
    _update(state.copyWith(drills: List.unmodifiable(drills), clearEnded: true));
  }

  /// Takes away a planned set that hasn't been logged.
  void removeUnloggedSet(int index) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    final drill = state.drills[index];
    final sets = drill.defaultPrescription.sets;
    if (sets <= 1 || sets <= state.setsLogged(index)) throw StateError('Only an unlogged set can be removed.');
    final drills = [...state.drills]..[index] = _withSets(drill, sets - 1);
    _update(_finishIfDone(state.copyWith(drills: List.unmodifiable(drills))));
  }

  /// Stops a drill at the sets already logged. Skipped sets earn nothing and aren't recorded.
  void endDrillEarly(int index) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    final logged = state.setsLogged(index);
    if (logged == 0) throw StateError('Log a set first, or remove this drill.');
    final drills = [...state.drills]..[index] = _withSets(state.drills[index], logged);
    _update(_finishIfDone(state.copyWith(drills: List.unmodifiable(drills))));
  }

  /// Ends the workout with what has been logged: unstarted drills are dropped, partial drills stop where they are.
  void finishEarly() {
    _checkEditable();
    if (state.logs.isEmpty) throw StateError('Log at least one set before finishing.');
    final drills = [
      for (final (index, drill) in state.drills.indexed)
        if (state.setsLogged(index) > 0) _withSets(drill, state.setsLogged(index)),
    ];
    final current = state.drill.id;
    final nextIndex = drills.indexWhere((drill) => drill.id == current);
    _update(_finishIfDone(state.copyWith(drills: List.unmodifiable(drills), drillIndex: nextIndex >= 0 ? nextIndex : 0)));
  }

  TrainingSession _finishIfDone(TrainingSession next) => next.finished ? next.copyWith(clearRest: true, endedAt: clock.now().toUtc()) : next;

  /// Removes the most recent logged set of a drill, for a set logged by mistake.
  void undoLastSet(int index) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    final id = state.drills[index].id;
    final position = state.logs.lastIndexWhere((entry) => entry.drillId == id);
    if (position < 0) throw StateError('No logged set to undo.');
    final logs = [...state.logs]..removeAt(position);
    _update(state.copyWith(logs: List.unmodifiable(logs), clearEnded: true, clearRest: true));
  }

  /// Corrects a logged set's result.
  void editSet(int index, int setIndex, {int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
    _checkEditable();
    if (index < 0 || index >= state.drills.length) throw RangeError.index(index, state.drills);
    final drill = state.drills[index];
    validateSetEntry(drill.trackingType, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed);
    final position = state.logs.indexWhere((entry) => entry.drillId == drill.id && entry.log.setIndex == setIndex);
    if (position < 0) throw StateError('That set hasn\'t been logged.');
    final old = state.logs[position].log;
    final logs = [...state.logs];
    logs[position] = (drillId: drill.id, log: SetLog(setIndex: setIndex, reps: reps, hits: hits, seconds: seconds, streak: streak, completed: completed, loggedAt: old.loggedAt));
    _update(state.copyWith(logs: List.unmodifiable(logs)));
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

/// Whether workouts open on the Standard view (the scrolling list of sets) instead of the Simple guided
/// view, one drill at a time. Simple is the default; this remembers a player's choice on the device.
class WorkoutStandardViewPreference extends Notifier<bool> {
  static const storageKey = 'workoutStandardView';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(storageKey) ?? false;

  void choose(bool standard) {
    state = standard;
    unawaited(ref.read(sharedPreferencesProvider).setBool(storageKey, standard));
  }
}

final workoutStandardViewProvider = NotifierProvider<WorkoutStandardViewPreference, bool>(WorkoutStandardViewPreference.new);

class WorkoutSheetProgress extends Notifier<double> {
  @override
  double build() => 0;

  void update(double progress) => state = progress.clamp(0, 1).toDouble();
}

final workoutSheetProgressProvider = NotifierProvider<WorkoutSheetProgress, double>(WorkoutSheetProgress.new);
