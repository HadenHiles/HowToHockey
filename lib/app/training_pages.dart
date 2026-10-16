import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_catalog.dart';
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
      subtitle: 'Great training starts with what you have.',
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
        const Text('One puck is plenty. We\'ll make it count.'),
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
        const Text('For now, workouts use an example plan. Matching drills to your gear is coming soon.'),
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
      subtitle: '100 points. Your priorities. Move one and the others adjust.',
      action: FilledButton(onPressed: () => context.push('/routine'), child: const Text('View my workout')),
      children: [
        ArenaPanel(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tune, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(height: AppSpacing.md),
                  Text('BUILD A BETTER SESSION', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Your game.\nYour focus.', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Set your priorities. Custom workouts are coming soon.', style: theme.textTheme.bodyMedium),
                ],
              );
            },
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
                Slider(
                  value: focus[pillar]!.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${focus[pillar]}',
                  activeColor: pillar.color(pillars),
                  semanticFormatterCallback: (value) => '${pillar.label}, ${value.round()} of 100 focus points',
                  onChanged: (value) => ref.read(trainingFocusProvider.notifier).select(pillar, value.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const TrainingCard(child: Text('A balanced foundation\nSoon your priorities will shape your workouts. For now, train with an example six-drill plan.')),
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
            context.go('/train/session');
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => showFeatureMessage(context, 'Saving workouts isn\'t live yet. No workout was saved.'),
          icon: const Icon(Icons.bookmark_border),
          label: const Text('Save workout'),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Workout plan'),
        const SizedBox(height: AppSpacing.md),
        for (final drill in sampleDrills) ...[DrillListCard(drill: drill), const SizedBox(height: AppSpacing.sm)],
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
      subtitle: 'Build sessions from the drill library, or start from a skill template.',
      action: FilledButton.icon(onPressed: () => context.push('/routines/new'), icon: const Icon(Icons.add), label: const Text('Create routine')),
      children: [
        for (final routine in routines) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${routine.drills.length} drills · ${routine.drills.fold<int>(0, (seconds, drill) => seconds + drill.estimatedSecondsPerSet * drill.defaultPrescription.sets) ~/ 60} min estimated',
                ),
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
                              context.go('/train/session');
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
        if (routines.isEmpty) const TrainingCard(child: Text('No routines yet. Create one and it shows up here.')),
      ],
    );
  }

  Future<void> _deleteRoutine(BuildContext context, WidgetRef ref, RoutinePlan routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${routine.name}?'),
        content: const Text('This removes the routine from this device.'),
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
      if (context.mounted) showFeatureMessage(context, 'Couldn\'t delete routine: ${error.message ?? error.code}');
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
          _error = 'Couldn\'t save routine: ${error.message ?? error.code}';
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
      subtitle: 'Pick a routine style, then add drills in the order you like.',
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
        ...ref
            .watch(drillCatalogProvider)
            .when(
              data: (catalog) => [
                for (final drill in visibleDrills(catalog, pro: ref.watch(drillFiltersUnlockedProvider))) ...[
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
              ],
              loading: () => const [
                Center(
                  child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => const [Text('We couldn\'t load the drill library. Close this screen and try again.')],
            ),
        if (_error != null) ...[const SizedBox(height: AppSpacing.md), Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))],
        const SizedBox(height: AppSpacing.md),
        const Text('Routines and template drills are saved on this device. Cloud sync and plan checks are coming soon.'),
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

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  var _filters = const DrillFilters();

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(drillCatalogProvider);
    final pro = ref.watch(drillFiltersUnlockedProvider);
    return AppPage(
      title: 'Drill library',
      subtitle: catalog.maybeWhen(
        data: (drills) => '${visibleDrills(drills, pro: pro).length} drills to work on, on or off the ice. Coach Jeremy\'s video demos are coming soon.',
        orElse: () => 'Drills to work on, on or off the ice.',
      ),
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text('All drills'),
              selected: _filters.pillar == null,
              onSelected: (_) => setState(() => _filters = _filters.copyWith(pillar: () => null)),
            ),
            for (final pillar in SkillPillar.values)
              ChoiceChip(
                label: Text(pillar.label),
                selected: _filters.pillar == pillar,
                onSelected: (_) => setState(() => _filters = _filters.copyWith(pillar: () => pillar)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => _showFilters(pro), icon: Icon(pro ? Icons.tune : Icons.lock_outline), label: Text(_filters.hasDetailedFilters ? 'Filters on' : 'Filters')),
        ),
        const SizedBox(height: AppSpacing.md),
        ...catalog.when(
          data: (drills) {
            final shown = applyDrillFilters(
              visibleDrills(drills, pro: pro),
              pro ? _filters : _filters.copyWith(location: () => null, puckInventory: () => null, ball: () => null, passer: () => null, trackingType: () => null),
            );
            if (shown.isEmpty) {
              return [
                TrainingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No drills match yet.\nTry fewer filters to see more.'),
                      TextButton(onPressed: () => setState(() => _filters = const DrillFilters()), child: const Text('Clear filters')),
                    ],
                  ),
                ),
              ];
            }
            return [
              for (final drill in shown) ...[DrillListCard(drill: drill), const SizedBox(height: AppSpacing.sm)],
            ];
          },
          loading: () => const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(semanticsLabel: 'Loading drills'),
              ),
            ),
          ],
          error: (_, _) => [
            TrainingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('We couldn\'t load the drill library.'),
                  TextButton(onPressed: () => ref.invalidate(drillCatalogProvider), child: const Text('Try again')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showFilters(bool pro) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        void update(DrillFilters next) {
          setState(() => _filters = next);
          setSheetState(() {});
        }

        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Find the right drill', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                if (!pro) ...[
                  const Text('Filter by where you train, the pucks you have, the balls you use, and who can pass. Filters are part of Player Pro.'),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/paywall');
                    },
                    child: const Text('See Player Pro'),
                  ),
                ] else ...[
                  const Text('Show only drills that fit your setup.'),
                  const SizedBox(height: AppSpacing.md),
                  _FilterGroup<LocationOption>(
                    title: 'Where you train',
                    values: LocationOption.values,
                    selected: _filters.location,
                    label: (v) => v.label,
                    onChanged: (v) => update(_filters.copyWith(location: () => v)),
                  ),
                  _FilterGroup<PuckInventory>(
                    title: 'Pucks you have',
                    values: PuckInventory.values,
                    selected: _filters.puckInventory,
                    label: (v) => v.label,
                    onChanged: (v) => update(_filters.copyWith(puckInventory: () => v)),
                  ),
                  _FilterGroup<BallType>(
                    title: 'Ball',
                    values: BallType.values,
                    selected: _filters.ball,
                    label: (v) => v.label,
                    onChanged: (v) => update(_filters.copyWith(ball: () => v)),
                  ),
                  _FilterGroup<PasserType>(
                    title: 'Passer',
                    values: PasserType.values,
                    selected: _filters.passer,
                    label: (v) => v.label,
                    onChanged: (v) => update(_filters.copyWith(passer: () => v)),
                  ),
                  _FilterGroup<TrackingType>(
                    title: 'How you track it',
                    values: TrackingType.values,
                    selected: _filters.trackingType,
                    label: (v) => v.label,
                    onChanged: (v) => update(_filters.copyWith(trackingType: () => v)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(onPressed: () => update(const DrillFilters()), child: const Text('Clear filters')),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _FilterGroup<T> extends StatelessWidget {
  const _FilterGroup({required this.title, required this.values, required this.selected, required this.label, required this.onChanged});

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final value in values) ChoiceChip(label: Text(label(value)), selected: selected == value, onSelected: (on) => onChanged(on ? value : null))],
        ),
      ],
    ),
  );
}

