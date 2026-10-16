/// Something the timed-set UI should react to (play a cue, log the set, ...).
sealed class CountdownEvent {
  const CountdownEvent();
}

/// One of the lead-in beats; [secondsLeft] counts 3, 2, 1.
class LeadInTick extends CountdownEvent {
  const LeadInTick(this.secondsLeft);

  final int secondsLeft;

  @override
  bool operator ==(Object other) => other is LeadInTick && other.secondsLeft == secondsLeft;

  @override
  int get hashCode => secondsLeft.hashCode;

  @override
  String toString() => 'LeadInTick($secondsLeft)';
}

/// The lead-in finished and the timed set began.
class CountdownStarted extends CountdownEvent {
  const CountdownStarted();

  @override
  bool operator ==(Object other) => other is CountdownStarted;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'CountdownStarted';
}

/// The timed set reached zero.
class CountdownFinished extends CountdownEvent {
  const CountdownFinished();

  @override
  bool operator ==(Object other) => other is CountdownFinished;

  @override
  int get hashCode => 2;

  @override
  String toString() => 'CountdownFinished';
}

enum CountdownPhase { idle, leadIn, running, paused, done }

/// Pure, wall-clock based countdown for a timed set: a short lead-in, then the set, then done.
///
/// It never owns a timer. The caller calls [tick] often (for example every 200 ms) and reacts to
/// the returned events, so it stays correct when ticks are late, such as after the app was
/// backgrounded, and is easy to test with fake times.
class SetCountdown {
  SetCountdown({required this.totalSeconds, this.leadInSeconds = 3}) : assert(totalSeconds > 0), assert(leadInSeconds >= 0), _remainingMs = totalSeconds * 1000;

  final int totalSeconds;
  final int leadInSeconds;

  var _phase = CountdownPhase.idle;
  DateTime? _leadInStartedAt;
  DateTime? _runEndsAt;
  int _remainingMs;
  var _leadInTicksSent = 0;

  CountdownPhase get phase => _phase;
  bool get isDone => _phase == CountdownPhase.done;
  bool get isActive => _phase == CountdownPhase.leadIn || _phase == CountdownPhase.running;

  /// Whole seconds left in the set, rounded up so a fresh set shows its full length.
  int get remainingSeconds => _phase == CountdownPhase.done ? 0 : (_remainingMs / 1000).ceil();

  /// How much of the set has been used, from 0 to 1.
  double get progress => 1 - _remainingMs / (totalSeconds * 1000);

  /// 3, 2, 1 while in the lead-in, otherwise 0.
  int get leadInSecondsLeft => _phase == CountdownPhase.leadIn ? (leadInSeconds - _leadInTicksSent + 1).clamp(1, leadInSeconds) : 0;

  /// Starts a fresh countdown, or resumes a paused one. Returns events that are due immediately.
  List<CountdownEvent> start(DateTime now) {
    switch (_phase) {
      case CountdownPhase.idle:
        if (leadInSeconds == 0) return _beginRunning(now);
        _phase = CountdownPhase.leadIn;
        _leadInStartedAt = now;
        _leadInTicksSent = 0;
        return tick(now);
      case CountdownPhase.paused:
        _phase = CountdownPhase.running;
        _runEndsAt = now.add(Duration(milliseconds: _remainingMs));
        return const [];
      case CountdownPhase.leadIn || CountdownPhase.running || CountdownPhase.done:
        return const [];
    }
  }

  /// Pauses a running set. Pausing during the lead-in cancels it, so the lead-in restarts next time.
  void pause(DateTime now) {
    switch (_phase) {
      case CountdownPhase.running:
        _remainingMs = _runEndsAt!.difference(now).inMilliseconds.clamp(0, totalSeconds * 1000);
        _phase = CountdownPhase.paused;
      case CountdownPhase.leadIn:
        _phase = CountdownPhase.idle;
        _leadInTicksSent = 0;
      case CountdownPhase.idle || CountdownPhase.paused || CountdownPhase.done:
        break;
    }
  }

  /// Back to a fresh, unstarted countdown.
  void reset() {
    _phase = CountdownPhase.idle;
    _remainingMs = totalSeconds * 1000;
    _leadInTicksSent = 0;
    _leadInStartedAt = null;
    _runEndsAt = null;
  }

  /// Advances to [now] and returns every event that became due since the last call, in order.
  List<CountdownEvent> tick(DateTime now) {
    final events = <CountdownEvent>[];
    if (_phase == CountdownPhase.leadIn) {
      final elapsedMs = now.difference(_leadInStartedAt!).inMilliseconds;
      while (_leadInTicksSent < leadInSeconds && elapsedMs >= _leadInTicksSent * 1000) {
        events.add(LeadInTick(leadInSeconds - _leadInTicksSent));
        _leadInTicksSent++;
      }
      if (elapsedMs >= leadInSeconds * 1000) {
        // The set clock starts when the lead-in ends, not when a late tick arrived.
        events.addAll(_beginRunning(_leadInStartedAt!.add(Duration(seconds: leadInSeconds))));
      }
    }
    if (_phase == CountdownPhase.running) {
      final left = _runEndsAt!.difference(now).inMilliseconds;
      if (left <= 0) {
        _remainingMs = 0;
        _phase = CountdownPhase.done;
        events.add(const CountdownFinished());
      } else {
        _remainingMs = left;
      }
    }
    return events;
  }

  List<CountdownEvent> _beginRunning(DateTime at) {
    _phase = CountdownPhase.running;
    _runEndsAt = at.add(Duration(seconds: totalSeconds));
    _remainingMs = totalSeconds * 1000;
    return const [CountdownStarted()];
  }
}
