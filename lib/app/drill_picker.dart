import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';
import 'routine_state.dart';
import 'sample_data.dart';
import 'workout_sync.dart';

/// Opens the one drill picker used for routines and live workouts. Returns the drills chosen, or
/// null if the player backed out. Drills in [excludeIds] aren't offered.
Future<List<Drill>?> showDrillPicker(
  BuildContext context, {
  required String title,
  Set<String> excludeIds = const {},
  bool single = false,
  List<Drill> suggested = const [],
  String? noSuggestionsNote,
}) => showModalBottomSheet<List<Drill>>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => DrillPickerSheet(title: title, excludeIds: excludeIds, single: single, suggested: suggested, noSuggestionsNote: noSuggestionsNote),
);

class DrillPickerSheet extends ConsumerStatefulWidget {
  const DrillPickerSheet({required this.title, this.excludeIds = const {}, this.single = false, this.suggested = const [], this.noSuggestionsNote, super.key});

  final String title;
  final Set<String> excludeIds;
  final bool single;

  /// Drills that fit the moment, such as same-skill swaps that suit the player's setup. Shown first.
  final List<Drill> suggested;

  /// Shown instead of a Suggested section when [suggested] is empty, to say why.
  final String? noSuggestionsNote;

  @override
  ConsumerState<DrillPickerSheet> createState() => _DrillPickerSheetState();
}

class _DrillPickerSheetState extends ConsumerState<DrillPickerSheet> {
  final _search = TextEditingController();
  final _selected = <String, Drill>{};
  SkillPillar? _pillar;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Drill drill) {
    if (widget.excludeIds.contains(drill.id)) return false;
    if (_pillar != null && drill.pillar != _pillar) return false;
    final query = _search.text.trim().toLowerCase();
    return query.isEmpty || drill.title.toLowerCase().contains(query) || drill.pillar.label.toLowerCase().contains(query);
  }

  void _toggle(Drill drill, bool on) {
    if (widget.single) {
      Navigator.of(context).pop([drill]);
      return;
    }
    setState(() {
      if (on) {
        _selected[drill.id] = drill;
      } else {
        _selected.remove(drill.id);
      }
    });
  }

  Future<void> _create() async {
    final mine = ref.read(customDrillLibraryProvider);
    final drill = await showTemplateDrillSheet(context, existingTitles: mine.map((item) => item.title));
    if (drill == null || !mounted) return;
    try {
      await ref.read(customDrillLibraryProvider.notifier).add(drill);
    } on StateError catch (error) {
      setState(() => _error = error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _error = null);
    _toggle(drill, true);
  }

  Future<void> _delete(Drill drill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${drill.title}?'),
        content: const Text('This removes it from My drills. Routines and workouts that already use it keep it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(customDrillLibraryProvider.notifier).remove(drill.id);
    if (mounted) setState(() => _selected.remove(drill.id));
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _tile(Drill drill, {bool deletable = false}) {
    final pillars = Theme.of(context).extension<PillarColors>()!;
    final subtitle = '${drill.pillar.label} · ${drill.prescriptionLabel}';
    final icon = Icon(drill.pillar.icon, color: drill.pillar.color(pillars));
    final Widget tile = widget.single
        ? ListTile(key: ValueKey('picker-drill-${drill.id}'), contentPadding: EdgeInsets.zero, leading: icon, title: Text(drill.title), subtitle: Text(subtitle), onTap: () => _toggle(drill, true))
        : CheckboxListTile(
            key: ValueKey('picker-drill-${drill.id}'),
            contentPadding: EdgeInsets.zero,
            value: _selected.containsKey(drill.id),
            onChanged: (on) => _toggle(drill, on ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
            secondary: icon,
            title: Text(drill.title),
            subtitle: Text(subtitle),
          );
    if (!deletable) return tile;
    return Row(
      children: [
        Expanded(child: tile),
        IconButton(tooltip: 'Delete ${drill.title}', onPressed: () => _delete(drill), icon: const Icon(Icons.delete_outline)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = ref.watch(drillCatalogProvider);
    final pro = ref.watch(drillFiltersUnlockedProvider);
    final suggested = widget.suggested.where(_matches).toList();
    final mine = ref.watch(customDrillLibraryProvider).where((drill) => _matches(drill) && !suggested.any((s) => s.id == drill.id)).toList();
    final shown = {...suggested.map((drill) => drill.id), ...mine.map((drill) => drill.id)};
    final recent = <Drill>[];
    for (final workout in ref.watch(playerHistoryProvider)) {
      for (final drill in workout.drills) {
        if (recent.length < 6 && !shown.contains(drill.id) && _matches(drill)) {
          recent.add(drill);
          shown.add(drill.id);
        }
      }
    }
    final library = [
      for (final drill in catalog.value == null ? const <Drill>[] : visibleDrills(catalog.value!, pro: pro))
        if (!shown.contains(drill.id) && _matches(drill)) drill,
    ];
    final empty = suggested.isEmpty && mine.isEmpty && recent.isEmpty && library.isEmpty;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(widget.title, style: theme.textTheme.headlineSmall),
                TextButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Create drill')),
              ],
            ),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search drills'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(label: const Text('All skills'), selected: _pillar == null, onSelected: (_) => setState(() => _pillar = null)),
                  ),
                  for (final pillar in SkillPillar.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(label: Text(pillar.label), selected: _pillar == pillar, onSelected: (on) => setState(() => _pillar = on ? pillar : null)),
                    ),
                ],
              ),
            ),
            if (_error != null) Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            if (widget.suggested.isEmpty && widget.noSuggestionsNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(widget.noSuggestionsNote!),
              ),
            Expanded(
              child: ListView(
                key: const ValueKey('drill-picker-list'),
                children: [
                  if (suggested.isNotEmpty) ...[_heading('Suggested'), for (final drill in suggested) _tile(drill)],
                  if (mine.isNotEmpty) ...[_heading('My drills'), for (final drill in mine) _tile(drill, deletable: true)],
                  if (recent.isNotEmpty) ...[_heading('Recent'), for (final drill in recent) _tile(drill)],
                  if (library.isNotEmpty) ...[_heading('Drill library'), for (final drill in library) _tile(drill)],
                  if (catalog.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (catalog.hasError) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Text('We couldn\'t load the drill library. You can still use My drills.')),
                  if (empty && !catalog.isLoading) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Text('No drills match. Clear the search, or create a drill.')),
                ],
              ),
            ),
            if (!widget.single)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.values.toList()),
                  child: Text(_selected.isEmpty ? 'Choose drills' : 'Add ${_selected.length} ${_selected.length == 1 ? 'drill' : 'drills'}'),
                ),
              ),
            if (widget.single) const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Builds a reusable drill from structured choices only: a skill, how it is measured, sets, a target and rest.
