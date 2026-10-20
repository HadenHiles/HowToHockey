import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/drill_swap.dart';
import '../features/drills/models/drill.dart';
import '../features/drills/set_calculations.dart';
import 'drill_picker.dart';
import 'sample_data.dart';
import 'training_state.dart';
import 'workout_sync.dart';

enum _DrillMenu { details, focus, rest, moveUp, moveDown, replace, removeSet, endEarly, remove }

typedef _Values = ({int? reps, int? hits, int? seconds, int? streak, bool? completed});

/// One input column of a set row: its heading and which value it fills.
typedef _Field = ({String label, String key});

List<_Field> _fieldsFor(TrackingType type) => switch (type) {
  TrackingType.volume => const [(label: 'REPS', key: 'reps')],
  TrackingType.accuracy => const [(label: 'SHOTS', key: 'reps'), (label: 'HITS', key: 'hits')],
  TrackingType.duration => const [(label: 'SECONDS', key: 'seconds')],
  TrackingType.density => const [(label: 'SHOTS', key: 'reps'), (label: 'SECONDS', key: 'seconds')],
  TrackingType.streak => const [(label: 'STREAK', key: 'streak')],
  TrackingType.binary => const [],
};

/// A short result for the PREVIOUS column, for example `6/10` or `30s`.
String _compact(SetLog log, TrackingType type) => switch (type) {
  TrackingType.volume => '${log.reps ?? 0}',
  TrackingType.accuracy => '${log.hits ?? 0}/${log.reps ?? 0}',
  TrackingType.duration => '${log.seconds ?? 0}s',
  TrackingType.density => '${log.reps ?? 0} in ${log.seconds ?? 0}s',
  TrackingType.streak => '${log.streak ?? 0}',
  TrackingType.binary => (log.completed ?? false) ? 'Done' : '–',
};

String? _valueText(SetLog? log, String key) {
  final value = switch (key) {
    'reps' => log?.reps,
    'hits' => log?.hits,
    'seconds' => log?.seconds,
    'streak' => log?.streak,
    _ => null,
  };
  return value?.toString();
}

/// The workout as one scrolling list: every drill with a compact table of sets, logged in place.
/// Logging, correcting and undoing happen on the set rows; everything else sits behind each drill's
/// menu. Logged results are never dropped by an edit; ending a drill early keeps what was logged.
class WorkoutOverview extends ConsumerWidget {
  const WorkoutOverview({required this.session, required this.onFocus, required this.onDetails, required this.onRest, required this.onEdited, super.key});

  final TrainingSession session;
  final ValueChanged<int> onFocus;
  final ValueChanged<Drill> onDetails;
  final ValueChanged<Drill> onRest;

  /// Called after a change that can move the selected drill, so the drill pages can follow.
  final VoidCallback onEdited;

  Future<void> _run(BuildContext context, void Function() action) async {
    try {
      action();
      onEdited();
    } on StateError catch (error) {
      await _tell(context, error.message);
    } on ArgumentError catch (error) {
      await _tell(context, '${error.message}');
    }
  }

  Future<void> _tell(BuildContext context, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );

