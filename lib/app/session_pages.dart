import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../design/components/training_components.dart';
import '../design/theme/app_theme.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_media.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/drill_swap.dart';
import '../features/drills/models/drill.dart';
import '../features/drills/set_calculations.dart';
import '../features/drills/set_summary.dart';
import '../features/session/rest_notifications.dart';
import '../features/session/session_cues.dart';
import '../features/session/set_countdown.dart';
import 'sample_data.dart';
import 'workout_history.dart';
import 'app_page.dart';
import 'training_state.dart';

class WorkoutSessionPanel extends ConsumerStatefulWidget {
  const WorkoutSessionPanel({required this.expandRequested, required this.navigationHeight, super.key});

  final bool expandRequested;
  final double navigationHeight;

  static double headerHeightOf(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return 104 + ((textScale - 1).clamp(0, 1) * 44).toDouble();
  }

  @override
  ConsumerState<WorkoutSessionPanel> createState() => _WorkoutSessionPanelState();
}

class _WorkoutSessionPanelState extends ConsumerState<WorkoutSessionPanel> with WidgetsBindingObserver {
  late final PageController _pages = PageController(initialPage: ref.read(trainingSessionProvider).drillIndex);
  final ScrollController _previews = ScrollController();
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final ValueNotifier<_DrillAction?> _drillAction = ValueNotifier(null);
  Timer? _ticker;
  double _minimumSheetSize = .2;
  double _maximumSheetSize = .96;
  bool _overview = false;
  bool _detailsOpen = false;
  bool _expanded = false;
  double _previewWidth = 0;
  double _previewViewport = 0;
  int? _centeredPreview;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_syncSheetProgress);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkRestFinished();
      setState(() {});
    });
    _prefetchFrom(ref.read(trainingSessionProvider).drillIndex);
    _reminders = ref.read(restNotificationsProvider);
    _keepScreenOn(true);
    WidgetsBinding.instance.addObserver(this);
  }

  // Players are often a few feet from the phone mid-drill; keep it awake while the workout panel is open.
  void _keepScreenOn(bool on) {
    unawaited(
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((Object error, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'workout screen', context: ErrorDescription('while ${on ? 'enabling' : 'disabling'} keep-screen-on')));
      }),
    );
  }

  late final RestNotifications _reminders;
  var _wasResting = false;

  // A reminder is only needed when the phone is locked or another app is open; while the
  // workout is on screen the in-app chime covers it, so nothing is scheduled until we leave.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifications = _reminders;
    if (state == AppLifecycleState.resumed) {
      unawaited(notifications.cancel().catchError(reportReminderError));
    } else if (state == AppLifecycleState.paused && ref.read(restRemindersEnabledProvider)) {
      final session = ref.read(trainingSessionProvider);
      final deadline = session.restEndsAt;
      if (deadline == null || !deadline.isAfter(clock.now().toUtc())) return;
      final next = session.setsLogged(session.drillIndex) < session.drill.defaultPrescription.sets ? session.drill.title : null;
      unawaited(notifications.scheduleRestOver(deadline, title: 'Rest\'s over', body: next == null ? 'Time for your next drill.' : 'Time for your next set of $next.').catchError(reportReminderError));
    }
  }

  // Chime when a rest countdown runs out on its own (skipping it stays silent).
  void _checkRestFinished() {
    final session = ref.read(trainingSessionProvider);
    final deadline = session.restEndsAt;
    final resting = deadline != null && deadline.isAfter(clock.now().toUtc());
    // In the background the rest reminder notification does this job, so don't chime twice.
    final foreground = WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_wasResting && !resting && deadline != null && foreground) ref.read(sessionCuesProvider).restFinished();
    _wasResting = resting;
  }

  // Warms the cache for this drill and the next so their demos are ready when opened.
  void _prefetchFrom(int index) {
    final drills = ref.read(trainingSessionProvider).drills;
    final source = ref.read(drillMediaSourceProvider);
    for (final i in [index, index + 1]) {
      if (i >= 0 && i < drills.length) unawaited(source.prefetch(drills[i].mediaAssetPath));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reminders.cancel().catchError(reportReminderError));
    _keepScreenOn(false);
    _ticker?.cancel();
    _sheet.removeListener(_syncSheetProgress);
    _pages.dispose();
    _previews.dispose();
    _sheet.dispose();
    _drillAction.dispose();
    super.dispose();
  }

  void _syncSheetProgress() {
    if (!mounted || !_sheet.isAttached) return;
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheetProgress());
      return;
    }
    final progress = (_sheet.size - _minimumSheetSize) / (_maximumSheetSize - _minimumSheetSize);
    ref.read(workoutSheetProgressProvider.notifier).update(progress);
    final expanded = progress > .01;
    if (_expanded != expanded) setState(() => _expanded = expanded);
  }

  @override
  void didUpdateWidget(WorkoutSessionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandRequested != oldWidget.expandRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheet.isAttached) {
          _sheet.jumpTo(widget.expandRequested ? _maximumSheetSize : _minimumSheetSize);
        }
      });
    }
  }

  void _centerPreview(int index) {
    if (!mounted || !_previews.hasClients || _centeredPreview == index) return;
    _centeredPreview = index;
    final target = (index * (_previewWidth + AppSpacing.sm) - (_previewViewport - _previewWidth) / 2).clamp(0.0, _previews.position.maxScrollExtent).toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _previews.jumpTo(target);
    } else {
      _previews.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    }
  }

  void _dragHandle(double deltaY) {
    if (!_sheet.isAttached) return;
    final nextSize = _sheet.size - deltaY / MediaQuery.sizeOf(context).height;
    _sheet.jumpTo(nextSize.clamp(_minimumSheetSize, _maximumSheetSize).toDouble());
    _syncSheetProgress();
  }

  void _settleHandleDrag() {
    if (!_sheet.isAttached) return;
    final snaps = [_minimumSheetSize, _maximumSheetSize];
    final target = snaps.reduce((nearest, size) => (size - _sheet.size).abs() < (nearest - _sheet.size).abs() ? size : nearest);
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheet.jumpTo(target);
      _syncSheetProgress();
      return;
    }
    _sheet.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic).whenComplete(_syncSheetProgress);
  }

  void _select(int index) {
    _drillAction.value = null;
    ref.read(trainingSessionProvider.notifier).selectDrill(index);
    _prefetchFrom(index);
    setState(() => _overview = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(index);
    });
  }

  Future<void> _showDetails(Drill drill) async {
    setState(() => _detailsOpen = true);
    try {
      await context.push('/session-drills/${Uri.encodeComponent(drill.id)}');
    } finally {
      if (mounted) setState(() => _detailsOpen = false);
    }
  }

  void _onPageChanged(int index) {
    _drillAction.value = null;
    ref.read(trainingSessionProvider.notifier).selectDrill(index);
    _prefetchFrom(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trainingSessionProvider.select((session) => session.restEndsAt), (previous, next) {
      if (previous == null && next != null && ref.read(restRemindersEnabledProvider)) {
        unawaited(ref.read(restNotificationsProvider).ensurePermission().catchError(reportReminderError));
      }
    });
    final session = ref.watch(trainingSessionProvider);
    final elapsed = session.elapsedSeconds;
    final remaining = session.restEndsAt == null ? 0 : (session.restEndsAt!.difference(clock.now().toUtc()).inMilliseconds / 1000).ceil().clamp(0, 600);
    final totalSets = session.drills.fold<int>(0, (sum, drill) => sum + drill.defaultPrescription.sets);
    final pillars = HockeyTheme.dark.extension<PillarColors>()!;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final statusHeaderHeight = WorkoutSessionPanel.headerHeightOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Theme(
      data: HockeyTheme.dark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The viewport spans the body plus the navigation slot, so the expanded
          // sheet fills the screen while the collapsed red header sits exactly
          // on top of the (opaque) navigation bar.
          final viewport = constraints.maxHeight;
          final minSheetSize = ((statusHeaderHeight + widget.navigationHeight) / viewport).clamp(.05, .9).toDouble();
          final maxSheetSize = ((viewport - topInset) / viewport).clamp(minSheetSize, 1).toDouble();
          _minimumSheetSize = minSheetSize;
          _maximumSheetSize = maxSheetSize;
          WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheetProgress());
          final screenWidth = MediaQuery.sizeOf(context).width;
          final cardWidth = (screenWidth - AppSpacing.screen * 2 - AppSpacing.sm * ((textScale > 1 ? 4 : 5) - 1)) / (textScale > 1 ? 4 : 5);
          const titleRowHeight = 48.0;
          final actionHeight = 56 + AppSpacing.sm + math.max(MediaQuery.paddingOf(context).bottom, AppSpacing.lg);
          // Fit title, previews, drill body, and the Log action on one screen.
          final drillBodyHeight = math.max(260.0, viewport - topInset - statusHeaderHeight - titleRowHeight - cardWidth * 16 / 9 - AppSpacing.xs - actionHeight - (remaining > 0 ? 76 : 0));
          return DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: widget.expandRequested ? maxSheetSize : minSheetSize,
            minChildSize: minSheetSize,
            maxChildSize: maxSheetSize,
            snap: true,
            snapSizes: [minSheetSize, maxSheetSize],
            builder: (context, scrollController) => Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                children: [
                  SizedBox(
                    height: statusHeaderHeight,
                    child: _WorkoutStatusHeader(
                      elapsed: elapsed,
                      active: session.activeSeconds,
                      setsLogged: session.logs.length,
                      totalSets: totalSets,
                      estimated: session.hasEstimatedTime,
                      onHandleDrag: _dragHandle,
                      onHandleDragEnd: _settleHandleDrag,
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      key: const ValueKey('workout-session-scroll'),
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.sm, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: titleRowHeight,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Your session · Drill ${session.drillIndex + 1} of ${session.drills.length}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: _overview ? 'Show drills' : 'Workout overview',
                                  onPressed: () => setState(() {
                                    _overview = !_overview;
                                    if (_overview) _drillAction.value = null;
                                  }),
                                  icon: Icon(_overview ? Icons.view_carousel_outlined : Icons.list_alt),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final available = constraints.maxWidth - AppSpacing.screen * 2;
                              final visibleCards = textScale > 1 ? 4 : 5;
                              final width = (available - AppSpacing.sm * (visibleCards - 1)) / visibleCards;
                              if (_previewWidth != width || _previewViewport != available) _centeredPreview = null;
                              _previewWidth = width;
                              _previewViewport = available;
                              WidgetsBinding.instance.addPostFrameCallback((_) => _centerPreview(session.drillIndex));
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, 0),
                                child: SizedBox(
                                  height: width * 16 / 9,
                                  child: ListView.separated(
                                    key: const ValueKey('workout-drill-previews'),
                                    controller: _previews,
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.zero,
                                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                                    itemCount: session.drills.length,
                                    itemBuilder: (context, index) {
                                      final drill = session.drills[index];
                                      final selected = index == session.drillIndex;
                                      final color = drill.pillar.color(pillars);
                                      return SizedBox(
                                        width: width,
                                        child: Semantics(
                                          key: ValueKey('workout-preview-${drill.id}'),
                                          button: true,
                                          selected: selected,
                                          label: '${drill.pillar.label}: ${drill.title}, ${session.setsLogged(index)} of ${drill.defaultPrescription.sets} sets',
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
                                                padding: const EdgeInsets.all(AppSpacing.xs),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Expanded(
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(11)),
                                                        child: Center(child: Icon(drill.pillar.icon, color: color, size: 26)),
                                                      ),
                                                    ),
                                                    const SizedBox(height: AppSpacing.xxs),
                                                    Text(drill.title, maxLines: textScale > 1 ? 1 : 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                                                    Text(
                                                      '${session.setsLogged(index)}/${drill.defaultPrescription.sets} sets',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context).textTheme.labelSmall,
                                                    ),
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
                              );
                            },
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
                            height: drillBodyHeight,
                            child: IndexedStack(
                              index: _overview ? 0 : 1,
                              children: [
                                ListView(
                                  key: const ValueKey('workout-overview-scroll'),
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  children: [
                                    const SectionHeading(title: 'Workout overview'),
                                    const SizedBox(height: AppSpacing.md),
                                    const Text('Training time counts your logged sets, not rest. A ~ means some untimed sets are estimated. Elapsed includes rest.'),
                                    const SizedBox(height: AppSpacing.md),
                                    for (final (index, drill) in session.drills.indexed) ...[
                                      TrainingCard(
                                        onTap: () => _select(index),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(drill.title),
                                            Text('${session.setsLogged(index)} / ${drill.defaultPrescription.sets} sets · ${drill.trackingType.label}'),
                                            Text(session.setsLogged(index) >= drill.defaultPrescription.sets ? 'Complete' : 'Continue drill'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ],
                                ),
                                PageView.builder(
                                  controller: _pages,
                                  itemCount: session.drills.length,
                                  onPageChanged: _onPageChanged,
                                  itemBuilder: (_, index) => _ActiveDrill(
                                    key: ValueKey('${session.drills[index].id}-${session.setsLogged(index)}'),
                                    session: session.copyWith(drillIndex: index),
                                    active: _expanded && !_overview && !_detailsOpen && index == session.drillIndex,
                                    onSelect: _select,
                                    onShowDetails: () => _showDetails(session.drills[index]),
                                    actionNotifier: _drillAction,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SafeArea(
                            top: false,
                            minimum: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                            child: ValueListenableBuilder<_DrillAction?>(
                              valueListenable: _drillAction,
                              builder: (context, action, _) {
                                final label = session.finished ? 'Finish workout' : action?.label;
                                final onPressed = session.finished
                                    ? () {
                                        ref.read(trainingSessionProvider.notifier).dismissFinishedWorkout();
                                        context.go('/summary');
                                      }
                                    : action?.onPressed;
                                return SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.check), label: Text(label ?? 'Log set')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkoutStatusHeader extends StatelessWidget {
  const _WorkoutStatusHeader({
    required this.elapsed,
    required this.active,
    required this.setsLogged,
    required this.totalSets,
    required this.estimated,
    required this.onHandleDrag,
    required this.onHandleDragEnd,
  });

  final int elapsed;
  final int active;
  final int setsLogged;
  final int totalSets;
  final bool estimated;
  final ValueChanged<double> onHandleDrag;
  final VoidCallback onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      key: const ValueKey('workout-sheet-handle'),
      onPointerMove: (event) => onHandleDrag(event.delta.dy),
      onPointerUp: (_) => onHandleDragEnd(),
      onPointerCancel: (_) => onHandleDragEnd(),
      child: Container(
        key: const ValueKey('workout-status-header'),
        decoration: BoxDecoration(color: theme.colorScheme.primary),
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.sm),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 24,
              child: Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: theme.colorScheme.onPrimary.withValues(alpha: .55), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _WorkoutMetric(label: 'ELAPSED', value: _time(elapsed), color: theme.colorScheme.onPrimary),
                ),
                Expanded(
                  child: Semantics(
                    label: 'Training time ${_time(active)}${estimated ? ', partly estimated' : ''}. This is the time that counts toward your total training.',
                    excludeSemantics: true,
                    child: _WorkoutMetric(label: 'TRAINING', value: '${estimated ? '~' : ''}${_time(active)}', centered: true, color: theme.colorScheme.onPrimary),
                  ),
                ),
                Expanded(
                  child: _WorkoutMetric(label: 'SETS', value: '$setsLogged/$totalSets', alignEnd: true, color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  const _WorkoutMetric({required this.label, required this.value, required this.color, this.centered = false, this.alignEnd = false});

  final String label;
  final String value;
  final Color color;
  final bool centered;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: .78)),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

String _time(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class _DrillAction {
  const _DrillAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

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
          _error = 'Couldn\'t save settings: ${error.message ?? error.code}';
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rest timer'),
            subtitle: const Text('Start a countdown after each logged set. You can still swipe and keep training.'),
            value: _enabled,
            onChanged: _saving ? null : (value) => setState(() => _enabled = value),
          ),
          Text('Rest duration: $_seconds seconds'),
          Slider(value: _seconds.toDouble(), min: 15, max: 600, divisions: 39, label: '${_seconds}s', onChanged: _saving ? null : (value) => setState(() => _seconds = value.round())),
          const Text('Saved per drill on this device. Turning rest off applies to future sets. Tap Skip rest to end a countdown now.'),
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
  const _ActiveDrill({required this.session, required this.active, required this.onSelect, required this.onShowDetails, required this.actionNotifier, super.key});

  final TrainingSession session;
  final bool active;
  final ValueChanged<int> onSelect;
  final VoidCallback onShowDetails;
  final ValueNotifier<_DrillAction?> actionNotifier;

  @override
  ConsumerState<_ActiveDrill> createState() => _ActiveDrillState();
}

class _ActiveDrillState extends ConsumerState<_ActiveDrill> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  int _count = 0;
  bool _completed = false;
  late final SetCountdown _countdown = SetCountdown(totalSeconds: drill.defaultPrescription.seconds ?? 1);

  Drill get drill => widget.session.drill;
  bool get _timed => drill.trackingType == TrackingType.duration || drill.trackingType == TrackingType.density;
  bool get _canLog => !_timed || _countdown.isDone;
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
    if (!widget.active && _countdown.isActive) {
      _countdown.pause(clock.now().toUtc());
      _timer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _count = drill.trackingType == TrackingType.volume ? drill.defaultPrescription.reps! : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    final now = clock.now().toUtc();
    if (_countdown.isActive) {
      _countdown.pause(now);
      _timer?.cancel();
      setState(() {});
      return;
    }
    _handle(_countdown.start(now));
    setState(() {});
    // Ticking often keeps the display and the 3-2-1 beats accurate; the countdown itself uses the clock.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _handle(_countdown.tick(clock.now().toUtc()));
      if (!_countdown.isActive) _timer?.cancel();
      if (mounted) setState(() {});
    });
  }

  void _handle(List<CountdownEvent> events) {
    final cues = ref.read(sessionCuesProvider);
    for (final event in events) {
      switch (event) {
        case LeadInTick(:final secondsLeft):
          cues.leadInTick(secondsLeft);
        case CountdownStarted():
          cues.setStarted();
        case CountdownFinished():
          cues.setFinished();
      }
    }
  }

  void _startRest() {
    final settings = ref.read(drillRestSettingsProvider)[drill.id];
    final seconds = settings?.enabled == true ? settings!.seconds : drill.defaultPrescription.restSeconds;
    ref.read(trainingSessionProvider.notifier).startRest(seconds.clamp(15, 600));
  }

  Future<void> _swapDrill() async {
    final session = widget.session;
    final setup = ref.read(trainingSetupProvider);
    final catalog = ref.read(drillCatalogProvider).value ?? const <Drill>[];
    final options = swapCandidates(
      current: drill,
      catalog: visibleDrills(catalog, pro: ref.read(drillFiltersUnlockedProvider)),
      alreadyInWorkout: session.drills.map((d) => d.id),
      setup: setup,
    );
    final index = session.drillIndex;
    final choice = await showModalBottomSheet<Drill>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Swap drill', style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(options.isEmpty ? 'No other drills fit your setup right now. Change your setup on Train to see more.' : 'Pick a drill that works the same skill and fits your setup.'),
              const SizedBox(height: AppSpacing.md),
              for (final option in options)
                ListTile(contentPadding: EdgeInsets.zero, title: Text(option.title), subtitle: Text(option.prescriptionLabel), onTap: () => Navigator.of(sheetContext).pop(option)),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) ref.read(trainingSessionProvider.notifier).swapDrill(index, choice);
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
    final nextIncomplete = _nextIncomplete;
    final action = widget.active && !widget.session.finished
        ? _DrillAction(
            label: _drillComplete ? 'Next drill' : 'Log set',
            onPressed: _drillComplete
                ? (nextIncomplete == null ? null : () => widget.onSelect(nextIncomplete))
                : _canLog
                ? _log
                : null,
          )
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) widget.actionNotifier.value = action;
    });
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: widget.session.logs.length / widget.session.drills.fold<int>(0, (total, drill) => total + drill.defaultPrescription.sets)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drill.title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(_drillComplete ? 'All sets logged' : 'Set ${widget.session.setIndex + 1} of ${drill.defaultPrescription.sets}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(tooltip: 'Drill details', onPressed: widget.onShowDetails, icon: const Icon(Icons.play_circle_outline)),
              IconButton(
                tooltip: ref.watch(drillRestSettingsProvider)[drill.id]?.enabled == true ? 'Drill settings · Rest on' : 'Drill settings · Rest off',
                onPressed: () => showDrillRestSettings(context, drill),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              if (widget.session.setsLogged(widget.session.drillIndex) == 0) TextButton.icon(onPressed: _swapDrill, icon: const Icon(Icons.swap_horiz), label: const Text('Swap drill')),
              TextButton.icon(
                onPressed: widget.session.restEndsAt != null && widget.session.restEndsAt!.isAfter(clock.now().toUtc()) ? null : _startRest,
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Start rest'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_drillComplete)
            const TrainingCard(child: Text('Drill done. Swipe to the next drill or open the workout overview.'))
          else if (_timed) ...[
            Center(
              child: Semantics(
                liveRegion: _countdown.phase == CountdownPhase.leadIn,
                child: TrainingProgressRing(
                  progress: _countdown.phase == CountdownPhase.leadIn ? 0 : _countdown.progress,
                  value: _countdown.phase == CountdownPhase.leadIn
                      ? '${_countdown.leadInSecondsLeft}'
                      : '${_countdown.remainingSeconds ~/ 60}:${(_countdown.remainingSeconds % 60).toString().padLeft(2, '0')}',
                  label: switch (_countdown.phase) {
                    CountdownPhase.leadIn => 'Get ready',
                    CountdownPhase.done => 'Set complete',
                    CountdownPhase.paused => 'Paused',
                    _ => 'seconds remaining',
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_countdown.isDone)
              OutlinedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_countdown.isActive ? Icons.pause : Icons.play_arrow),
                label: Text(switch (_countdown.phase) {
                  CountdownPhase.leadIn => 'Cancel',
                  CountdownPhase.running => 'Pause timer',
                  CountdownPhase.paused => 'Resume timer',
                  _ => 'Start timer',
                }),
              ),
            if (type == TrackingType.density && _countdown.isDone) ...[const SizedBox(height: AppSpacing.md), _counter('Shots in this window', 999)],
          ] else if (type == TrackingType.binary)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Drill completed'),
              subtitle: const Text('Mark it when you finish this set.'),
              value: _completed,
              onChanged: (value) => setState(() => _completed = value),
            )
          else
            _counter(switch (type) {
              TrackingType.accuracy => 'Hits out of ${drill.defaultPrescription.reps}',
              TrackingType.streak => 'Best consecutive passes',
              _ => 'Reps completed',
            }, type == TrackingType.accuracy ? drill.defaultPrescription.reps! : 999),
          if (type == TrackingType.accuracy) ...[
            const SizedBox(height: AppSpacing.md),
            Text('${(_count / drill.defaultPrescription.reps! * 100).round()}% accuracy', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ],
          if (type == TrackingType.density && _countdown.isDone) ...[
            const SizedBox(height: AppSpacing.md),
            Text('${(_count / drill.defaultPrescription.seconds! * 60).round()} shots / min', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ],
        ],
      ),
    );
  }

  Widget _counter(String label, int max) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.xs),
      TextButton(
        onPressed: () => _editCount(label, max),
        child: Semantics(
          liveRegion: true,
          label: '$label: $_count. Tap to enter a number.',
          child: Text('$_count', style: Theme.of(context).textTheme.displayMedium),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _count == 0 ? null : () => setState(() => _count--),
              child: const Icon(Icons.remove, semanticLabel: 'Decrease count'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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
  const SummaryPage({this.workoutId, super.key});

  /// Set to show a saved workout from history instead of the one just finished.
  final String? workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = workoutId != null;
    final session = saved ? ref.watch(workoutHistoryProvider.notifier).byId(workoutId!) ?? const TrainingSession(drills: []) : ref.watch(trainingSessionProvider);
    ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);
    if (saved && session.drills.isEmpty) {
      return AppPage(
        title: 'Workout not found',
        action: FilledButton(onPressed: () => context.go('/progress'), child: const Text('Back to Progress')),
        children: const [Text('This workout isn\'t in your history anymore.')],
      );
    }
    if (!session.finished) {
      return AppPage(
        title: 'No finished workout yet',
        action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
        children: const [Text('Finish a workout and your summary shows up here.')],
      );
    }
    final shots = shotsLogged(session);
    return AppPage(
      title: saved ? 'Workout summary' : 'You showed up.',
      subtitle: saved ? '${workoutDateLabel(session.startedAt!.toLocal(), clock.now())} · ${workoutTitle(session)}' : 'That’s how you get better.',
      action: FilledButton(onPressed: () => context.go(saved ? '/progress' : '/train'), child: Text(saved ? 'Back to Progress' : 'Back to Train')),
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
                Text(
                  drillTotalsLabel(
                    drill,
                    summarizeDrill(drill, [
                      for (final entry in session.logs)
                        if (entry.drillId == drill.id) entry.log,
                    ]),
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final entry in session.logs.where((entry) => entry.drillId == drill.id)) Text('Set ${entry.log.setIndex + 1}: ${setResultLabel(entry.log, drill.trackingType)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        const Text('Saved to your history on this device. Syncing to your account and team updates aren\'t live yet.'),
      ],
    );
  }
}
