import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/coach/routine_generator.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';
import '../features/routines/profile_routine_repository.dart';
import '../features/teams/team_repository.dart';
import 'coach_state.dart';
import 'drill_picker.dart';
import 'drill_media_card.dart';
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
    final minutes = ref.watch(trainingLengthProvider);
    final presets = ref.watch(setupPresetsProvider);
    return AppPage(
      title: 'Your setup',
      subtitle: 'Great training starts with what you have.',
      action: FilledButton(onPressed: () => context.push('/focus'), child: const Text('Next: choose your focus')),
      children: [
        if (presets.isNotEmpty) ...[
          const SectionHeading(title: 'Your saved setups'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final preset in presets)
                InputChip(
                  label: Text(preset.name),
                  avatar: const Icon(Icons.bookmark_outline, size: 18),
                  deleteButtonTooltipMessage: 'Remove ${preset.name}',
                  onPressed: () => ref.read(setupPresetsProvider.notifier).apply(preset),
                  onDeleted: () => ref.read(setupPresetsProvider.notifier).remove(preset.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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
        const SectionHeading(title: 'How long?'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in routineLengthOptions) ChoiceChip(label: Text('$option min'), selected: option == minutes, onSelected: (_) => ref.read(trainingLengthProvider.notifier).select(option)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(onPressed: () => _savePreset(context, ref), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('Save this setup')),
        const SizedBox(height: AppSpacing.sm),
        const Text('We remember your last setup. Save it by name to switch between places, like Garage or Rink Tuesday.'),
      ],
    );
  }

  Future<void> _savePreset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(context: context, builder: (_) => const _PresetNameDialog());
    if (name == null) return;
    final problem = ref.read(setupPresetsProvider.notifier).save(name);
    messenger.showSnackBar(SnackBar(content: Text(problem ?? 'Saved "${name.trim()}".')));
  }
}

class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog();

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Name this setup'),
    content: TextField(
      controller: _name,
      autofocus: true,
      maxLength: maxPresetNameLength,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Name', hintText: 'Garage'),
      onSubmitted: (value) => Navigator.of(context).pop(value),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.of(context).pop(_name.text), child: const Text('Save')),
    ],
  );
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
                  Text('Move a slider and your workout changes with it.', style: theme.textTheme.bodyMedium),
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
        TrainingCard(
          child: switch (ref.watch(generatedRoutineProvider)) {
            AsyncData(:final value) when value.drills.isNotEmpty => Text('Your workout: ${value.drills.length} drills, about ${value.estimatedMinutes} minutes.'),
            AsyncData() => const Text('No drills fit this setup yet. Try another place or more pucks.'),
            _ => const Text('Building your workout…'),
          },
        ),
      ],
    );
  }
}

