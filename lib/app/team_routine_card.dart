import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/drills/drill_catalog.dart';
import '../features/profiles/active_player.dart';
import '../features/routines/profile_routine_repository.dart';
import '../features/teams/team_repository.dart';
import 'manual_logger_pages.dart';
import 'routine_state.dart';
import 'training_state.dart';

/// "Coach's routine": the one routine a team's coach shares, with a big Start.
class TeamRoutineCard extends ConsumerWidget {
  const TeamRoutineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(activePlayerProvider);
    // Guests have no teams, so there is nothing to look up.
    final auth = ref.watch(authStateProvider).value;
    if (auth is! SignedInAccount && auth is! KidDeviceSession) return const SizedBox.shrink();
    final teams = (ref.watch(memberTeamsProvider).value ?? const <Team>[]).where((team) => team.routine != null && (player == null || team.memberProfileIds.contains(player.id))).toList();
    final catalog = ref.watch(drillCatalogProvider).value;
    if (teams.isEmpty || catalog == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final team in teams)
            TrainingCard(
              key: ValueKey('team-routine-${team.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Coach’s routine · ${team.name}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(team.routine!.name, style: theme.textTheme.titleLarge),
                  Text('${team.routine!.drills.length} drills · ${team.routine!.drills.fold<int>(0, (sum, d) => sum + d.sets)} sets', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: () async {
                      final drills = drillsForTeamRoutine(team.routine!, catalog);
                      if (drills.isEmpty) return;
                      if (!await confirmReplaceWorkout(context, ref)) return;
                      ref.read(trainingSessionProvider.notifier).start(drills);
                      if (context.mounted) context.go('/train/session');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "From your grown-up": routines a parent saved on this child's profile, each with a big Start.
class GrownUpRoutinesCard extends ConsumerWidget {
  const GrownUpRoutinesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(activePlayerProvider);
    if (player == null || !player.isChild) return const SizedBox.shrink();
    final routines = ref.watch(profileRoutinesProvider(player.id)).value ?? const <ProfileRoutine>[];
    final catalog = ref.watch(drillCatalogProvider).value;
    if (routines.isEmpty || catalog == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('From your grown-up', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            for (final item in routines)
              ListTile(
                key: ValueKey('grown-up-routine-${item.id}'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 64,
                title: Text(item.routine.name, style: theme.textTheme.titleMedium),
                subtitle: Text('${item.routine.drills.length} drills'),
                trailing: const Icon(Icons.play_circle_fill, size: 40),
                onTap: () async {
                  final drills = drillsForTeamRoutine(item.routine, catalog);
                  if (drills.isEmpty) return;
                  if (!await confirmReplaceWorkout(context, ref)) return;
                  ref.read(trainingSessionProvider.notifier).start(drills);
                  if (context.mounted) context.go('/train/session');
                },
              ),
          ],
        ),
      ),
    );
  }
}