  Future<bool> _confirm(BuildContext context, String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _addDrills(BuildContext context, WidgetRef ref) async {
    final chosen = await showDrillPicker(context, title: 'Add drills', excludeIds: session.drills.map((drill) => drill.id).toSet());
    if (chosen == null || chosen.isEmpty || !context.mounted) return;
    await _run(context, () => ref.read(trainingSessionProvider.notifier).addDrills(chosen));
  }

  Future<void> _replace(BuildContext context, WidgetRef ref, int index) async {
    final taken = session.drills.map((drill) => drill.id).toSet();
    final suggested = swapCandidates(
      current: session.drills[index],
      catalog: visibleDrills(ref.read(drillCatalogProvider).value ?? const <Drill>[], pro: ref.read(drillFiltersUnlockedProvider)),
      alreadyInWorkout: taken,
      setup: ref.read(trainingSetupProvider),
    );
    final chosen = await showDrillPicker(
      context,
      title: 'Replace drill',
      excludeIds: taken,
      single: true,
      suggested: suggested,
      noSuggestionsNote: 'No other drills fit your setup right now. Change your setup on Train to see more.',
    );
    if (chosen == null || chosen.isEmpty || !context.mounted) return;
    await _run(context, () => ref.read(trainingSessionProvider.notifier).swapDrill(index, chosen.single));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, int index, _DrillMenu action) async {
    final notifier = ref.read(trainingSessionProvider.notifier);
    final drill = session.drills[index];
    switch (action) {
      case _DrillMenu.details:
        onDetails(drill);
      case _DrillMenu.focus:
        onFocus(index);
      case _DrillMenu.rest:
        onRest(drill);
      case _DrillMenu.moveUp:
        await _run(context, () => notifier.moveDrill(index, index - 1));
      case _DrillMenu.moveDown:
        await _run(context, () => notifier.moveDrill(index, index + 1));
      case _DrillMenu.replace:
        await _replace(context, ref, index);
      case _DrillMenu.removeSet:
        await _run(context, () => notifier.removeUnloggedSet(index));
      case _DrillMenu.endEarly:
        final logged = session.setsLogged(index);
        if (await _confirm(context, 'End ${drill.title} early?', 'Your $logged logged ${logged == 1 ? 'set stays' : 'sets stay'}. The rest are skipped and earn nothing.', 'End drill') &&
            context.mounted) {
          await _run(context, () => notifier.endDrillEarly(index));
        }
      case _DrillMenu.remove:
        if (await _confirm(context, 'Remove ${drill.title}?', 'It has no logged sets, so nothing is lost.', 'Remove') && context.mounted) {
          await _run(context, () => notifier.removeDrill(index));
        }
    }
  }

  Future<void> _finishEarly(BuildContext context, WidgetRef ref) async {
    final unstarted = [
      for (final (index, drill) in session.drills.indexed)
        if (session.setsLogged(index) == 0) drill.title,
    ];
    final skipped = [
      for (final (index, drill) in session.drills.indexed)
        if (session.setsLogged(index) > 0 && session.setsLogged(index) < drill.defaultPrescription.sets) drill.title,
    ];
    final message = [
      'Everything you logged is saved.',
      if (unstarted.isNotEmpty) 'Drills you haven\'t started are left out: ${unstarted.join(', ')}.',
      if (skipped.isNotEmpty) 'Unlogged sets are skipped for: ${skipped.join(', ')}.',
      'Skipped sets earn nothing.',
    ].join(' ');
    if (!await _confirm(context, 'Finish workout now?', message, 'Finish workout') || !context.mounted) return;
    await _run(context, () => ref.read(trainingSessionProvider.notifier).finishEarly());
  }

  void _log(BuildContext context, WidgetRef ref, int index, _Values values) {
    final notifier = ref.read(trainingSessionProvider.notifier);
    _run(context, () {
      notifier.selectDrill(index);
      notifier.logSet(reps: values.reps, hits: values.hits, seconds: values.seconds, streak: values.streak, completed: values.completed);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastResultsProvider);
    final notifier = ref.read(trainingSessionProvider.notifier);
    return Column(
      key: const ValueKey('workout-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, drill) in session.drills.indexed)
          _DrillSection(
            key: ValueKey('overview-drill-${drill.id}'),
            session: session,
            index: index,
            previous: last[drill.id]?.sets ?? const [],
            onMenu: (action) => _menu(context, ref, index, action),
            onDetails: () => onDetails(drill),
            onLog: (values) => _log(context, ref, index, values),
            onEdit: (setIndex, values) =>
                _run(context, () => notifier.editSet(index, setIndex, reps: values.reps, hits: values.hits, seconds: values.seconds, streak: values.streak, completed: values.completed)),
            onUndo: () => _run(context, () => notifier.undoLastSet(index)),
            onAddSet: () => _run(context, () => notifier.addSet(index)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, 0),
          child: FilledButton.tonalIcon(onPressed: () => _addDrills(context, ref), icon: const Icon(Icons.add), label: const Text('Add drills')),
        ),
        if (session.logs.isNotEmpty && !session.finished)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, 0),
            child: TextButton(onPressed: () => _finishEarly(context, ref), child: const Text('Finish workout early')),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _DrillSection extends StatelessWidget {
  const _DrillSection({
    required this.session,
    required this.index,
    required this.previous,
    required this.onMenu,
    required this.onDetails,
    required this.onLog,
    required this.onEdit,
    required this.onUndo,
    required this.onAddSet,
    super.key,
  });

  final TrainingSession session;
  final int index;
  final List<SetLog> previous;
  final ValueChanged<_DrillMenu> onMenu;
  final VoidCallback onDetails;
  final ValueChanged<_Values> onLog;
  final void Function(int setIndex, _Values values) onEdit;
  final VoidCallback onUndo;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    final drill = session.drills[index];
    final sets = drill.defaultPrescription.sets;
    final logged = session.setsLogged(index);
    final logs = {
      for (final entry in session.logs)
        if (entry.drillId == drill.id) entry.log.setIndex: entry.log,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onDetails,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(drill.pillar.icon, color: drill.pillar.color(pillars), size: 22),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(drill.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<_DrillMenu>(
                key: ValueKey('overview-menu-$index'),
                tooltip: 'Options for ${drill.title}',
                onSelected: onMenu,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: _DrillMenu.details, child: Text('Drill details')),
                  const PopupMenuItem(value: _DrillMenu.focus, child: Text('Focus view')),
                  const PopupMenuItem(value: _DrillMenu.rest, child: Text('Rest timer')),
                  if (index > 0) const PopupMenuItem(value: _DrillMenu.moveUp, child: Text('Move up')),
                  if (index < session.drills.length - 1) const PopupMenuItem(value: _DrillMenu.moveDown, child: Text('Move down')),
                  if (logged == 0) const PopupMenuItem(value: _DrillMenu.replace, child: Text('Replace drill')),
                  if (sets > logged && sets > 1) const PopupMenuItem(value: _DrillMenu.removeSet, child: Text('Remove an unlogged set')),
                  if (logged > 0 && logged < sets) const PopupMenuItem(value: _DrillMenu.endEarly, child: Text('End drill early')),
                  if (logged == 0 && session.drills.length > 1) const PopupMenuItem(value: _DrillMenu.remove, child: Text('Remove drill')),
                ],
              ),
            ],
          ),
          _SetHeader(drill: drill),
          for (var set = 0; set < sets; set++)
            _SetRow(
              key: ValueKey('overview-set-${drill.id}-$set-${logs[set]?.loggedAt.microsecondsSinceEpoch}'),
              drill: drill,
              setIndex: set,
              log: logs[set],
              previous: set < previous.length ? previous[set] : (previous.isEmpty ? null : previous.last),
              canLog: set == logged,
              canUndo: set == logged - 1,
              onLog: onLog,
              onEdit: (values) => onEdit(set, values),
              onUndo: onUndo,
            ),
          const SizedBox(height: AppSpacing.xxs),
          TextButton.icon(onPressed: onAddSet, icon: const Icon(Icons.add, size: 18), label: const Text('Add set')),
        ],
      ),
    );
  }
}

