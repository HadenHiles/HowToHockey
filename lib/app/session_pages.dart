import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/theme/app_theme.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/models/drill.dart';
import 'player_pages.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'training_state.dart';

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  late final PageController _pages = PageController(initialPage: ref.read(trainingSessionProvider).drillIndex);
  final DraggableScrollableController _sheet = DraggableScrollableController();
  Timer? _ticker;
  bool _overview = false;
  bool _sheetExpanded = true;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_updateSheetMode);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sheet.removeListener(_updateSheetMode);
    _pages.dispose();
    _sheet.dispose();
    super.dispose();
  }

  void _updateSheetMode() {
    if (!_sheet.isAttached) return;
    final expanded = _sheet.size > .42;
    if (_sheetExpanded != expanded) setState(() => _sheetExpanded = expanded);
  }

  void _select(int index) {
    ref.read(trainingSessionProvider.notifier).selectDrill(index);
    setState(() => _overview = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trainingSessionProvider);
    final elapsed = session.elapsedSeconds;
    final remaining = session.restEndsAt == null ? 0 : (session.restEndsAt!.difference(DateTime.now().toUtc()).inMilliseconds / 1000).ceil().clamp(0, 600);
    final totalSets = session.drills.fold<int>(0, (sum, drill) => sum + drill.defaultPrescription.sets);
    final pillars = HockeyTheme.dark.extension<PillarColors>()!;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final previewHeight = 112.0 + ((textScale - 1).clamp(0, 2) * 32).toDouble();
    final minSheetSize = (.19 + ((textScale - 1).clamp(0, 1) * .13)).toDouble();
    final statusHeaderHeight = 104 + ((textScale - 1).clamp(0, 2) * 80).toDouble();
    final headerActions = _sheetExpanded && textScale < 1.5;
    final headerHeight = statusHeaderHeight + (headerActions ? 92 : 0);
    return Stack(
      children: [
        const TrainPage(),
        const ModalBarrier(color: Color(0x99000000), dismissible: false),
        Theme(
          data: HockeyTheme.dark,
          child: DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: .88,
            minChildSize: minSheetSize,
            maxChildSize: .98,
            snap: true,
            snapSizes: [minSheetSize, .88],
            builder: (context, scrollController) => Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
                      child: GestureDetector(
                        key: const ValueKey('workout-sheet-handle'),
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (_sheet.isAttached) {
                            final nextSize = _sheet.size - details.delta.dy / MediaQuery.sizeOf(context).height;
                            _sheet.jumpTo(nextSize.clamp(minSheetSize, .98).toDouble());
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (!_sheet.isAttached) return;
                          final velocity = details.velocity.pixelsPerSecond.dy;
                          final midpoint = (minSheetSize + .88) / 2;
                          final target = velocity < -250 || (velocity.abs() <= 250 && _sheet.size >= midpoint) ? .88 : minSheetSize;
                          _sheet.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 20,
                              child: Center(
                                child: Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .32), borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Text('Elapsed ${_time(elapsed)}', style: Theme.of(context).textTheme.labelSmall),
                                Text('Training ${_time(session.activeSeconds)}${session.hasEstimatedTime ? ' est.' : ''}', style: Theme.of(context).textTheme.labelSmall),
                                Text('${session.logs.length}/$totalSets sets', style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                            if (headerActions) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('WORKOUT IN PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: pillars.shotAccuracy, letterSpacing: 1)),
                                        Text('Your session', style: Theme.of(context).textTheme.titleLarge),
                                      ],
                                    ),
                                  ),
                                  IconButton(tooltip: _overview ? 'Show drills' : 'Workout overview', onPressed: () => setState(() => _overview = !_overview), icon: Icon(_overview ? Icons.view_carousel_outlined : Icons.list_alt)),
                                  IconButton(
                                    tooltip: 'Minimize workout',
                                    onPressed: () => _sheet.animateTo(minSheetSize, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      key: const ValueKey('workout-session-scroll'),
                      controller: scrollController,
                      slivers: [
                        if (_sheetExpanded && !headerActions)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('WORKOUT IN PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: pillars.shotAccuracy, letterSpacing: 1)),
                                        Text('Your session', style: Theme.of(context).textTheme.titleLarge),
                                      ],
                                    ),
                                  ),
                                  IconButton(tooltip: _overview ? 'Show drills' : 'Workout overview', onPressed: () => setState(() => _overview = !_overview), icon: Icon(_overview ? Icons.view_carousel_outlined : Icons.list_alt)),
                                  IconButton(
                                    tooltip: 'Minimize workout',
                                    onPressed: () => _sheet.animateTo(minSheetSize, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: previewHeight,
                            child: ListView.separated(
                              key: const ValueKey('workout-drill-previews'),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                              itemCount: session.drills.length,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final drill = session.drills[index];
                                final selected = !_overview && index == session.drillIndex;
                                final color = drill.pillar.color(pillars);
                                return Semantics(
                                  button: true,
                                  selected: selected,
                                  label: '${drill.pillar.label}: ${drill.title}, ${session.setsLogged(index)} of ${drill.defaultPrescription.sets} sets',
                                  child: SizedBox(
                                    width: 112,
                                    child: Material(
                                      color: selected ? color.withValues(alpha: .2) : Theme.of(context).colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(color: selected ? color : Theme.of(context).dividerColor, width: selected ? 2 : 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => _select(index),
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 32,
                                                width: double.infinity,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(9)),
                                                  child: Center(child: Icon(drill.pillar.icon, color: color, size: 24)),
                                                ),
                                              ),
                                              Text(drill.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                                              Text('${session.setsLogged(index)}/${drill.defaultPrescription.sets} sets', maxLines: 1, style: Theme.of(context).textTheme.labelSmall),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (remaining > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                              child: TrainingCard(
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('Rest ${_time(remaining)}'),
                                    TextButton(onPressed: () => ref.read(trainingSessionProvider.notifier).adjustRest(-15), child: const Text('−15s')),
                                    TextButton(onPressed: () => ref.read(trainingSessionProvider.notifier).adjustRest(15), child: const Text('+15s')),
                                    TextButton(onPressed: () => ref.read(trainingSessionProvider.notifier).skipRest(), child: const Text('Skip rest')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * .44,
                            child: Column(
                              children: [
                                Expanded(
                                  child: IndexedStack(
                                    index: _overview ? 0 : 1,
                                    children: [
                                      ListView(
                                        padding: const EdgeInsets.all(AppSpacing.screen),
                                        children: [
                                          const SectionHeading(title: 'Workout overview'),
                                          const SizedBox(height: AppSpacing.md),
                                          const Text('Active time counts logged training sets, not rest. Untimed sets use estimated training time. Elapsed includes rest.'),
                                          const SizedBox(height: AppSpacing.md),
                                          for (final (index, drill) in session.drills.indexed) ...[
                                            TrainingCard(
                                              onTap: () => _select(index),
                                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(drill.title), Text('${session.setsLogged(index)} / ${drill.defaultPrescription.sets} sets · ${drill.trackingType.label}'), Text(session.setsLogged(index) >= drill.defaultPrescription.sets ? 'Complete' : 'Continue drill')]),
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                          ],
                                        ],
                                      ),
                                      PageView.builder(
                                        controller: _pages,
                                        itemCount: session.drills.length,
                                        onPageChanged: (index) => ref.read(trainingSessionProvider.notifier).selectDrill(index),
                                        itemBuilder: (_, index) => _ActiveDrill(
                                          key: ValueKey('${session.drills[index].id}-${session.setsLogged(index)}'),
                                          session: session.copyWith(drillIndex: index),
                                          active: !_overview && index == session.drillIndex,
                                          onSelect: _select,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (session.finished)
                                  SafeArea(
                                    top: false,
                                    minimum: const EdgeInsets.all(AppSpacing.screen),
                                    child: FilledButton(onPressed: () => context.pushReplacement('/summary'), child: const Text('Finish workout')),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * .08)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _time(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

Future<void> showDrillRestSettings(BuildContext context, Drill drill) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _DrillRestSheet(drill: drill),
);

class _DrillRestSheet extends ConsumerStatefulWidget {
  const _DrillRestSheet({required this.drill});

  final Drill drill;

  @override
  ConsumerState<_DrillRestSheet> createState() => _DrillRestSheetState();
}

class _DrillRestSheetState extends ConsumerState<_DrillRestSheet> {
  late bool _enabled;
  late int _seconds;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(drillRestSettingsProvider)[widget.drill.id];
    _enabled = settings?.enabled ?? false;
    _seconds = settings?.seconds ?? widget.drill.defaultPrescription.restSeconds.clamp(15, 600);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(drillRestSettingsProvider.notifier).configure(widget.drill.id, (enabled: _enabled, seconds: _seconds));
      if (mounted) Navigator.of(context).pop();
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
          _error = 'Could not save settings: ${error.message ?? error.code}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Drill settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.drill.title),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Rest timer'), subtitle: const Text('Start an optional inline countdown after each logged set. You can still swipe and train.'), value: _enabled, onChanged: _saving ? null : (value) => setState(() => _enabled = value)),
          Text('Rest duration: $_seconds seconds'),
          Slider(value: _seconds.toDouble(), min: 15, max: 600, divisions: 39, label: '${_seconds}s', onChanged: _saving ? null : (value) => setState(() => _seconds = value.round())),
          const Text('Saved per drill on this device. Disabling rest affects future sets; use Skip rest to dismiss a current countdown.'),
          if (_error != null)
            Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(_error!)),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save settings')),
        ],
      ),
    ),
  );
}

class _ActiveDrill extends ConsumerStatefulWidget {
  const _ActiveDrill({required this.session, required this.active, required this.onSelect, super.key});

  final TrainingSession session;
  final bool active;
  final ValueChanged<int> onSelect;

  @override
  ConsumerState<_ActiveDrill> createState() => _ActiveDrillState();
}

class _ActiveDrillState extends ConsumerState<_ActiveDrill> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  int _count = 0;
  int _remaining = 0;
  bool _completed = false;
  bool _running = false;

  Drill get drill => widget.session.drill;
  bool get _timed => drill.trackingType == TrackingType.duration || drill.trackingType == TrackingType.density;
  bool get _canLog => !_timed || _remaining == 0;
  bool get _drillComplete => widget.session.setIndex >= drill.defaultPrescription.sets;
  int? get _nextIncomplete {
    final session = widget.session;
    for (var offset = 1; offset <= session.drills.length; offset++) {
      final index = (session.drillIndex + offset) % session.drills.length;
      if (session.setsLogged(index) < session.drills[index].defaultPrescription.sets) return index;
    }
    return null;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(_ActiveDrill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && _running) {
      _timer?.cancel();
      _running = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _remaining = drill.defaultPrescription.seconds ?? 0;
    _count = drill.trackingType == TrackingType.volume ? drill.defaultPrescription.reps! : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining--;
        if (_remaining == 0) {
          _running = false;
          _timer?.cancel();
        }
      });
    });
  }

  void _log() {
    final type = drill.trackingType;
    ref
        .read(trainingSessionProvider.notifier)
        .logSet(
          reps: switch (type) {
            TrackingType.volume || TrackingType.density => _count,
            TrackingType.accuracy => drill.defaultPrescription.reps,
            _ => null,
          },
          hits: type == TrackingType.accuracy ? _count : null,
          seconds: _timed ? drill.defaultPrescription.seconds : null,
          streak: type == TrackingType.streak ? _count : null,
          completed: type == TrackingType.binary ? _completed : null,
        );
  }

  Future<void> _editCount(String label, int max) async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _CountDialog(label: label, max: max, initial: _count),
    );
    if (mounted && value != null) setState(() => _count = value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final type = drill.trackingType;
    return AppPage(
      title: 'Drill ${widget.session.drillIndex + 1} of ${widget.session.drills.length}',
      showAppBar: false,
      action: widget.session.finished
          ? null
          : FilledButton.icon(
              onPressed: _drillComplete
                  ? _nextIncomplete != null
                        ? () => widget.onSelect(_nextIncomplete!)
                        : null
                  : _canLog
                  ? _log
                  : null,
              icon: const Icon(Icons.check),
              label: Text(_drillComplete ? 'Next drill' : 'Log set'),
            ),
      children: [
        Text('Drill ${widget.session.drillIndex + 1} of ${widget.session.drills.length}', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const Text('Swipe between drills · Overview shows the whole workout'),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(onPressed: () => showDrillRestSettings(context, drill), icon: const Icon(Icons.tune), label: Text(ref.watch(drillRestSettingsProvider)[drill.id]?.enabled == true ? 'Drill settings · Rest on' : 'Drill settings · Rest off')),
        LinearProgressIndicator(value: widget.session.logs.length / widget.session.drills.fold<int>(0, (total, drill) => total + drill.defaultPrescription.sets)),
        const SizedBox(height: AppSpacing.md),
        DrillMediaPlaceholder(title: drill.title, compact: true),
        const SizedBox(height: AppSpacing.xl),
        Text(drill.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(_drillComplete ? 'All sets logged' : 'Set ${widget.session.setIndex + 1} of ${drill.defaultPrescription.sets}', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xl),
        if (_drillComplete)
          const TrainingCard(child: Text('Drill complete. Swipe to another drill or open the workout overview.'))
        else if (_timed) ...[
          Center(
            child: TrainingProgressRing(progress: 1 - _remaining / drill.defaultPrescription.seconds!, value: '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}', label: _remaining == 0 ? 'Set complete' : 'seconds remaining'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_remaining > 0) OutlinedButton.icon(onPressed: _toggleTimer, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running ? 'Pause timer' : 'Start timer')),
          if (type == TrackingType.density && _remaining == 0) ...[const SizedBox(height: AppSpacing.md), _counter('Shots in this window', 999)],
        ] else if (type == TrackingType.binary)
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Drill completed'), subtitle: const Text('Mark whether you finished this set.'), value: _completed, onChanged: (value) => setState(() => _completed = value))
        else
          _counter(switch (type) {
            TrackingType.accuracy => 'Hits out of ${drill.defaultPrescription.reps}',
            TrackingType.streak => 'Best consecutive passes',
            _ => 'Reps completed',
          }, type == TrackingType.accuracy ? drill.defaultPrescription.reps! : 999),
        if (type == TrackingType.accuracy) ...[const SizedBox(height: AppSpacing.md), Text('${(_count / drill.defaultPrescription.reps! * 100).round()}% accuracy', textAlign: TextAlign.center, style: theme.textTheme.titleLarge)],
        if (type == TrackingType.density && _remaining == 0) ...[const SizedBox(height: AppSpacing.md), Text('${(_count / drill.defaultPrescription.seconds! * 60).round()} shots / min', textAlign: TextAlign.center, style: theme.textTheme.titleLarge)],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Remember'),
        const SizedBox(height: AppSpacing.md),
        for (final cue in drill.formCues) ...[Text(cue, style: theme.textTheme.bodyLarge), const SizedBox(height: AppSpacing.sm)],
      ],
    );
  }

  Widget _counter(String label, int max) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.md),
      TextButton(
        onPressed: () => _editCount(label, max),
        child: Semantics(
          liveRegion: true,
          label: '$label: $_count. Tap to enter a number.',
          child: Text('$_count', style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: _count == 0 ? null : () => setState(() => _count--),
              child: const Icon(Icons.remove, semanticLabel: 'Decrease count'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: _count == max ? null : () => setState(() => _count++),
              child: const Icon(Icons.add, semanticLabel: 'Increase count'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _CountDialog extends StatefulWidget {
  const _CountDialog({required this.label, required this.max, required this.initial});

  final String label;
  final int max;
  final int initial;

  @override
  State<_CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<_CountDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: 'Count (0–${widget.max})'),
        validator: (value) {
          final count = int.tryParse(value ?? '');
          return count == null || count < 0 || count > widget.max ? 'Enter a number from 0 to ${widget.max}.' : null;
        },
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.of(context).pop(int.parse(_controller.text));
          }
        },
        child: const Text('Apply'),
      ),
    ],
  );
}

class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trainingSessionProvider);
    final theme = Theme.of(context);
    if (!session.finished) {
      return AppPage(
        title: 'No completed workout',
        action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
        children: const [Text('Complete a workout to see its summary.')],
      );
    }
    final shots = session.logs
        .where((entry) {
          final pillar = session.drills.firstWhere((drill) => drill.id == entry.drillId).pillar;
          return pillar == SkillPillar.shotAccuracy || pillar == SkillPillar.shotPower;
        })
        .fold(0, (total, entry) => total + (entry.log.reps ?? 0));
    return AppPage(
      title: 'You showed up.',
      subtitle: 'That’s how better happens.',
      action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            MetricTile(value: '$shots', label: 'Shots logged'),
            MetricTile(value: '${session.logs.length}', label: 'Sets logged'),
            MetricTile(value: '${session.drills.length}', label: 'Drills completed'),
            MetricTile(value: _time(session.activeSeconds), label: 'Active training', detail: 'Untimed sets are estimated'),
            MetricTile(value: _time(session.elapsedSeconds), label: 'Elapsed time', detail: 'Includes rest'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Your workout, set by set'),
        const SizedBox(height: AppSpacing.md),
        for (final drill in session.drills) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drill.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                for (final entry in session.logs.where((entry) => entry.drillId == drill.id)) Text('Set ${entry.log.setIndex + 1}: ${_logLabel(entry.log, drill.trackingType)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        const Text('Results are held in memory only. Workout history, lifetime stats, and team updates are not connected yet.'),
      ],
    );
  }

  String _logLabel(SetLog log, TrackingType type) => switch (type) {
    TrackingType.volume => '${log.reps} reps',
    TrackingType.duration => '${log.seconds}s',
    TrackingType.density => '${log.reps} shots in ${log.seconds}s',
    TrackingType.accuracy => '${log.hits} / ${log.reps} hits',
    TrackingType.streak => '${log.streak} consecutive',
    TrackingType.binary => log.completed! ? 'Completed' : 'Not completed',
  };
}
