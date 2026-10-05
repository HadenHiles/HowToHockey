import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/models/drill.dart';
import 'player_pages.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'training_state.dart';
import 'session_pages.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(trainingSetupProvider);
    final controller = ref.read(trainingSetupProvider.notifier);
    final theme = Theme.of(context);
    return AppPage(
      title: 'Your setup',
      subtitle: 'Good training starts with what you have.',
      action: FilledButton(onPressed: () => context.push('/focus'), child: const Text('Next: choose your focus')),
      children: [
        Text('Where are you training?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final option in LocationOption.values) ChoiceChip(label: Text(option.label), selected: option == setup.location, onSelected: (_) => controller.selectLocation(option))],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('How many pucks?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        const Text('We can make a single puck go a long way.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final option in PuckInventory.values) ChoiceChip(label: Text(option.label), selected: option == setup.inventory, onSelected: (_) => controller.selectInventory(option))],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Using a ball?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(label: const Text('No ball'), selected: setup.ball == null, onSelected: (_) => controller.selectBall(null)),
            for (final option in BallType.values) ChoiceChip(label: Text(option.label), selected: option == setup.ball, onSelected: (_) => controller.selectBall(option)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Have a passer?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(label: const Text('Training solo'), selected: setup.passer == null, onSelected: (_) => controller.selectPasser(null)),
            for (final option in PasserType.values) ChoiceChip(label: Text(option.label), selected: option == setup.passer, onSelected: (_) => controller.selectPasser(option)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Workouts currently use a sample plan. Equipment matching will be connected when workout generation is implemented.'),
      ],
    );
  }
}

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(trainingFocusProvider);
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return AppPage(
      title: 'Find your focus',
      subtitle: '100 points. Your priorities. Adjust one and the others rebalance.',
      action: FilledButton(onPressed: () => context.push('/routine'), child: const Text('View my workout')),
      children: [
        for (final pillar in SkillPillar.values) ...[
          Row(
            children: [
              Expanded(
                child: PillarTag(label: pillar.label, color: pillar.color(pillars)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${focus[pillar]}', style: theme.textTheme.headlineSmall),
            ],
          ),
          Slider(value: focus[pillar]!.toDouble(), min: 0, max: 100, divisions: 100, label: '${focus[pillar]}', activeColor: pillar.color(pillars), semanticFormatterCallback: (value) => '${pillar.label}, ${value.round()} of 100 focus points', onChanged: (value) => ref.read(trainingFocusProvider.notifier).select(pillar, value.round())),
          const SizedBox(height: AppSpacing.md),
        ],
        const TrainingCard(child: Text('A balanced foundation\nYour priorities will shape your workouts once generation is connected. For now, train with a sample six-drill plan.')),
      ],
    );
  }
}

class RoutinePage extends ConsumerWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Your workout',
      subtitle: 'Build your foundation',
      action: FilledButton.icon(
        onPressed: () {
          ref.read(trainingSessionProvider.notifier).start(sampleDrills);
          context.push('/session');
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start workout'),
      ),
      children: [
        const DrillMediaPlaceholder(title: 'Build your foundation'),
        const SizedBox(height: AppSpacing.md),
        Text('20 min · 6 drills · 12 sets', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('A little shooting, a little control, and a strong finish. Move at your own pace.'),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(onPressed: () => showFeatureMessage(context, 'Saved workouts are not connected yet. No workout was saved.'), icon: const Icon(Icons.bookmark_border), label: const Text('Save workout')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Workout plan'),
        const SizedBox(height: AppSpacing.md),
        for (final drill in sampleDrills) ...[DrillListCard(drillId: drill.id), const SizedBox(height: AppSpacing.sm)],
      ],
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  SkillPillar? _pillar;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Drill library',
    subtitle: 'Six sample drills. Real demos will replace these illustrations.',
    children: [
      const Text('Sample catalog · Filters shown for UX development; Pro access is not connected yet.'),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ChoiceChip(label: const Text('All drills'), selected: _pillar == null, onSelected: (_) => setState(() => _pillar = null)),
          for (final pillar in SkillPillar.values) ChoiceChip(label: Text(pillar.label), selected: _pillar == pillar, onSelected: (_) => setState(() => _pillar = pillar)),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      if (sampleDrills.where((drill) => _pillar == null || drill.pillar == _pillar).isEmpty) const TrainingCard(child: Text('No sample drills for this focus yet.\nTry All drills to explore the current fixtures.')),
      for (final drill in sampleDrills.where((drill) => _pillar == null || drill.pillar == _pillar)) ...[DrillListCard(drillId: drill.id), const SizedBox(height: AppSpacing.sm)],
    ],
  );
}

class DrillDetailPage extends ConsumerWidget {
  const DrillDetailPage({required this.drillId, super.key});

  final String drillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = sampleDrills.where((drill) => drill.id == drillId);
    if (matches.isEmpty) {
      return AppPage(
        title: 'Drill unavailable',
        action: OutlinedButton(onPressed: () => context.go('/library'), child: const Text('Go to drill library')),
        children: const [Text('This drill is unavailable. Return to the library to choose a drill.')],
      );
    }
    final drill = matches.single;
    final rest = ref.watch(drillRestSettingsProvider)[drill.id];
    final theme = Theme.of(context);
    return AppPage(
      title: 'Drill detail',
      action: FilledButton(
        onPressed: () {
          ref.read(trainingSessionProvider.notifier).start([drill]);
          context.push('/session');
        },
        child: const Text('Try this drill'),
      ),
      children: [
        DrillMediaPlaceholder(title: drill.title),
        const SizedBox(height: AppSpacing.xl),
        Text(drill.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            PillarTag(label: drill.pillar.label, color: drill.pillar.color(theme.extension<PillarColors>()!)),
            PillarTag(label: drill.trackingType.label, color: theme.extension<AppColors>()!.textSecondary),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Coach’s cues'),
        const SizedBox(height: AppSpacing.md),
        for (final (index, cue) in drill.formCues.indexed) ...[Text('${index + 1}. $cue', style: theme.textTheme.bodyLarge), const SizedBox(height: AppSpacing.md)],
        const SizedBox(height: AppSpacing.sm),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended sets', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('${drill.prescriptionLabel} · ${rest?.enabled == true ? '${rest!.seconds}s rest' : 'Rest off'}'),
              TextButton.icon(
                onPressed: () => showDrillRestSettings(context, drill),
                icon: const Icon(Icons.tune),
                label: const Text('Drill settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
