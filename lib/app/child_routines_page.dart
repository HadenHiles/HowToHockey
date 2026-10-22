import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_catalog.dart';
import '../features/profiles/active_player.dart';
import '../features/routines/profile_routine_repository.dart';
import '../features/teams/team_repository.dart';
import 'app_page.dart';
import 'routine_state.dart';

/// A parent's list of the routines saved on a child's profile. They show up on the child's own Train screen.
class ChildRoutinesPage extends ConsumerWidget {
  const ChildRoutinesPage({required this.kidId, super.key});

  final String kidId;

  Future<void> _run(BuildContext context, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on RoutineException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  /// Offers the parent's own saved routines. Only library drills can go on a child's profile.
  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final catalog = await ref.read(drillCatalogProvider.future);
    final inLibrary = {for (final drill in catalog) drill.id};
    final routines = ref.read(allRoutinesProvider).where((routine) => routine.drills.every((drill) => inLibrary.contains(drill.id))).toList();
    if (!context.mounted) return;
    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save a routine first, using drills from the library. Custom drills can’t be sent.')));
      return;
    }
    final chosen = await showModalBottomSheet<RoutinePlan>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Send which routine?', style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final routine in routines)
              ListTile(
                key: ValueKey('send-${routine.id}'),
                minTileHeight: 56,
                title: Text(routine.name),
                subtitle: Text('${routine.drills.length} drills'),
                onTap: () => Navigator.of(sheetContext).pop(routine),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    final routine = TeamRoutine(name: chosen.name, drills: [for (final drill in chosen.drills) (drillId: drill.id, sets: drill.defaultPrescription.sets)]);
    await _run(context, () => ref.read(profileRoutineRepositoryProvider).save(kidId, routine), 'Sent.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(switchablePlayersProvider).where((p) => p.id == kidId).firstOrNull;
    final routines = ref.watch(profileRoutinesProvider(kidId));
    final repository = ref.read(profileRoutineRepositoryProvider);
    final theme = Theme.of(context);
    return AppPage(
      title: 'Routines',
      subtitle: kid == null ? null : 'These show up on ${kid.displayName}’s Train screen, on any device they use.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => context.push('/parent/kids/$kidId/routines/new'),
            icon: const Icon(Icons.add),
            label: const Text('Create a routine'),
          ),
          TextButton(onPressed: () => _send(context, ref), child: const Text('Send one of my routines')),
        ],
      ),
      children: [
        switch (routines) {
          AsyncData(:final value) when value.isEmpty => const Text('Nothing here yet. Free players keep up to 3 routines.'),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in value) ...[
                TrainingCard(
                  key: ValueKey('routine-${item.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.routine.name, style: theme.textTheme.titleMedium),
                            Text('${item.routine.drills.length} drills · ${item.routine.drills.fold<int>(0, (sum, d) => sum + d.sets)} sets'),
                          ],
                        ),
                      ),
                      IconButton(tooltip: 'Edit ${item.routine.name}', onPressed: () => context.push('/parent/kids/$kidId/routines/${item.id}/edit'), icon: const Icon(Icons.edit_outlined)),
                      IconButton(tooltip: 'Delete ${item.routine.name}', onPressed: () => _run(context, () => repository.delete(kidId, item.id), 'Deleted.'), icon: const Icon(Icons.delete_outline)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          AsyncError() => const Text('We couldn’t load the routines. Check your connection and try again.'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
