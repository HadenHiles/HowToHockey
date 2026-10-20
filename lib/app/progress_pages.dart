import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/progress/drill_trends.dart';
import 'app_page.dart';
import 'player_pages.dart';
import 'progress_state.dart';
import 'training_state.dart';
import 'workout_history.dart';

/// One finished workout as a tappable card: title, when, active minutes, shots, drills and sets.
class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({required this.workout, super.key});

  final TrainingSession workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TrainingCard(
      onTap: () => context.push('/history/${workoutId(workout)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(workoutTitle(workout), style: theme.textTheme.titleLarge)),
              Icon(Icons.arrow_outward, color: theme.colorScheme.primary, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${workoutDateLabel(workout.startedAt!.toLocal(), clock.now()).toUpperCase()}  ·  ${(workout.activeSeconds / 60).round()} ACTIVE MIN', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              HistoryStat(value: '${shotsLogged(workout)}', label: 'shots'),
              HistoryStat(value: '${workout.drills.length}', label: workout.drills.length == 1 ? 'drill' : 'drills'),
              HistoryStat(value: '${workout.logs.length}', label: workout.logs.length == 1 ? 'set' : 'sets'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Every workout saved on this device, newest first.
class HistoryListPage extends ConsumerWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    return AppPage(
      title: 'Workout history',
      subtitle: history.isEmpty ? null : 'Your latest ${history.length} ${history.length == 1 ? 'workout' : 'workouts'}, saved on this device.',
      actions: [IconButton(tooltip: 'Back to Progress', icon: const Icon(Icons.close), onPressed: () => context.go('/progress'))],
      children: [
        if (history.isEmpty)
          const TrainingCard(child: Text('No workouts yet. Finish one and it shows up here.'))
        else
          for (final workout in history) ...[WorkoutHistoryCard(workout: workout), const SizedBox(height: AppSpacing.sm)],
      ],
    );
  }
}

/// How each drill has gone, workout by workout. A Player Pro feature.
class DrillBreakdownPage extends ConsumerWidget {
  const DrillBreakdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(playerProProvider);
    final trends = drillTrends([for (final workout in ref.watch(workoutHistoryProvider)) workout.toRecord()]);
    return AppPage(
      title: 'Drill by drill',
      subtitle: 'How each drill has gone across your recent workouts.',
      actions: [IconButton(tooltip: 'Back to Progress', icon: const Icon(Icons.close), onPressed: () => context.go('/progress'))],
      children: [
        ProLocked(
          unlocked: pro,
          message: 'See every drill\'s results, workout by workout.',
          child: trends.isEmpty
              ? const TrainingCard(child: Text('Finish a workout and each drill\'s results show up here.'))
              : Column(
                  children: [
                    for (final trend in trends) ...[DrillTrendCard(trend: trend), const SizedBox(height: AppSpacing.sm)],
                  ],
                ),
        ),
      ],
    );
  }
}

class DrillTrendCard extends StatelessWidget {
  const DrillTrendCard({required this.trend, super.key});

  final DrillTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = trend.points.length;
    return TrainingCard(
      onTap: () => context.push('/drills/${trend.drillId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trend.title, style: theme.textTheme.titleMedium),
          Text('${trend.metricLabel} · $workouts ${workouts == 1 ? 'workout' : 'workouts'}', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Sparkline(values: [for (final p in trend.points) p.value], semanticLabel: '${trend.title}. Latest ${trend.format(trend.latest)}, best ${trend.format(trend.best)}.'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              HistoryStat(value: trend.format(trend.latest), label: 'latest'),
              const SizedBox(width: AppSpacing.xl),
              HistoryStat(value: trend.format(trend.best), label: 'best'),
              const SizedBox(width: AppSpacing.xl),
              HistoryStat(value: '${trend.totalSets}', label: trend.totalSets == 1 ? 'set' : 'sets'),
            ],
          ),
        ],
      ),
    );
  }
}
