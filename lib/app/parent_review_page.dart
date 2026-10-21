import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/drills/set_summary.dart';
import '../features/profiles/active_player.dart';
import '../features/sessions/session_repository.dart';
import 'app_page.dart';
import 'training_state.dart';

/// A child's finished workout waits for a grown-up here before it is saved and counted. This is the single-device case:
/// a parent's account is training as one of its children, so the parent is the one holding the phone.
final needsParentConfirmationProvider = Provider<bool>((ref) => (ref.watch(activePlayerProvider)?.isChild ?? false) && ref.watch(authStateProvider).value is SignedInAccount);

/// A child's own device sends the workout to the parent's account to confirm, from the parent's device.
final sendsToGrownUpProvider = Provider<bool>((ref) => ref.watch(authStateProvider).value is KidDeviceSession);

final _pendingForProfileProvider = StreamProvider.family<List<PendingWorkout>, String>((ref, profileId) => ref.watch(sessionRepositoryProvider).watchPending(profileId));

/// Workouts the account's children sent from their own devices, waiting for this grown-up to confirm.
final pendingWorkoutsProvider = Provider<List<PendingWorkout>>((ref) {
  if (ref.watch(authStateProvider).value is! SignedInAccount) return const [];
  return [for (final child in ref.watch(switchablePlayersProvider).where((p) => p.isChild)) ...?ref.watch(_pendingForProfileProvider(child.id)).value];
});

final _pendingDrillsProvider = FutureProvider.family<List<PendingDrill>, ({String profileId, String id})>((ref, key) => ref.watch(sessionRepositoryProvider).loadPendingDrills(key.profileId, key.id));

String _childName(WidgetRef ref, String profileId) => ref.read(switchablePlayersProvider).where((p) => p.id == profileId).firstOrNull?.displayName ?? 'Your child';

/// "Avery sent a workout": the grown-up's queue, shown at the top of Train.
class PendingWorkoutsCard extends ConsumerWidget {
  const PendingWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingWorkoutsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Waiting for you', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final workout in pending)
              ListTile(
                key: ValueKey('pending-${workout.id}'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 56,
                title: Text('${_childName(ref, workout.profileId)} finished a workout'),
                subtitle: Text('${workout.routineName} · ${workout.drillCount} drills'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/review/${workout.profileId}/${workout.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// A grown-up checks a workout a child sent from their own device, then confirms (it counts) or discards it.
class PendingReviewPage extends ConsumerStatefulWidget {
  const PendingReviewPage({required this.profileId, required this.sessionId, super.key});

  final String profileId;
  final String sessionId;

  @override
  ConsumerState<PendingReviewPage> createState() => _PendingReviewPageState();
}

class _PendingReviewPageState extends ConsumerState<PendingReviewPage> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      router.go('/train');
    } on Object {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(const SnackBar(content: Text('That didn\'t work. Check your connection and try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(pendingWorkoutsProvider).where((w) => w.profileId == widget.profileId && w.id == widget.sessionId).firstOrNull;
    if (workout == null) {
      return AppPage(
        title: 'Nothing to review',
        action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
        children: const [Text('This workout has already been checked.')],
      );
    }
    final theme = Theme.of(context);
    final drills = ref.watch(_pendingDrillsProvider((profileId: widget.profileId, id: widget.sessionId)));
    final repository = ref.read(sessionRepositoryProvider);
    return AppPage(
      title: 'Check the workout',
      subtitle: '${_childName(ref, workout.profileId)} sent this from their own device.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64), textStyle: theme.textTheme.titleMedium),
            onPressed: _busy || drills.value == null ? null : () => _run(() => repository.confirm(workout), 'Saved. It counts now.'),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Confirm & save'),
          ),
          TextButton(onPressed: _busy ? null : () => _run(() => repository.discard(workout), 'Workout discarded.'), child: const Text('Discard this workout')),
        ],
      ),
      children: [
        switch (drills) {
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final drill in value) ...[
                TrainingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drill.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      for (final log in drill.sets) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Set ${log.setIndex + 1} · ${setResultLabel(log, drill.trackingType)}')),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          AsyncError() => const Text('We couldn\'t load the results. Check your connection and try again.'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

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