class DrillDetailPage extends ConsumerWidget {
  const DrillDetailPage({required this.drillId, this.fromSession = false, super.key});

  final String drillId;
  final bool fromSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drills = fromSession ? ref.watch(trainingSessionProvider).drills : [...?ref.watch(drillCatalogProvider).value, ...sampleDrills];
    if (!fromSession && ref.watch(drillCatalogProvider).isLoading) {
      return const AppPage(
        title: 'Drill detail',
        children: [Center(child: CircularProgressIndicator(semanticsLabel: 'Loading drill'))],
      );
    }
    final matches = drills.where((drill) => drill.id == drillId).take(1);
    if (matches.isEmpty) {
      return AppPage(
        title: 'Drill not found',
        action: OutlinedButton(onPressed: () => fromSession ? context.pop() : context.go('/library'), child: Text(fromSession ? 'Back to workout' : 'Go to drill library')),
        children: [Text(fromSession ? 'This drill is no longer in the workout.' : 'We can\'t find this drill. Head back to the library and pick another.')],
      );
    }
    final drill = matches.first;
    final rest = ref.watch(drillRestSettingsProvider)[drill.id];
    final theme = Theme.of(context);
    return AppPage(
      title: 'Drill detail',
      action: fromSession
          ? FilledButton(onPressed: () => context.pop(), child: const Text('Back to workout'))
          : FilledButton(
              onPressed: () {
                ref.read(trainingSessionProvider.notifier).start([drill]);
                context.go('/train/session');
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