class RoutinePage extends ConsumerWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(generatedRoutineProvider);
    final focus = ref.watch(trainingFocusProvider);
    final setup = ref.watch(trainingSetupProvider);
    return AppPage(
      title: 'Your workout',
      subtitle: '${setup.location.label} · ${setup.inventory.label}${setup.passer == null ? '' : ' · with a ${setup.passer!.label.toLowerCase()}'}',
      children: switch (routine) {
        AsyncData(:final value) when value.drills.isEmpty => [
          const TrainingCard(child: Text('No drills fit this setup yet. Try another place, more pucks, or a ball or passer.')),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () => context.push('/setup'), child: const Text('Change my setup')),
        ],
        AsyncData(:final value) => [
          TrainingHeroCard(
            eyebrow: 'Your session',
            title: routineTitle(focus),
            detail: routineDetail(focus),
            metrics: [('${value.estimatedMinutes}', 'minutes'), (value.drills.length.toString().padLeft(2, '0'), 'drills'), ('${value.totalSets}', 'sets')],
            actionLabel: 'Start workout',
            onTap: () {
              ref.read(trainingSessionProvider.notifier).start(value.drills);
              context.go('/train/session');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(routineShuffleProvider.notifier).next([for (final d in value.drills) d.id]),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Try another'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(onPressed: () => _save(context, ref, value, focus), icon: const Icon(Icons.bookmark_border), label: const Text('Save workout')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeading(title: 'Workout plan'),
          const SizedBox(height: AppSpacing.md),
          for (final drill in value.drills) ...[DrillListCard(drill: drill), const SizedBox(height: AppSpacing.sm)],
        ],
        AsyncError() => [
          const TrainingCard(child: Text('We couldn\'t load the drills. Check your connection and try again.')),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () => ref.invalidate(drillCatalogProvider), child: const Text('Try again')),
        ],
        _ => const [Center(child: CircularProgressIndicator())],
      },
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref, GeneratedRoutine routine, Map<SkillPillar, int> focus) async {
    final messenger = ScaffoldMessenger.of(context);
    final library = ref.read(routineStoreProvider);
    final plan = RoutinePlan(id: 'workout-${clock.now().microsecondsSinceEpoch}', name: '${topPillar(focus).label} · ${routine.estimatedMinutes} min', drills: routine.drills);
    try {
      if (await library.isAtLimit()) {
        if (!context.mounted) return;
        final replace = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Replace a saved routine?'),
            children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('You can keep up to 3 saved routines. Pick one to replace with this workout.')),
              for (final saved in ref.read(allRoutinesProvider)) SimpleDialogOption(onPressed: () => Navigator.of(dialogContext).pop(saved.id), child: Text(saved.name)),
              SimpleDialogOption(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ],
          ),
        );
        if (replace == null) return;
        await library.replace(replace, plan);
      } else {
        await library.save(plan);
      }
      messenger.showSnackBar(SnackBar(content: Text('Saved "${plan.name}" to My routines.')));
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class RoutineLibraryPage extends ConsumerWidget {
  const RoutineLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(allRoutinesProvider);
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
                    OutlinedButton.icon(onPressed: () => _duplicate(context, ref, routine), icon: const Icon(Icons.copy_outlined), label: const Text('Duplicate')),
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

  Future<void> _duplicate(BuildContext context, WidgetRef ref, RoutinePlan routine) async {
    try {
      await ref.read(routineStoreProvider).save(RoutinePlan(id: 'routine-${DateTime.now().microsecondsSinceEpoch}', name: '${routine.name} copy', drills: routine.drills));
      if (context.mounted) showFeatureMessage(context, 'Duplicated "${routine.name}".');
    } on StateError catch (error) {
      if (context.mounted) showFeatureMessage(context, error.message);
    } on PlatformException catch (error) {
      if (context.mounted) showFeatureMessage(context, 'Couldn\'t duplicate routine: ${error.message ?? error.code}');
    }
  }

  Future<void> _deleteRoutine(BuildContext context, WidgetRef ref, RoutinePlan routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${routine.name}?'),
        content: Text(routine.id.startsWith(cloudRoutinePrefix) ? 'This removes the routine from your account.' : 'This removes the routine from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(routineStoreProvider).remove(routine.id);
    } on StateError catch (error) {
      if (context.mounted) showFeatureMessage(context, error.message);
    } on PlatformException catch (error) {
      if (context.mounted) showFeatureMessage(context, 'Couldn\'t delete routine: ${error.message ?? error.code}');
    }
  }
}

class RoutineBuilderPage extends ConsumerStatefulWidget {
  const RoutineBuilderPage({super.key, this.routineId, this.profileId});

  final String? routineId;

  /// Set when a parent builds or edits a routine on a child's profile, rather than on their own My routines.
  final String? profileId;

  @override
  ConsumerState<RoutineBuilderPage> createState() => _RoutineBuilderPageState();
}

class _RoutineBuilderPageState extends ConsumerState<RoutineBuilderPage> {
  static const _routineNames = ['Skills Builder', 'Game-day Tune-up', 'Off-ice Fundamentals', 'Custom Skills Session'];
  late final String _id;
  late String _name;
  late final List<Drill> _drills;
  late final TextEditingController _nameController;
  late bool _hydrated;
  var _missing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    RoutinePlan? existing;
    if (widget.routineId != null && widget.profileId == null) existing = ref.read(allRoutinesProvider).where((plan) => plan.id == widget.routineId).firstOrNull;
    _id = existing?.id ?? 'routine-${DateTime.now().microsecondsSinceEpoch}';
    _name = existing?.name ?? _routineNames.first;
    _nameController = TextEditingController(text: _name);
    _drills = [...?existing?.drills];
    // A routine on a child's profile arrives from the server, so it is filled in once it has loaded.
    _hydrated = widget.profileId == null || widget.routineId == null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Adults may name a routine freely, within a short limit; everyone else picks a style.
  bool get _freeName => ref.read(authStateProvider).value is SignedInAccount;

