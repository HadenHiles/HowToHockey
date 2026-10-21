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
import 'drill_picker.dart';
import 'drill_media_card.dart';
import 'routine_state.dart';
import 'workout_overview.dart';
import 'workout_history.dart';
import 'app_page.dart';
import 'parent_review_page.dart';
import '../features/share/share_data.dart';
import 'progress_state.dart';
import 'share_sheet.dart';
import 'progress_tuning.dart';
import 'workout_sync.dart';
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
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final ValueNotifier<_DrillAction?> _drillAction = ValueNotifier(null);
  Timer? _ticker;
  double _minimumSheetSize = .2;
  double _maximumSheetSize = .96;

  /// True on the Standard view (the list of sets); false on the Simple guided view, the default.
  late bool _overview = ref.read(workoutStandardViewProvider);
  bool _detailsOpen = false;
  bool _expanded = false;

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

  // After the workout is edited, the selected drill can sit at a different position; keep the pages on it.
  void _syncPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      final index = ref.read(trainingSessionProvider).drillIndex;
      if (_pages.page?.round() != index) _pages.jumpToPage(index);
      _prefetchFrom(index);
    });
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
          const titleRowHeight = 48.0;
          const stepsHeight = 28.0;
          final actionHeight = _actionBarHeight(context);
          // The Simple view fits its drill, a pinned action and a progress strip on one screen where it can.
          final drillBodyHeight = math.max(380.0, viewport - topInset - statusHeaderHeight - titleRowHeight - stepsHeight - actionHeight - (remaining > 0 ? 76 : 0));
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
              child: LayoutBuilder(
                builder: (context, box) => Column(
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
                                          _overview ? 'Workout' : 'Drill ${session.drillIndex + 1} of ${session.drills.length}',
                                          style: Theme.of(context).textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: _overview ? 'Simple view' : 'Standard view',
                                    onPressed: () {
                                      // Switching with the toggle is a choice worth remembering; jumping to one drill from the list is not.
                                      ref.read(workoutStandardViewProvider.notifier).choose(!_overview);
                                      setState(() {
                                        _overview = !_overview;
                                        _drillAction.value = null;
                                      });
                                    },
                                    icon: Icon(_overview ? Icons.crop_portrait : Icons.list_alt),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!_overview) SliverToBoxAdapter(child: _DrillSteps(session: session)),
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
                            // Keyed: slivers appear and disappear around it, which must not remount the drill pages.
                            key: const ValueKey('workout-body'),
                            child: Column(
                              children: [
                                if (_overview)
                                  WorkoutOverview(session: session, onFocus: _select, onDetails: _showDetails, onRest: (drill) => showDrillRestSettings(context, drill), onEdited: _syncPage),
                                // Kept alive while hidden so a half-entered count survives a trip to the list.
                                Offstage(
                                  key: const ValueKey('focus-pages'),
                                  offstage: _overview,
                                  child: SizedBox(
                                    height: drillBodyHeight,
                                    child: PageView.builder(
                                      controller: _pages,
                                      itemCount: session.drills.length,
                                      onPageChanged: _onPageChanged,
                                      itemBuilder: (_, index) => _ActiveDrill(
                                        key: ValueKey('${session.drills[index].id}-${session.setsLogged(index)}-${session.drills[index].defaultPrescription.sets}'),
                                        session: session.copyWith(drillIndex: index),
                                        active: _expanded && !_overview && !_detailsOpen && index == session.drillIndex,
                                        onSelect: _select,
                                        onShowDetails: () => _showDetails(session.drills[index]),
                                        actionNotifier: _drillAction,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // The one big action stays pinned in reach, however tall the drill or long the workout is. It waits
                    // until the sheet has room for it, so a half-dragged or collapsing sheet never has to squeeze it in.
                    if ((!_overview || session.finished) && box.maxHeight >= statusHeaderHeight + _actionBarHeight(context) + 160)
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                        child: ValueListenableBuilder<_DrillAction?>(
                          valueListenable: _drillAction,
                          builder: (context, action, _) {
                            final finishing = session.finished;
                            final label = finishing
                                ? (ref.watch(needsParentConfirmationProvider) ? 'Hand to a grown-up' : (ref.watch(sendsToGrownUpProvider) ? 'Send to a grown-up' : 'Finish workout'))
                                : action?.label;
                            final onPressed = finishing
                                ? () {
                                    if (ref.read(needsParentConfirmationProvider)) {
                                      context.go('/train/review');
                                      return;
                                    }
                                    ref.read(trainingSessionProvider.notifier).dismissFinishedWorkout();
                                    context.go('/summary');
                                  }
                                : action?.onPressed;
                            return FilledButton.icon(
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_actionHeight), textStyle: Theme.of(context).textTheme.titleMedium),
                              onPressed: onPressed,
                              icon: const Icon(Icons.check, size: 28),
                              label: Text(label ?? 'Done'),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The height of the big pinned action, the biggest thing on the screen on purpose: it has to be easy to hit.
const _actionHeight = 64.0;

double _actionBarHeight(BuildContext context) => _actionHeight + AppSpacing.sm + math.max(MediaQuery.paddingOf(context).bottom, AppSpacing.lg);

/// A strip with one segment per drill, filling as sets are done, so a player can see how far along they are
/// without reading anything.
class _DrillSteps extends StatelessWidget {
  const _DrillSteps({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSets = session.drills.fold<int>(0, (sum, drill) => sum + drill.defaultPrescription.sets);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xs),
      child: Semantics(
        label: 'Drill ${session.drillIndex + 1} of ${session.drills.length}, ${session.logs.length} of $totalSets sets done',
        child: SizedBox(
          height: 20,
          child: Row(
            key: const ValueKey('drill-steps'),
            children: [
              for (final (index, drill) in session.drills.indexed) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      height: index == session.drillIndex ? 10 : 6,
                      decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(5)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (session.setsLogged(index) / drill.defaultPrescription.sets).clamp(0, 1).toDouble(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final chosen = await showDrillPicker(
      context,
      title: 'Swap drill',
      excludeIds: session.drills.map((d) => d.id).toSet(),
      single: true,
      suggested: options,
      noSuggestionsNote: 'No other drills fit your setup right now. Change your setup on Train to see more.',
    );
    if (chosen != null && chosen.isNotEmpty && mounted) ref.read(trainingSessionProvider.notifier).swapDrill(index, chosen.single);
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
            label: _drillComplete ? 'Next drill' : 'Done',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // The demo is the biggest thing after the action, but never so tall that it pushes the controls away.
        final videoHeight = (constraints.maxHeight.isFinite ? constraints.maxHeight * .34 : 200.0).clamp(110.0, 260.0).toDouble();
        final cue = drill.formCues.isEmpty ? null : drill.formCues.first;
        final resting = widget.session.restEndsAt != null && widget.session.restEndsAt!.isAfter(clock.now().toUtc());
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(height: videoHeight, child: DrillMediaCard.forDrill(drill)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(drill.title, style: theme.textTheme.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(
                          _drillComplete ? 'All sets done' : 'Set ${widget.session.setIndex + 1} of ${drill.defaultPrescription.sets}',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_DrillMore>(
                    key: const ValueKey('drill-more-menu'),
                    tooltip: 'More options',
                    onSelected: (choice) => switch (choice) {
                      _DrillMore.details => widget.onShowDetails(),
                      _DrillMore.swap => _swapDrill(),
                      _DrillMore.rest => _startRest(),
                      _DrillMore.restSettings => showDrillRestSettings(context, drill),
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: _DrillMore.details, child: Text('Drill details')),
                      if (widget.session.setsLogged(widget.session.drillIndex) == 0) const PopupMenuItem(value: _DrillMore.swap, child: Text('Swap drill')),
                      if (!resting) const PopupMenuItem(value: _DrillMore.rest, child: Text('Start rest')),
                      const PopupMenuItem(value: _DrillMore.restSettings, child: Text('Rest settings')),
                    ],
                  ),
                ],
              ),
              if (cue != null && !_drillComplete) ...[const SizedBox(height: AppSpacing.xxs), Text(cue, style: theme.textTheme.bodyLarge)],
              const SizedBox(height: AppSpacing.md),
              if (_drillComplete)
                const TrainingCard(child: Text('Drill done! Tap Next drill.'))
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
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_countButtonHeight)),
                    onPressed: _toggleTimer,
                    icon: Icon(_countdown.isActive ? Icons.pause : Icons.play_arrow, size: 32),
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
      },
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
          child: Text('$_count', style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(_countButtonHeight)),
              onPressed: _count == 0 ? null : () => setState(() => _count--),
              child: const Icon(Icons.remove, size: 36, semanticLabel: 'Decrease count'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_countButtonHeight)),
              onPressed: _count == max ? null : () => setState(() => _count++),
              child: const Icon(Icons.add, size: 36, semanticLabel: 'Increase count'),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The height of the plus and minus buttons: big enough for a small child to hit without trying.
const _countButtonHeight = 72.0;

enum _DrillMore { details, swap, rest, restSettings }

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

List<Widget> _personalBests(BuildContext context, WidgetRef ref, TrainingSession session, bool saved) {
  final bests = bestsSetBy(ref.watch(progressStatsProvider), session, ref.watch(progressTuningProvider));
  if (bests.isEmpty) return const [];
  final theme = Theme.of(context);
  return [
    const SizedBox(height: AppSpacing.xl),
    SectionHeading(title: bests.length == 1 ? 'New personal best' : 'New personal bests'),
    const SizedBox(height: AppSpacing.md),
    for (final best in bests) ...[
      TrainingCard(
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(best.title, style: theme.textTheme.titleMedium)),
            Text(best.valueLabel, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
    ],
  ];
}

class SummaryPage extends ConsumerWidget {
  const SummaryPage({this.workoutId, super.key});

  Future<void> _repeat(BuildContext context, WidgetRef ref, TrainingSession workout) async {
    final active = ref.read(trainingSessionProvider);
    if (active.startedAt != null && !active.dismissed) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace your current workout?'),
          content: const Text('You have a workout in progress. Starting this one discards it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep current')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Start this one')),
          ],
        ),
      );
      if (replace != true || !context.mounted) return;
    }
    ref.read(trainingSessionProvider.notifier).start(workout.drills);
    context.go('/train/session');
  }

  Future<void> _saveAsRoutine(BuildContext context, WidgetRef ref, TrainingSession workout) async {
    try {
      final name = 'Repeat: ${workoutTitle(workout)}';
      await ref.read(routineLibraryProvider.notifier).save(RoutinePlan(id: 'routine-${DateTime.now().microsecondsSinceEpoch}', name: name, drills: workout.drills));
      if (context.mounted) showFeatureMessage(context, 'Saved "$name" to My routines.');
    } on StateError catch (error) {
      if (context.mounted) showFeatureMessage(context, error.message);
    } on PlatformException catch (error) {
      if (context.mounted) showFeatureMessage(context, 'Couldn\'t save routine: ${error.message ?? error.code}');
    }
  }

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
    final waitingForGrownUp = ref.watch(workoutSyncProvider)["${session.startedAt!.millisecondsSinceEpoch}"]?.pending ?? false;
    return AppPage(
      title: saved ? 'Workout summary' : 'You showed up.',
      subtitle: saved ? '${workoutDateLabel(session.startedAt!.toLocal(), clock.now())} · ${workoutTitle(session)}' : 'That’s how you get better.',
      action: FilledButton(onPressed: () => context.go(saved ? '/progress' : '/train'), child: Text(saved ? 'Back to Progress' : 'Back to Train')),
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
        if (waitingForGrownUp) ...[
          const SizedBox(height: AppSpacing.md),
          TrainingCard(
            child: Row(
              children: [
                Icon(Icons.hourglass_top, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(child: Text('Waiting for a grown-up to check it. Then it counts!')),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => showShareSheet(
            context,
            data: workoutCard(
              shots: shots,
              activeSeconds: session.activeSeconds,
              drills: session.drills.length,
              sets: session.logs.length,
              bests: bestsSetBy(ref.read(progressStatsProvider), session, ref.read(progressTuningProvider)),
              streakDays: ref.read(progressStatsProvider).add(session.toRecord(), tuning: ref.read(progressTuningProvider)).stats.currentStreak(clock.now()),
              dateLabel: workoutDateLabel(session.startedAt!.toLocal(), clock.now()),
            ),
            fileStem: 'how-to-hockey-workout',
          ),
          icon: const Icon(Icons.ios_share),
          label: const Text('Share this workout'),
        ),
        if (!waitingForGrownUp) ..._personalBests(context, ref, session, saved),
        if (saved) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(onPressed: () => _repeat(context, ref, session), icon: const Icon(Icons.replay), label: const Text('Repeat this workout')),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(onPressed: () => _saveAsRoutine(context, ref, session), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('Save as routine')),
        ],
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
