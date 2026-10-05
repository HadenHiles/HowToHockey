import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
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
      actions: const [
        Padding(padding: EdgeInsets.only(right: AppSpacing.screen), child: BrandWordmark()),
      ],
      children: [
        Text('Your next shift starts here.', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text('A little better. Every day.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TODAY’S SUGGESTION', style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.md),
              const DrillMediaPlaceholder(title: 'Build your foundation', compact: true),
              const SizedBox(height: AppSpacing.md),
              Text('Build your foundation', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('20 min · 6 drills · All levels', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context.push('/routine'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View workout'),
              ),
            ],
          ),
        ),
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
        OutlinedButton.icon(
          onPressed: () => context.push('/setup'),
          icon: const Icon(Icons.tune),
          label: const Text('Build a workout'),
        ),
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
        for (final drill in sampleDrills.take(2)) ...[
          DrillListCard(drillId: drill.id),
          const SizedBox(height: AppSpacing.sm),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillarTag(label: drill.pillar.label, color: drill.pillar.color(pillars)),
          const SizedBox(height: AppSpacing.sm),
          Text(drill.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('${drill.prescriptionLabel} · ${drill.trackingType.label}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: Text('View drill', style: theme.textTheme.labelLarge)),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Progress',
    subtitle: 'Small sessions. Lasting progress.',
    children: [
      const Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          MetricTile(value: '2,480', label: 'Lifetime shots', detail: '+140 this week'),
          MetricTile(value: '18.5 h', label: 'Active training', detail: 'Rest time excluded'),
          MetricTile(value: '32', label: 'Workouts completed'),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Recent training'),
      const SizedBox(height: AppSpacing.md),
      TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick hands, clean release', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('Yesterday · 24 active min · 80 shots'),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      const Text('Radar, PR Vault, history, and share-card review are in the next UX slice. These totals are sample data.'),
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
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS WEEK’S HOMEWORK', style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.md),
              Text('Build your foundation', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('From Coach Jeremy · Due Friday'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: () => context.push('/routine'), child: const Text('View assigned workout')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Locker room'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alex R. completed a workout', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              const Text('24 active min · 80 shots · 5-day streak'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Sample system-generated post · No player text or uploads'),
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
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jamie H.', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('Player · Sample profile'),
              const SizedBox(height: AppSpacing.md),
              const Text('Profile and role switching will be reviewed with the Parent and Coach shells.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Appearance', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('One app. Light, dark, or your device setting.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in AppAppearance.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option == appearance,
                onSelected: (_) => unawaited(ref.read(appearanceProvider.notifier).setAppearance(option)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const TrainingCard(
          child: Text('Data and services\nScreens currently use sample content. Workout results stay on this device until restart; history, team updates, and purchases are not connected yet. Appearance is saved to this device.'),
        ),
      ],
    );
  }
}
