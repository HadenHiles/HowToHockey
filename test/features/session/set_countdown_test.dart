import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/session/set_countdown.dart';

final t0 = DateTime.utc(2026, 1, 1, 12);
DateTime at(double seconds) => t0.add(Duration(milliseconds: (seconds * 1000).round()));

void main() {
  test('starting begins a 3-2-1 lead-in and the first beat is immediate', () {
    final c = SetCountdown(totalSeconds: 30);
    expect(c.phase, CountdownPhase.idle);
    expect(c.start(t0), [const LeadInTick(3)]);
    expect(c.phase, CountdownPhase.leadIn);
    expect(c.leadInSecondsLeft, 3);
    expect(c.remainingSeconds, 30);
  });

  test('lead-in beats arrive each second, then the set starts and its clock begins at the end of the lead-in', () {
    final c = SetCountdown(totalSeconds: 30)..start(t0);
    expect(c.tick(at(.5)), isEmpty);
    expect(c.tick(at(1)), [const LeadInTick(2)]);
    expect(c.leadInSecondsLeft, 2);
    expect(c.tick(at(2.1)), [const LeadInTick(1)]);
    expect(c.leadInSecondsLeft, 1);
    expect(c.tick(at(3)), [const CountdownStarted()]);
    expect(c.phase, CountdownPhase.running);
    expect(c.remainingSeconds, 30);
    c.tick(at(8.2));
    expect(c.remainingSeconds, 25);
    expect(c.progress, closeTo(5 / 30, 0.01));
  });

  test('a late tick still emits every missed event in order, with the clock anchored to the lead-in end', () {
    final c = SetCountdown(totalSeconds: 10)..start(t0);
    // Jump straight to 5.5s: lead-in 2, 1, start, and 2.5 s into the set.
    expect(c.tick(at(5.5)), [const LeadInTick(2), const LeadInTick(1), const CountdownStarted()]);
    expect(c.remainingSeconds, 8);
  });

  test('the set finishes exactly once and then stays done', () {
    final c = SetCountdown(totalSeconds: 5)..start(t0);
    c.tick(at(3));
    expect(c.tick(at(7.9)), isEmpty);
    expect(c.remainingSeconds, 1);
    expect(c.tick(at(8)), [const CountdownFinished()]);
    expect(c.isDone, isTrue);
    expect(c.remainingSeconds, 0);
    expect(c.progress, 1);
    expect(c.tick(at(20)), isEmpty);
    expect(c.start(at(21)), isEmpty);
  });

  test('a very late tick can start and finish in one call', () {
    final c = SetCountdown(totalSeconds: 5)..start(t0);
    expect(c.tick(at(100)).last, const CountdownFinished());
    expect(c.isDone, isTrue);
  });

  test('pausing keeps the remaining time and resuming continues from it without a new lead-in', () {
    final c = SetCountdown(totalSeconds: 30)..start(t0);
    c.tick(at(3));
    c.tick(at(13));
    c.pause(at(13));
    expect(c.phase, CountdownPhase.paused);
    expect(c.remainingSeconds, 20);
    expect(c.tick(at(60)), isEmpty, reason: 'a paused set does not run down');
    expect(c.remainingSeconds, 20);

    expect(c.start(at(60)), isEmpty);
    expect(c.phase, CountdownPhase.running);
    c.tick(at(70));
    expect(c.remainingSeconds, 10);
    expect(c.tick(at(80)), [const CountdownFinished()]);
  });

  test('pausing during the lead-in cancels it and the lead-in restarts next time', () {
    final c = SetCountdown(totalSeconds: 30)..start(t0);
    c.tick(at(1.5));
    c.pause(at(1.5));
    expect(c.phase, CountdownPhase.idle);
    expect(c.remainingSeconds, 30);
    expect(c.start(at(10)), [const LeadInTick(3)]);
  });

  test('a zero-second lead-in starts the set immediately', () {
    final c = SetCountdown(totalSeconds: 20, leadInSeconds: 0);
    expect(c.start(t0), [const CountdownStarted()]);
    expect(c.phase, CountdownPhase.running);
  });

  test('reset returns to a fresh countdown', () {
    final c = SetCountdown(totalSeconds: 5)..start(t0);
    c.tick(at(30));
    c.reset();
    expect(c.phase, CountdownPhase.idle);
    expect(c.remainingSeconds, 5);
    expect(c.progress, 0);
  });

  test('starting while already running does nothing', () {
    final c = SetCountdown(totalSeconds: 30)..start(t0);
    c.tick(at(3));
    expect(c.start(at(5)), isEmpty);
    c.pause(at(5));
    c.pause(at(6));
    expect(c.phase, CountdownPhase.paused);
  });
}