Future<Drill?> showTemplateDrillSheet(BuildContext context, {Iterable<String> existingTitles = const []}) => showModalBottomSheet<Drill>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _TemplateDrillSheet(existingTitles: existingTitles.toList()),
);

String _measureHelp(TrackingType type) => switch (type) {
  TrackingType.volume => 'Count reps each set.',
  TrackingType.accuracy => 'Count shots and how many hit the target.',
  TrackingType.duration => 'A timer for each set.',
  TrackingType.streak => 'Record your longest streak.',
  TrackingType.binary => 'Mark each set done or not done.',
  TrackingType.density => '',
};

class _TemplateDrillSheet extends StatefulWidget {
  const _TemplateDrillSheet({required this.existingTitles});

  final List<String> existingTitles;

  @override
  State<_TemplateDrillSheet> createState() => _TemplateDrillSheetState();
}

class _TemplateDrillSheetState extends State<_TemplateDrillSheet> {
  SkillPillar _pillar = SkillPillar.hands;
  TrackingType _type = TrackingType.volume;
  int _sets = 3;
  int _reps = 10;
  int _seconds = 30;
  int _rest = 45;

  Drill get _preview => createTemplateDrill(_pillar, sets: _sets, reps: _reps, seconds: _seconds, restSeconds: _rest, trackingType: _type, existingTitles: widget.existingTitles);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counted = _type == TrackingType.volume || _type == TrackingType.accuracy;
    final preview = _preview;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create a drill', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<SkillPillar>(
            isExpanded: true,
            initialValue: _pillar,
            decoration: const InputDecoration(labelText: 'Skill focus'),
            items: [for (final pillar in SkillPillar.values) DropdownMenuItem(value: pillar, child: Text(pillar.label))],
            onChanged: (value) => setState(() => _pillar = value!),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('How do you track it?', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [for (final type in templateTrackingTypes) ChoiceChip(label: Text(type.label), selected: _type == type, onSelected: (_) => setState(() => _type = type))],
          ),
          Text(_measureHelp(_type), style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text('Sets: $_sets'),
          Slider(value: _sets.toDouble(), min: 1, max: 6, divisions: 5, label: '$_sets', onChanged: (value) => setState(() => _sets = value.round())),
          if (counted) ...[
            Text(_type == TrackingType.accuracy ? 'Shots per set: $_reps' : 'Reps per set: $_reps'),
            Slider(value: _reps.toDouble(), min: 5, max: 30, divisions: 5, label: '$_reps', onChanged: (value) => setState(() => _reps = value.round())),
          ],
          if (_type == TrackingType.duration) ...[
            Text('Seconds per set: $_seconds'),
            Slider(value: _seconds.toDouble(), min: 10, max: 120, divisions: 11, label: '$_seconds', onChanged: (value) => setState(() => _seconds = value.round())),
          ],
          Text('Rest between sets: ${_rest}s'),
          Slider(value: _rest.toDouble(), min: 15, max: 120, divisions: 7, label: '$_rest', onChanged: (value) => setState(() => _rest = value.round())),
          const SizedBox(height: AppSpacing.xs),
          Text('${preview.title} · ${preview.prescriptionLabel}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () => Navigator.pop(context, preview), child: const Text('Save to My drills')),
        ],
      ),
    );
  }
}
