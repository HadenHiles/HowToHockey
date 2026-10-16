import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/models/drill.dart';
import 'app_page.dart';
import 'training_state.dart';

const _maxShots = 9999;

/// Starting a manual log would replace a workout that is still in progress, so ask first.
Future<bool> confirmReplaceWorkout(BuildContext context, WidgetRef ref) async {
  final session = ref.read(trainingSessionProvider);
  final inProgress = session.startedAt != null && !session.dismissed && !session.finished;
  if (!inProgress) return true;
  final replace = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('End your current workout?'),
      content: const Text('You have a workout in progress. Starting this will end it, and the sets you logged will be lost.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep workout')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('End it')),
      ],
    ),
  );
  return replace ?? false;
}

/// A one-set stand-in drill so manual work flows through the same saved, summarised session.
Drill manualDrill({required String id, required String title, required TrackingType type, required SkillPillar pillar, required DrillPrescription prescription, required int estimatedSeconds}) =>
    Drill(
      id: id,
      title: title,
      mediaAssetPath: 'placeholder/$id',
      formCues: const ['Log it as you go, or after you finish.'],
      trackingType: type,
      allowedLocations: LocationOption.values,
      minPuckInventory: PuckInventory.low,
      requiresPasser: false,
      skillWeights: {pillar: 1},
      tier: AccessTier.free,
      supportedBalls: const [],
      passerTypes: const [],
      defaultPrescription: prescription,
      estimatedSecondsPerSet: estimatedSeconds,
      difficulty: 1,
      tags: const ['manual'],
    );

/// Log shots you already took, with or without how many hit. No routine needed.
class ShotLoggerPage extends ConsumerStatefulWidget {
  const ShotLoggerPage({super.key});

  @override
  ConsumerState<ShotLoggerPage> createState() => _ShotLoggerPageState();
}

class _ShotLoggerPageState extends ConsumerState<ShotLoggerPage> {
  var _shots = 0;
  var _hits = 0;
  var _trackHits = false;

  void _setShots(int value) => setState(() {
    _shots = value.clamp(0, _maxShots);
    if (_hits > _shots) _hits = _shots;
  });

  Future<void> _enter(String label, int current, int max, ValueChanged<int> onChanged) async {
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _NumberEntryDialog(label: label, initial: current, max: max),
    );
    if (value != null) onChanged(value.clamp(0, max));
  }

  Future<void> _log() async {
    if (!await confirmReplaceWorkout(context, ref)) return;
    if (!mounted) return;
    final notifier = ref.read(trainingSessionProvider.notifier);
    final drill = manualDrill(
      id: _trackHits ? 'manual-shots-accuracy' : 'manual-shots',
      title: _trackHits ? 'Shot logger · accuracy' : 'Shot logger',
      type: _trackHits ? TrackingType.accuracy : TrackingType.volume,
      pillar: _trackHits ? SkillPillar.shotAccuracy : SkillPillar.shotPower,
      prescription: DrillPrescription(sets: 1, reps: _shots),
      estimatedSeconds: (_shots * 6).clamp(30, 3600),
    );
    notifier.start([drill]);
    notifier.logSet(reps: _shots, hits: _trackHits ? _hits : null);
    notifier.dismissFinishedWorkout();
    context.go('/summary');
  }

  Widget _counter(String label, int value, int max, ValueChanged<int> onChanged, {List<int> quick = const []}) {
    final theme = Theme.of(context);
    return TrainingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(tooltip: 'One less', onPressed: value == 0 ? null : () => onChanged(value - 1), icon: const Icon(Icons.remove)),
              const SizedBox(width: AppSpacing.md),
              Semantics(
                button: true,
                label: '$label: $value. Tap to type a number.',
                child: InkWell(
                  onTap: () => _enter(label, value, max, onChanged),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text('$value', style: theme.textTheme.displayMedium),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.outlined(tooltip: 'One more', onPressed: value >= max ? null : () => onChanged(value + 1), icon: const Icon(Icons.add)),
            ],
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              children: [for (final amount in quick) ActionChip(label: Text('+$amount'), onPressed: value + amount > max ? null : () => onChanged(value + amount))],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Shot logger',
    subtitle: 'Took some shots on your own? Add them up here.',
    actions: [IconButton(tooltip: 'Back to Train', icon: const Icon(Icons.close), onPressed: () => context.go('/train'))],
    action: FilledButton(onPressed: _shots == 0 ? null : _log, child: Text(_shots == 0 ? 'Log shots' : 'Log $_shots ${_shots == 1 ? 'shot' : 'shots'}')),
    children: [
      _counter('Shots taken', _shots, _maxShots, _setShots, quick: const [5, 10, 25, 50]),
      const SizedBox(height: AppSpacing.md),
      TrainingCard(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Track hits too'),
          subtitle: const Text('Count how many hit your target to see your accuracy.'),
          value: _trackHits,
          onChanged: (value) => setState(() => _trackHits = value),
        ),
      ),
      if (_trackHits) ...[const SizedBox(height: AppSpacing.md), _counter('Hits', _hits, _shots, (value) => setState(() => _hits = value.clamp(0, _shots)))],
    ],
  );
}

/// A plain countdown for any practice block, with the same lead-in and cues as a drill.
class TimerSetupPage extends ConsumerStatefulWidget {
  const TimerSetupPage({super.key});

  @override
  ConsumerState<TimerSetupPage> createState() => _TimerSetupPageState();
}

class _TimerSetupPageState extends ConsumerState<TimerSetupPage> {
  static const _options = [30, 60, 120, 300, 600, 900, 1200];
  var _seconds = 60;

  static String _label(int seconds) => seconds < 60 ? '${seconds}s' : '${seconds ~/ 60} min';

  Future<void> _start() async {
    if (!await confirmReplaceWorkout(context, ref)) return;
    if (!mounted) return;
    final drill = manualDrill(
      id: 'manual-timer',
      title: 'Timer',
      type: TrackingType.duration,
      pillar: SkillPillar.endurance,
      prescription: DrillPrescription(sets: 1, seconds: _seconds),
      estimatedSeconds: _seconds,
    );
    ref.read(trainingSessionProvider.notifier).start([drill]);
    context.go('/train/session');
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Timer',
    subtitle: 'Pick how long you want to work. You get a 3-2-1 and a beep at the start and finish.',
    actions: [IconButton(tooltip: 'Back to Train', icon: const Icon(Icons.close), onPressed: () => context.go('/train'))],
    action: FilledButton(onPressed: _start, child: Text('Start ${_label(_seconds)} timer')),
    children: [
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final option in _options) ChoiceChip(label: Text(_label(option)), selected: _seconds == option, onSelected: (_) => setState(() => _seconds = option))],
      ),
    ],
  );
}

/// Owns its text controller so it is disposed only after the dialog has finished closing.
class _NumberEntryDialog extends StatefulWidget {
  const _NumberEntryDialog({required this.label, required this.initial, required this.max});

  final String label;
  final int initial;
  final int max;

  @override
  State<_NumberEntryDialog> createState() => _NumberEntryDialogState();
}

class _NumberEntryDialogState extends State<_NumberEntryDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial == 0 ? '' : '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
      decoration: InputDecoration(hintText: '0 to ${widget.max}'),
      onSubmitted: (text) => Navigator.of(context).pop(int.tryParse(text)),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.of(context).pop(int.tryParse(_controller.text)), child: const Text('Done')),
    ],
  );
}
