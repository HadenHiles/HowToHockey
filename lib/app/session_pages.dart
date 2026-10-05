import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/theme/app_theme.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/models/drill.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'training_state.dart';

class SessionPage extends ConsumerWidget {
  const SessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trainingSessionProvider);
    if (session.finished) {
      return const SummaryPage();
    }
    return Theme(
      data: HockeyTheme.dark,
      child: _ActiveDrill(
        key: ValueKey('${session.drillIndex}-${session.setIndex}'),
        session: session,
      ),
    );
  }
}

class _ActiveDrill extends ConsumerStatefulWidget {
  const _ActiveDrill({required this.session, super.key});

  final TrainingSession session;

  @override
  ConsumerState<_ActiveDrill> createState() => _ActiveDrillState();
}

class _ActiveDrillState extends ConsumerState<_ActiveDrill> {
  Timer? _timer;
  int _count = 0;
  int _remaining = 0;
  bool _completed = false;
  bool _running = false;

  Drill get drill => widget.session.drill;
  bool get _timed => drill.trackingType == TrackingType.duration || drill.trackingType == TrackingType.density;
  bool get _canLog => !_timed || _remaining == 0;

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
    ref.read(trainingSessionProvider.notifier).logSet(
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
    final finished = ref.read(trainingSessionProvider).finished;
    context.pushReplacement(finished ? '/summary' : '/rest', extra: drill.defaultPrescription.restSeconds);
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
    final theme = Theme.of(context);
    final type = drill.trackingType;
    return AppPage(
      title: 'Drill ${widget.session.drillIndex + 1} of ${widget.session.drills.length}',
      action: FilledButton.icon(
        onPressed: _canLog ? _log : null,
        icon: const Icon(Icons.check),
        label: const Text('Log set'),
      ),
      children: [
        LinearProgressIndicator(
          value: widget.session.logs.length /
              widget.session.drills.fold<int>(0, (total, drill) => total + drill.defaultPrescription.sets),
        ),
        const SizedBox(height: AppSpacing.md),
        DrillMediaPlaceholder(title: drill.title, compact: true),
        const SizedBox(height: AppSpacing.xl),
        Text(drill.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text('Set ${widget.session.setIndex + 1} of ${drill.defaultPrescription.sets}', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xl),
        if (_timed) ...[
          Center(
            child: TrainingProgressRing(
              progress: 1 - _remaining / drill.defaultPrescription.seconds!,
              value: '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
              label: _remaining == 0 ? 'Set complete' : 'seconds remaining',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_remaining > 0)
            OutlinedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause timer' : 'Start timer'),
            ),
          if (type == TrackingType.density && _remaining == 0) ...[
            const SizedBox(height: AppSpacing.md),
            _counter('Shots in this window', 999),
          ],
        ] else if (type == TrackingType.binary)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Drill completed'),
            subtitle: const Text('Mark whether you finished this set.'),
            value: _completed,
            onChanged: (value) => setState(() => _completed = value),
          )
        else
          _counter(
            switch (type) {
              TrackingType.accuracy => 'Hits out of ${drill.defaultPrescription.reps}',
              TrackingType.streak => 'Best consecutive passes',
              _ => 'Reps completed',
            },
            type == TrackingType.accuracy ? drill.defaultPrescription.reps! : 999,
          ),
        if (type == TrackingType.accuracy) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${(_count / drill.defaultPrescription.reps! * 100).round()}% accuracy', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        ],
        if (type == TrackingType.density && _remaining == 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${(_count / drill.defaultPrescription.seconds! * 60).round()} shots / min', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Remember'),
        const SizedBox(height: AppSpacing.md),
        for (final cue in drill.formCues) ...[
          Text(cue, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
        ],
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
          return count == null || count < 0 || count > widget.max
              ? 'Enter a number from 0 to ${widget.max}.'
              : null;
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

class RestPage extends StatefulWidget {
  const RestPage({super.key, this.seconds = 45});

  final int seconds;

  @override
  State<RestPage> createState() => _RestPageState();
}

class _RestPageState extends State<RestPage> {
  Timer? _timer;
  late int _remaining;
  late int _total;

  @override
  void initState() {
    super.initState();
    _remaining = _total = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HockeyTheme.dark,
    child: AppPage(
      title: 'Breathe. Reset.',
      subtitle: 'Great work. Give yourself a moment.',
      action: FilledButton(
        onPressed: () => context.pushReplacement('/session'),
        child: Text(_remaining == 0 ? 'Next set' : 'Skip rest'),
      ),
      children: [
        Center(
          child: TrainingProgressRing(
            progress: _total == 0 ? 1 : 1 - _remaining / _total,
            value: '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
            label: _remaining == 0 ? 'Ready when you are' : 'rest remaining',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _remaining = (_remaining - 15).clamp(0, 600)),
              child: const Text('−15s'),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                _remaining = (_remaining + 15).clamp(0, 600);
                if (_remaining > _total) _total = _remaining;
              }),
              child: const Text('+15s'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const TrainingCard(child: Text('Stay loose\nShake out your hands, reset your pucks, and take one slow breath.')),
      ],
    ),
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
    final shots = session.logs.where((entry) =>
      session.drills.firstWhere((drill) => drill.id == entry.drillId).pillar == SkillPillar.shooting,
    ).fold(0, (total, entry) => total + (entry.log.reps ?? 0));
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
                for (final entry in session.logs.where((entry) => entry.drillId == drill.id))
                  Text('Set ${entry.log.setIndex + 1}: ${_logLabel(entry.log, drill.trackingType)}'),
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