const _setColumn = 36.0;
const _checkColumn = 44.0;

bool _showPrevious(BuildContext context) => MediaQuery.sizeOf(context).width >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.3;

class _SetHeader extends StatelessWidget {
  const _SetHeader({required this.drill});

  final Drill drill;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget cell(String text) => Center(
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(width: _setColumn, child: cell('SET')),
          const SizedBox(width: AppSpacing.xs),
          if (_showPrevious(context)) ...[Expanded(flex: 2, child: cell('PREVIOUS')), const SizedBox(width: AppSpacing.xs)],
          for (final field in _fieldsFor(drill.trackingType)) ...[Expanded(child: cell(field.label)), const SizedBox(width: AppSpacing.xs)],
          if (drill.trackingType == TrackingType.binary) Expanded(child: cell('DONE?')),
          const SizedBox(width: _checkColumn),
        ],
      ),
    );
  }
}

/// One set: its number, what the player did last time, the numbers to log, and a check that logs it.
/// Typing in a logged row corrects that set when the player leaves the row.
class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.drill,
    required this.setIndex,
    required this.log,
    required this.previous,
    required this.canLog,
    required this.canUndo,
    required this.onLog,
    required this.onEdit,
    required this.onUndo,
    super.key,
  });

  final Drill drill;
  final int setIndex;
  final SetLog? log;
  final SetLog? previous;
  final bool canLog;
  final bool canUndo;
  final ValueChanged<_Values> onLog;
  final ValueChanged<_Values> onEdit;
  final VoidCallback onUndo;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final List<_Field> _fields = _fieldsFor(widget.drill.trackingType);
  late final Map<String, TextEditingController> _controllers = {for (final field in _fields) field.key: TextEditingController(text: _initial(field.key))};
  String? _error;

  String _initial(String key) {
    final logged = _valueText(widget.log, key);
    if (widget.log != null) return logged ?? '';
    final fromPrevious = _valueText(widget.previous, key);
    if (fromPrevious != null) return fromPrevious;
    final plan = widget.drill.defaultPrescription;
    return switch (key) {
      'reps' => widget.drill.trackingType == TrackingType.density ? '' : '${plan.reps ?? ''}',
      'seconds' => '${plan.seconds ?? ''}',
      _ => '',
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _int(String key) => int.tryParse(_controllers[key]?.text.trim() ?? '');

  _Values get _values => (reps: _int('reps'), hits: _int('hits'), seconds: _int('seconds'), streak: _int('streak'), completed: widget.drill.trackingType == TrackingType.binary ? true : null);

  String? _problem(_Values values) {
    try {
      validateSetEntry(widget.drill.trackingType, reps: values.reps, hits: values.hits, seconds: values.seconds, streak: values.streak, completed: values.completed);
      return null;
    } on InvalidSetEntry catch (error) {
      return error.message as String;
    }
  }

  void _check() {
    if (widget.log != null) {
      if (widget.canUndo) widget.onUndo();
      return;
    }
    if (!widget.canLog) return;
    final values = _values;
    final problem = _problem(values);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);
    widget.onLog(values);
  }

  void _commit() {
    final log = widget.log;
    if (log == null) return;
    final values = _values;
    final unchanged = values.reps == log.reps && values.hits == log.hits && values.seconds == log.seconds && values.streak == log.streak;
    if (unchanged) return;
    final problem = _problem(values);
    if (problem != null) {
      setState(() {
        _error = problem;
        for (final field in _fields) {
          _controllers[field.key]!.text = _valueText(log, field.key) ?? '';
        }
      });
      return;
    }
    setState(() => _error = null);
    widget.onEdit((reps: values.reps, hits: values.hits, seconds: values.seconds, streak: values.streak, completed: log.completed));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = widget.log != null;
    final label = 'set ${widget.setIndex + 1} of ${widget.drill.title}';
    final previous = widget.previous;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (!focused) _commit();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: DecoratedBox(
          decoration: BoxDecoration(color: done ? scheme.primary.withValues(alpha: .14) : null, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: _setColumn,
                      child: Center(child: Text('${widget.setIndex + 1}', style: theme.textTheme.titleMedium)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (_showPrevious(context)) ...[
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            previous == null ? '–' : _compact(previous, widget.drill.trackingType),
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    for (final field in _fields) ...[
                      Expanded(
                        child: _NumberField(
                          key: ValueKey('set-${widget.drill.id}-${widget.setIndex}-${field.key}'),
                          controller: _controllers[field.key]!,
                          semanticLabel: '${field.label.toLowerCase()} for $label',
                          onDone: _commit,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (widget.drill.trackingType == TrackingType.binary) ...[
                      Expanded(
                        child: Center(child: Text(done ? 'Done' : 'Tap ✓', style: theme.textTheme.bodyMedium)),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    SizedBox(
                      width: _checkColumn,
                      height: 40,
                      child: Semantics(
                        button: true,
                        label: done ? 'Undo $label' : 'Log $label',
                        child: Material(
                          color: done ? scheme.primary : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            key: ValueKey('check-${widget.drill.id}-${widget.setIndex}'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: (done ? widget.canUndo : widget.canLog) ? _check : null,
                            child: Icon(Icons.check, color: done ? scheme.onPrimary : (widget.canLog ? scheme.onSurface : scheme.onSurface.withValues(alpha: .3))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.semanticLabel, required this.onDone, super.key});

  final TextEditingController controller;
  final String semanticLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Semantics(
        label: semanticLabel,
        textField: true,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          style: theme.textTheme.titleMedium,
          onEditingComplete: () {
            onDone();
            FocusScope.of(context).unfocus();
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }
}
