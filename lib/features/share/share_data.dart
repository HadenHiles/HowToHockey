import '../progress/progress_stats.dart';
import 'share_card.dart';

String _minutes(num seconds) => seconds >= 3600 ? '${(seconds / 3600).toStringAsFixed(1)} h' : '${(seconds / 60).round()} min';

/// The card for one finished workout.
ShareCardData workoutCard({
  required int shots,
  required int activeSeconds,
  required int drills,
  required int sets,
  required List<PersonalBest> bests,
  required int streakDays,
  required String dateLabel,
}) {
  // Shots lead when there are some; otherwise the work is measured in time.
  final lead = shots > 0 ? (value: '$shots', label: shots == 1 ? 'shot' : 'shots') : (value: _minutes(activeSeconds), label: 'active training');
  return ShareCardData(
    eyebrow: 'Workout done',
    heroValue: lead.value,
    heroLabel: lead.label,
    stats: [if (shots > 0) (value: _minutes(activeSeconds), label: 'active'), (value: '$drills', label: drills == 1 ? 'drill' : 'drills'), (value: '$sets', label: sets == 1 ? 'set' : 'sets')],
    badges: [for (final best in bests) '${best.title} · ${best.valueLabel}'],
    streakDays: streakDays,
    dateLabel: dateLabel,
  );
}

/// The card for the last seven days.
ShareCardData weekCard({required LifetimeStats stats, required DateTime now, required String dateLabel}) {
  final shots = stats.weekShots(now);
  final seconds = stats.weekSeconds(now);
  final active = stats.lastSevenDays(now).where((d) => d.stats.seconds > 0).length;
  final recent = [
    for (final best in stats.bests.values)
      if (now.difference(best.achievedAt).inDays < 7) best,
  ]..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
  return ShareCardData(
    eyebrow: 'Weekly recap',
    heroValue: shots > 0 ? '$shots' : _minutes(seconds),
    heroLabel: shots > 0 ? (shots == 1 ? 'shot this week' : 'shots this week') : 'trained this week',
    stats: [(value: _minutes(seconds), label: 'active'), (value: '$active', label: active == 1 ? 'day trained' : 'days trained')],
    badges: [for (final best in recent) '${best.title} · ${best.valueLabel}'],
    streakDays: stats.currentStreak(now),
    dateLabel: dateLabel,
  );
}
