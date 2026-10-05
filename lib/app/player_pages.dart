import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_shapes.dart';
import '../design/tokens/app_spacing.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'training_state.dart';

class TrainPage extends ConsumerWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final setup = ref.watch(trainingSetupProvider);
    return AppPage(
      title: 'Train',
      appBarTitle: const BrandWordmark(),
      centerAppBarTitle: true,
      children: [
        TrainingHeroCard(eyebrow: 'Today on the ice', title: 'Build your\nfoundation', detail: 'A little better. Every day.', metrics: const [('20', 'minutes'), ('06', 'drills'), ('12', 'sets')], actionLabel: 'View workout', onTap: () => context.push('/routine')),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Your setup', action: 'Edit', onAction: () => context.push('/setup')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(label: Text(setup.location.label), avatar: const Icon(Icons.place_outlined), onPressed: () => context.push('/setup')),
            ActionChip(label: Text(setup.inventory.label), avatar: const Icon(Icons.sports_hockey_outlined), onPressed: () => context.push('/setup')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(onPressed: () => context.push('/setup'), icon: const Icon(Icons.tune), label: const Text('Build a workout')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(onPressed: () => context.push('/routines'), icon: const Icon(Icons.view_list_outlined), label: const Text('Manage routines')),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const TrainingProgressRing(progress: .6, value: '72', label: 'of 120 min this week'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_fire_department_outlined, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.xs),
                  Text('5-day streak', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Keep showing up.'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Explore drills', action: 'See all', onAction: () => context.push('/library')),
        const SizedBox(height: AppSpacing.md),
        for (final drill in sampleDrills.take(2)) ...[DrillListCard(drillId: drill.id), const SizedBox(height: AppSpacing.sm)],
        const SizedBox(height: AppSpacing.sm),
        Text('Just want to log?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ref.read(trainingSessionProvider.notifier).start([sampleDrills.first]);
                context.push('/session');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Shot logger'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(trainingSessionProvider.notifier).start([sampleDrills[1]]);
                context.push('/session');
              },
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Timer'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class DrillListCard extends StatelessWidget {
  const DrillListCard({required this.drillId, super.key});

  final String drillId;

  @override
  Widget build(BuildContext context) {
    final drill = sampleDrills.firstWhere((drill) => drill.id == drillId);
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return TrainingCard(
      onTap: () => context.push('/drills/$drillId'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(color: drill.pillar.color(pillars).withValues(alpha: .14), borderRadius: BorderRadius.circular(AppRadii.control)),
            child: Icon(drill.pillar.icon, size: 28, color: drill.pillar.color(pillars)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drill.pillar.label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: drill.pillar.color(pillars), letterSpacing: .8)),
                const SizedBox(height: AppSpacing.xs),
                Text(drill.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text('${drill.prescriptionLabel} · ${drill.trackingType.label}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.arrow_forward, color: theme.colorScheme.primary, size: 18),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return AppPage(
      title: 'Progress',
      subtitle: 'Your work is adding up.',
      children: [
        ArenaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS SEASON', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              Text('2,480', style: theme.textTheme.displayMedium),
              Text('SHOTS ON GOAL', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xl),
              const WeeklyTrainingChart(),
              const SizedBox(height: AppSpacing.md),
              Text('140 shots this week  ·  18.5 hours on ice', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Your skill map'),
        const SizedBox(height: AppSpacing.md),
        ArenaPanel(
          child: Column(
            children: [
              const SkillRadar(scores: [82, 68, 74, 57, 65, 61]),
              const SizedBox(height: AppSpacing.md),
              Text('ACCURACY IS YOUR TOP SKILL', style: theme.textTheme.labelMedium?.copyWith(color: pillars.shotAccuracy, letterSpacing: .6)),
              const SizedBox(height: AppSpacing.xs),
              Text('One more endurance session rounds out your game.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Personal bests'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            MetricTile(value: '84%', label: 'Shot accuracy', detail: 'Best session', accent: pillars.shotAccuracy),
            MetricTile(value: '47', label: 'Pass streak', detail: 'Clean touches', accent: pillars.passing),
            MetricTile(value: '5 days', label: 'Training streak', accent: pillars.speedStrength),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Lifetime totals'),
        const SizedBox(height: AppSpacing.md),
        const ArenaPanel(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _HistoryStat(value: '18.5 h', label: 'active hours'),
              _HistoryStat(value: '32', label: 'workouts'),
              _HistoryStat(value: '140', label: 'shots this week'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Recent training'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick hands, clean release', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('SAMPLE SESSION  ·  YESTERDAY', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.md),
                    const Text('24 active min · 80 shots · 4 drills · 6 sets'),
                    const SizedBox(height: AppSpacing.md),
                    const Text('This session is a design sample. Completed workouts are not saved to history yet.'),
                  ],
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Quick hands, clean release', style: Theme.of(context).textTheme.titleLarge)),
                  Icon(Icons.arrow_outward, color: Theme.of(context).colorScheme.primary, size: 18),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('YESTERDAY  ·  24 ACTIVE MIN', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.md),
              const Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.sm,
                children: [
                  _HistoryStat(value: '80', label: 'shots'),
                  _HistoryStat(value: '4', label: 'drills'),
                  _HistoryStat(value: '6', label: 'sets'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) {
              final colors = Theme.of(context).extension<AppColors>()!;
              final theme = Theme.of(context);
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Progress card preview', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? colors.surface : colors.textPrimary, borderRadius: BorderRadius.circular(AppRadii.card)),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HOW TO HOCKEY  ·  WEEKLY RECAP', style: theme.textTheme.labelSmall?.copyWith(color: colors.brandPrimaryOnDark)),
                              const SizedBox(height: AppSpacing.xl),
                              Text('140', style: theme.textTheme.displayMedium?.copyWith(color: theme.brightness == Brightness.dark ? colors.textPrimary : colors.brandCream)),
                              Text('SHOTS THIS WEEK', style: theme.textTheme.labelMedium?.copyWith(color: theme.brightness == Brightness.dark ? colors.textPrimary : colors.brandCream)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Preview only · Sample data · Sharing is not connected yet', style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              );
            },
          ),
          child: Row(
            children: [
              Icon(Icons.ios_share, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share your progress', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    const Text('A clean recap of the work you put in.'),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Progress is representative sample data. Workouts are not yet saved to history.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Team',
      subtitle: 'North Stars · U15',
      children: [
        TrainingHeroCard(eyebrow: 'Coach Jeremy  ·  Due Friday', title: 'Team\nhomework', detail: 'Build your foundation', metrics: const [('20', 'minutes'), ('06', 'drills')], actionLabel: 'View assignment', onTap: () => context.push('/routine')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Locker room'),
        const SizedBox(height: AppSpacing.md),
        ArenaPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, child: const Text('AR')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alex R.', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('Finished a workout', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    const Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _HistoryStat(value: '24', label: 'active min'),
                        _HistoryStat(value: '80', label: 'shots'),
                        _HistoryStat(value: '5', label: 'day streak'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('SAMPLE TEAM UPDATE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Team discovery, leaderboards, invites, and stick-tap interactions are scheduled for a later UX slice.'),
      ],
    );
  }
}

class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    return AppPage(
      title: 'Me',
      children: [
        ArenaPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                child: Text('JH', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jamie H.', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('PLAYER  ·  SAMPLE PROFILE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.dark.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Appearance'),
        const SizedBox(height: AppSpacing.sm),
        const Text('One app. Light, dark, or your device setting.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final option in AppAppearance.values) ChoiceChip(label: Text(option.label), selected: option == appearance, onSelected: (_) => unawaited(ref.read(appearanceProvider.notifier).setAppearance(option)))],
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data & services', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text('Screens currently use sample content. Workout results stay on this device until restart; history, team updates, and purchases are not connected yet.'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text('Appearance is saved to this device.', style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
