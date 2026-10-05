import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/drills/models/drill.dart';
import 'preview_data.dart';

// Local-only notifiers keep preview interactions separate from production data.
typedef PreviewSetupState = ({
  LocationOption location,
  PuckInventory inventory,
  BallType? ball,
  PasserType? passer,
});

class PreviewSetup extends Notifier<PreviewSetupState> {
  @override
  PreviewSetupState build() => (
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

final previewSetupProvider = NotifierProvider<PreviewSetup, PreviewSetupState>(PreviewSetup.new);

class PreviewFocus extends Notifier<Map<SkillPillar, int>> {
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

final previewFocusProvider = NotifierProvider<PreviewFocus, Map<SkillPillar, int>>(PreviewFocus.new);

class PreviewSession {
  const PreviewSession({
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

class PreviewSessionNotifier extends Notifier<PreviewSession> {
  @override
  PreviewSession build() => PreviewSession(drills: previewDrills);

  void start(List<Drill> drills) {
    if (drills.isEmpty) throw ArgumentError('A preview session needs at least one drill.');
    state = PreviewSession(drills: List.unmodifiable(drills));
  }

  void logSet({int? reps, int? hits, int? seconds, int? streak, bool? completed}) {
    if (state.finished) throw StateError('This preview session is already complete.');
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
    state = PreviewSession(
      drills: state.drills,
      drillIndex: state.drillIndex + (lastSet ? 1 : 0),
      setIndex: lastSet ? 0 : state.setIndex + 1,
      logs: List.unmodifiable([...state.logs, (drillId: drill.id, log: log)]),
    );
  }
}

final previewSessionProvider = NotifierProvider<PreviewSessionNotifier, PreviewSession>(PreviewSessionNotifier.new);
