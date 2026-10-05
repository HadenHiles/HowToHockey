import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'routine_state.dart';
import 'session_pages.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(trainingSetupProvider);
    final controller = ref.read(trainingSetupProvider.notifier);
    return AppPage(
      title: 'Your setup',
      subtitle: 'Good training starts with what you have.',
      action: FilledButton(onPressed: () => context.push('/focus'), child: const Text('Next: choose your focus')),
      children: [
        const SectionHeading(title: 'Where are you training?'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final option in LocationOption.values) ChoiceChip(label: Text(option.label), selected: option == setup.location, onSelected: (_) => controller.selectLocation(option))],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'How many pucks?'),
        const SizedBox(height: AppSpacing.xs),
        const Text('We can make a single puck go a long way.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final option in PuckInventory.values) ChoiceChip(label: Text(option.label), selected: option == setup.inventory, onSelected: (_) => controller.selectInventory(option))],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Using a ball?'),
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
        const SectionHeading(title: 'Have a passer?'),
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
        ArenaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: AppSpacing.md),
              Text('BUILD A SMARTER SESSION', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
              const SizedBox(height: AppSpacing.xs),
              Text('Your game.\nYour focus.', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Set priorities for a sample plan. Workout generation is coming later.', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Skill priorities'),
        const SizedBox(height: AppSpacing.md),
        for (final pillar in SkillPillar.values) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
    return AppPage(
      title: 'Your workout',
      subtitle: 'Build your foundation',
      children: [
        TrainingHeroCard(
          eyebrow: 'Your session',
          title: 'Build your\nfoundation',
          detail: 'A little shooting, a little control, and a strong finish.',
          metrics: const [('20', 'minutes'), ('06', 'drills'), ('12', 'sets')],
          actionLabel: 'Start workout',
          onTap: () {
            ref.read(trainingSessionProvider.notifier).start(sampleDrills);
            context.push('/session');
          },
        ),
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

class RoutineLibraryPage extends ConsumerWidget {
  const RoutineLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routineLibraryProvider);
    final theme = Theme.of(context);
    return AppPage(
      title: 'My routines',
      subtitle: 'Build sessions from the drill library or create a drill from a skill template.',
      action: FilledButton.icon(onPressed: () => context.push('/routines/new'), icon: const Icon(Icons.add), label: const Text('Create routine')),
      children: [
        for (final routine in routines) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('${routine.drills.length} drills · ${routine.drills.fold<int>(0, (seconds, drill) => seconds + drill.estimatedSecondsPerSet * drill.defaultPrescription.sets) ~/ 60} min estimated'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(onPressed: () => context.push('/routines/${routine.id}/edit'), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                    FilledButton.icon(
                      onPressed: routine.drills.isEmpty
                          ? null
                          : () {
                              ref.read(trainingSessionProvider.notifier).start(routine.drills);
                              context.push('/session');
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                    if (routine.id != 'foundation') IconButton(tooltip: 'Delete ${routine.name}', onPressed: () => _deleteRoutine(context, ref, routine), icon: const Icon(Icons.delete_outline)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (routines.isEmpty) const TrainingCard(child: Text('No saved routines yet. Create one to get started.')),
      ],
    );
  }

  Future<void> _deleteRoutine(BuildContext context, WidgetRef ref, RoutinePlan routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${routine.name}?'),
        content: const Text('This removes the saved routine from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(routineLibraryProvider.notifier).remove(routine.id);
    } on StateError catch (error) {
      if (context.mounted) showFeatureMessage(context, error.message);
    } on PlatformException catch (error) {
      if (context.mounted) showFeatureMessage(context, 'Could not delete routine: ${error.message ?? error.code}');
    }
  }
}

class RoutineBuilderPage extends ConsumerStatefulWidget {
  const RoutineBuilderPage({super.key, this.routineId});

  final String? routineId;

  @override
  ConsumerState<RoutineBuilderPage> createState() => _RoutineBuilderPageState();
}

class _RoutineBuilderPageState extends ConsumerState<RoutineBuilderPage> {
  static const _routineNames = ['Skills Builder', 'Game-day Tune-up', 'Off-ice Fundamentals', 'Custom Skills Session'];
  late final String _id;
  late String _name;
  late final List<Drill> _drills;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plans = ref.read(routineLibraryProvider);
    final existing = widget.routineId == null ? null : plans.where((plan) => plan.id == widget.routineId).firstOrNull;
    _id = existing?.id ?? 'routine-${DateTime.now().microsecondsSinceEpoch}';
    _name = existing?.name ?? _routineNames.first;
    _drills = [...?existing?.drills];
  }

  void _toggleDrill(Drill drill, bool selected) {
    setState(() {
      _drills.removeWhere((item) => item.id == drill.id);
      if (selected) _drills.add(drill);
    });
  }

  Future<void> _createDrill() async {
    final drill = await showModalBottomSheet<Drill>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _TemplateDrillSheet());
    if (drill != null && mounted) setState(() => _drills.add(drill));
  }

  Future<void> _save() async {
    if (_drills.isEmpty) {
      setState(() => _error = 'Add at least one drill to this routine.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // TODO(RevenueCat): Enforce the Phase 5 three-routine free-tier cap and Player Pro entitlement here.
      await ref.read(routineLibraryProvider.notifier).save(RoutinePlan(id: _id, name: _name, drills: _drills));
      if (mounted) context.go('/routines');
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save routine: ${error.message ?? error.code}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return AppPage(
      title: widget.routineId == null ? 'Create routine' : 'Edit routine',
      subtitle: 'Choose a routine style, then add drills in your preferred order.',
      action: FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving…' : 'Save routine')),
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _name,
          decoration: const InputDecoration(labelText: 'Routine style'),
          items: [for (final name in _routineNames) DropdownMenuItem(value: name, child: Text(name))],
          onChanged: _saving ? null : (value) => setState(() => _name = value!),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Drills (${_drills.length})'),
        const SizedBox(height: AppSpacing.sm),
        for (final drill in _drills.indexed) ...[
          TrainingCard(
            child: Row(
              children: [
                Icon(drill.$2.pillar.icon, color: drill.$2.pillar.color(pillars)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('${drill.$1 + 1}. ${drill.$2.title}\n${drill.$2.prescriptionLabel}')),
                IconButton(tooltip: 'Remove ${drill.$2.title}', onPressed: () => setState(() => _drills.removeAt(drill.$1)), icon: const Icon(Icons.remove_circle_outline)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        OutlinedButton.icon(onPressed: _createDrill, icon: const Icon(Icons.auto_awesome), label: const Text('Create a drill from a template')),
        const SizedBox(height: AppSpacing.sm),
        const SectionHeading(title: 'Add from drill library'),
        const SizedBox(height: AppSpacing.sm),
        for (final drill in sampleDrills) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _drills.any((item) => item.id == drill.id),
            title: Text(drill.title),
            subtitle: Text('${drill.pillar.label} · ${drill.prescriptionLabel}'),
            secondary: Icon(drill.pillar.icon, color: drill.pillar.color(pillars)),
            onChanged: (selected) => _toggleDrill(drill, selected ?? false),
          ),
          const Divider(height: 1),
        ],
        if (_error != null) ...[const SizedBox(height: AppSpacing.md), Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))],
        const SizedBox(height: AppSpacing.md),
        const Text('Routine changes and template drills are saved on this device. Cloud sync and entitlement checks will be connected with the routine and RevenueCat milestones.'),
      ],
    );
  }
}

class _TemplateDrillSheet extends StatefulWidget {
  const _TemplateDrillSheet();

  @override
  State<_TemplateDrillSheet> createState() => _TemplateDrillSheetState();
}

class _TemplateDrillSheetState extends State<_TemplateDrillSheet> {
  SkillPillar _pillar = SkillPillar.hands;
  int _sets = 2;
  int _reps = 10;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create a drill', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<SkillPillar>(
            isExpanded: true,
            initialValue: _pillar,
            decoration: const InputDecoration(labelText: 'Skill focus'),
            items: [for (final pillar in SkillPillar.values) DropdownMenuItem(value: pillar, child: Text(pillar.label))],
            onChanged: (value) => setState(() => _pillar = value!),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Sets: $_sets'),
          Slider(value: _sets.toDouble(), min: 1, max: 6, divisions: 5, label: '$_sets', onChanged: (value) => setState(() => _sets = value.round())),
          Text('Reps per set: $_reps'),
          Slider(value: _reps.toDouble(), min: 5, max: 30, divisions: 5, label: '$_reps', onChanged: (value) => setState(() => _reps = value.round())),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.pop(context, createTemplateDrill(_pillar, sets: _sets, reps: _reps)),
            child: const Text('Add drill'),
          ),
        ],
      ),
    ),
  );
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
              TextButton.icon(onPressed: () => showDrillRestSettings(context, drill), icon: const Icon(Icons.tune), label: const Text('Drill settings')),
            ],
          ),
        ),
      ],
    );
  }
}
