import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/models/drill.dart';
import 'sample_data.dart';

// Back these providers with persistence when the session-engine milestone resumes.
typedef TrainingSetupState = ({
  LocationOption location,
  PuckInventory inventory,
  BallType? ball,
  PasserType? passer,
});

class TrainingSetup extends Notifier<TrainingSetupState> {
  @override
  TrainingSetupState build() => (
    location: LocationOption.drivewayGarage,
    inventory: PuckInventory.low,
    ball: null,
    passer: PasserType.partner,
  );

  void selectLocation(LocationOption location) => state = (
    location: location, inventory: state.inventory, ball: state.ball, passer: state.passer,
  );

  void selectInventory(PuckInventory inventory) => state = (
    location: state.location, inventory: inventory, ball: state.ball, passer: state.passer,
  );

  void selectBall(BallType? ball) => state = (
    location: state.location, inventory: state.inventory, ball: ball, passer: state.passer,
  );

  void selectPasser(PasserType? passer) => state = (
    location: state.location, inventory: state.inventory, ball: state.ball, passer: passer,
  );
}

final trainingSetupProvider = NotifierProvider<TrainingSetup, TrainingSetupState>(TrainingSetup.new);

class TrainingFocus extends Notifier<Map<SkillPillar, int>> {
  @override
  Map<SkillPillar, int> build() => const {
    SkillPillar.shooting: 40,
    SkillPillar.stickhandling: 25,
    SkillPillar.skating: 15,
    SkillPillar.passing: 10,
    SkillPillar.iqConditioning: 10,
  };

  void select(SkillPillar pillar, int value) {
    if (value < 0 || value > 100) {
      throw RangeError.range(value, 0, 100, 'focus');
    }
    final others = SkillPillar.values.where((item) => item != pillar).toList();
    final remaining = 100 - value;
    final total = others.fold(0, (sum, item) => sum + state[item]!);
    final shares = {
      for (final item in others) item: remaining * (total == 0 ? 1 / others.length : state[item]! / total),
    };
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
  const TrainingSession({
    required this.drills,
    this.drillIndex = 0,
    this.setIndex = 0,
    this.logs = const [],
  });

  final List<Drill> drills;
  final int drillIndex;
  final int setIndex;
  final List<({String drillId, SetLog log})> logs;

  bool get finished => drillIndex >= drills.length;
  Drill get drill => drills[drillIndex];
}

class TrainingSessionNotifier extends Notifier<TrainingSession> {
  @override
  TrainingSession build() => TrainingSession(drills: sampleDrills);

  void start(List<Drill> drills) {
    if (drills.isEmpty) throw ArgumentError('A session needs at least one drill.');
    state = TrainingSession(drills: List.unmodifiable(drills));
  }

  void logSet({int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
    if (state.finished) throw StateError('This session is already complete.');
    final drill = state.drill;
    final log = SetLog(
      setIndex: state.setIndex,
      reps: reps,
      hits: hits,
      seconds: seconds,
      streak: streak,
      completed: completed,
      loggedAt: DateTime.now().toUtc(),
    );
    final lastSet = state.setIndex + 1 >= drill.defaultPrescription.sets;
    state = TrainingSession(
      drills: state.drills,
      drillIndex: state.drillIndex + (lastSet ? 1 : 0),
      setIndex: lastSet ? 0 : state.setIndex + 1,
      logs: List.unmodifiable([...state.logs, (drillId: drill.id, log: log)]),
    );
  }
}

final trainingSessionProvider = NotifierProvider<TrainingSessionNotifier, TrainingSession>(TrainingSessionNotifier.new);