  Future<void> _addDrills() async {
    final chosen = await showDrillPicker(context, title: 'Add drills', excludeIds: _drills.map((drill) => drill.id).toSet());
    if (chosen != null && chosen.isNotEmpty && mounted) setState(() => _drills.addAll(chosen));
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _drills.length) return;
    setState(() => _drills.insert(to, _drills.removeAt(from)));
  }

  void _setSets(int index, int sets) {
    if (sets < 1 || sets > 12) return;
    final drill = _drills[index];
    setState(() => _drills[index] = drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: sets)));
  }

  Future<void> _save() async {
    if (_freeName) _name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (_drills.isEmpty) {
      setState(() => _error = 'Add at least one drill to this routine.');
      return;
    }
    if (_freeName && (_name.length < 2 || RegExp(r'[<>]').hasMatch(_name))) {
      setState(() => _error = 'Use a routine name between 2 and 40 characters, without < or >.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profileId = widget.profileId;
      if (profileId != null) {
        final shared = TeamRoutine(name: _name, drills: [for (final drill in _drills) (drillId: drill.id, sets: drill.defaultPrescription.sets)]);
        await ref.read(profileRoutineRepositoryProvider).save(profileId, shared, routineId: widget.routineId);
        if (mounted) context.go('/parent/kids/$profileId/routines');
        return;
      }
      await ref.read(routineStoreProvider).save(RoutinePlan(id: _id, name: _name, drills: _drills));
      if (mounted) context.go('/routines');
    } on RoutineException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
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
    if (!_hydrated) {
      final saved = ref.watch(profileRoutinesProvider(widget.profileId!));
      final catalog = ref.watch(drillCatalogProvider);
      if (saved.hasValue && catalog.hasValue) {
        final item = saved.requireValue.where((entry) => entry.id == widget.routineId).firstOrNull;
        _hydrated = true;
        if (item == null) {
          _missing = true;
        } else {
          _name = item.routine.name;
          _nameController.text = _name;
          _drills.addAll(drillsForTeamRoutine(item.routine, catalog.requireValue));
        }
      } else {
        return const AppPage(
          title: 'Edit routine',
          children: [Center(child: CircularProgressIndicator())],
        );
      }
    }
    if (_missing) {
      return AppPage(
        title: 'Routine not found',
        action: FilledButton(onPressed: () => context.go('/parent/kids/${widget.profileId}/routines'), child: const Text('Back to Routines')),
        children: const [Text('This routine was deleted.')],
      );
    }
    final pillars = theme.extension<PillarColors>()!;
    return AppPage(
      title: widget.routineId == null ? 'Create routine' : 'Edit routine',
      subtitle: _freeName ? 'Name it, then add drills in the order you like.' : 'Pick a routine style, then add drills in the order you like.',
      action: FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving…' : 'Save routine')),
      children: [
        if (_freeName) ...[
          TextField(
            key: const ValueKey('routine-name'),
            controller: _nameController,
            enabled: !_saving,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Routine name'),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [for (final name in _routineNames) ActionChip(label: Text(name), onPressed: _saving ? null : () => setState(() => _nameController.text = name))],
          ),
        ] else
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _name,
            decoration: const InputDecoration(labelText: 'Routine style'),
            // A routine saved under another name (the starter routine, a copy, or one made from history) keeps it.
            items: [
              for (final name in {..._routineNames, _name}) DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: _saving ? null : (value) => setState(() => _name = value!),
          ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Drills (${_drills.length})'),
        const SizedBox(height: AppSpacing.sm),
        for (final (index, drill) in _drills.indexed) ...[
          TrainingCard(
            key: ValueKey('routine-drill-${drill.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(drill.pillar.icon, color: drill.pillar.color(pillars)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text('${index + 1}. ${drill.title}\n${drill.prescriptionLabel}')),
                    IconButton(tooltip: 'Remove ${drill.title}', onPressed: () => setState(() => _drills.removeAt(index)), icon: const Icon(Icons.remove_circle_outline)),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Fewer sets for ${drill.title}',
                      onPressed: drill.defaultPrescription.sets > 1 ? () => _setSets(index, drill.defaultPrescription.sets - 1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${drill.defaultPrescription.sets} sets'),
                    IconButton(
                      tooltip: 'More sets for ${drill.title}',
                      onPressed: drill.defaultPrescription.sets < 12 ? () => _setSets(index, drill.defaultPrescription.sets + 1) : null,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(tooltip: 'Move ${drill.title} up', onPressed: index > 0 ? () => _move(index, index - 1) : null, icon: const Icon(Icons.arrow_upward)),
                    IconButton(tooltip: 'Move ${drill.title} down', onPressed: index < _drills.length - 1 ? () => _move(index, index + 1) : null, icon: const Icon(Icons.arrow_downward)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        FilledButton.tonalIcon(onPressed: _addDrills, icon: const Icon(Icons.add), label: const Text('Add drills')),
        if (_error != null) ...[const SizedBox(height: AppSpacing.md), Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))],
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.profileId != null || (ref.watch(authStateProvider).value is SignedInAccount && !_drills.any((d) => d.id.startsWith('custom-') || d.id.startsWith('manual-')))
              ? 'Saved to the account, so it follows the player to any device.'
              : 'Routines with your own drills are saved on this device.',
        ),
      ],
    );
  }
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
        DrillMediaCard.forDrill(drill),
        const SizedBox(height: AppSpacing.xl),
        Text(drill.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            PillarTag(label: drill.pillar.label, color: drill.pillar.color(theme.extension<PillarColors>()!)),
            if (drill.trackingType.label != drill.pillar.label) PillarTag(label: drill.trackingType.label, color: theme.extension<AppColors>()!.textSecondary),
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
