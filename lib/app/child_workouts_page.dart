import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/profiles/active_player.dart';
import '../features/sessions/session_repository.dart';
import 'app_page.dart';
import 'workout_history.dart';

final _childWorkoutsProvider = StreamProvider.family<List<ChildWorkout>, String>((ref, profileId) => ref.watch(sessionRepositoryProvider).watchRecent(profileId));

/// A parent's view of their child's counted workouts, with ways to fix the training time or remove one.
/// Every change is recorded on the server (who, when, what it was before).
class ChildWorkoutsPage extends ConsumerWidget {
  const ChildWorkoutsPage({required this.kidId, super.key});

  final String kidId;

  Future<void> _run(BuildContext context, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on SessionCorrectionException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(switchablePlayersProvider).where((p) => p.id == kidId).firstOrNull;
    final workouts = ref.watch(_childWorkoutsProvider(kidId));
    final repository = ref.read(sessionRepositoryProvider);
    final theme = Theme.of(context);
    return AppPage(
      title: 'Workouts',
      subtitle: kid == null ? null : '${kid.displayName}’s counted workouts. Fix a time, or remove one that shouldn’t count.',
      children: [
        switch (workouts) {
          AsyncData(:final value) when value.isEmpty => const Text('No counted workouts yet.'),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final workout in value) ...[
                TrainingCard(
                  key: ValueKey('workout-${workout.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.routineName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${workoutDateLabel(workout.startedAt.toLocal(), clock.now())} · ${workout.drillCount} ${workout.drillCount == 1 ? 'drill' : 'drills'} · ${(workout.seconds / 60).round()} min${workout.corrected ? ' · edited' : ''}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              onPressed: () async {
                                final minutes = await showDialog<int>(
                                  context: context,
                                  builder: (_) => _TimeDialog(initial: (workout.seconds / 60).round().clamp(1, 180)),
                                );
                                if (minutes != null && context.mounted) await _run(context, () => repository.correctTime(workout, minutes), 'Time updated.');
                              },
                              child: const Text('Fix time'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Remove this workout?'),
                                    content: const Text('It stops counting toward totals and personal bests. A record of the change is kept.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep')),
                                      FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) await _run(context, () => repository.removeWorkout(workout), 'Workout removed.');
                              },
                              child: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          AsyncError() => const Text('We couldn’t load the workouts. Check your connection and try again.'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

/// Picks training minutes with big buttons: no keyboard.
class _TimeDialog extends StatefulWidget {
  const _TimeDialog({required this.initial});

  final int initial;

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  late var _minutes = widget.initial;

  void _change(int by) => setState(() => _minutes = (_minutes + by).clamp(1, 180));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('How long was the training?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_minutes min', key: const ValueKey('minutes'), style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              for (final step in const [-10, -5, -1, 1, 5, 10])
                SizedBox(
                  width: 80,
                  height: 48,
                  child: OutlinedButton(onPressed: () => _change(step), child: Text(step > 0 ? '+$step' : '$step')),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_minutes), child: const Text('Save')),
      ],
    );
  }
}
