import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/set_summary.dart';
import '../features/profiles/active_player.dart';
import 'app_page.dart';
import 'training_state.dart';

/// A child's finished workout waits for a grown-up here before it is saved and counted.
final needsParentConfirmationProvider = Provider<bool>((ref) => ref.watch(activePlayerProvider)?.isChild ?? false);

/// "Hand to a grown-up": every drill and set of a child's finished workout, with a Confirm & save.
class ParentReviewPage extends ConsumerWidget {
  const ParentReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trainingSessionProvider);
    final player = ref.watch(activePlayerProvider);
    if (session.startedAt == null || session.dismissed || !session.finished) {
      return AppPage(
        title: 'Nothing to review',
        action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
        children: const [Text('A finished workout that is waiting for a grown-up shows up here.')],
      );
    }
    final theme = Theme.of(context);
    final name = player?.displayName;
    return AppPage(
      title: 'Hand to a grown-up',
      subtitle: name == null ? 'Check the results, then save the workout.' : 'Check $name\'s results, then save the workout.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64), textStyle: theme.textTheme.titleMedium),
            onPressed: () {
              ref.read(trainingSessionProvider.notifier).dismissFinishedWorkout();
              context.go('/summary');
            },
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Confirm & save'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workoutStandardViewProvider.notifier).choose(true);
              context.go('/train/session');
            },
            child: const Text('Fix a result'),
          ),
        ],
      ),
      children: [
        for (final (index, drill) in session.drills.indexed) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drill.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                for (final entry in session.logs.where((entry) => entry.drillId == drill.id))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('Set ${entry.log.setIndex + 1} · ${setResultLabel(entry.log, drill.trackingType)}', style: theme.textTheme.bodyMedium),
                  ),
                if (session.setsLogged(index) == 0) Text('Skipped', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
