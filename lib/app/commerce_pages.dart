import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import 'app_page.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, this.coach = false});

  final bool coach;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  late var _coach = widget.coach;
  var _yearly = true;

  static const _playerFeatures = [
    (label: 'Lifetime totals', free: true),
    (label: 'Skill radar and PR Vault', free: false),
    (label: 'Session breakdown charts', free: false),
    (label: 'Pro drill media', free: false),
    (label: 'Unlimited saved routines', free: false),
  ];
  static const _coachFeatures = [
    (label: 'Roster up to 30 players', free: false),
    (label: 'Team routine builder', free: false),
    (label: 'Assign homework', free: false),
    (label: 'Compliance dashboard', free: false),
    (label: 'Everything in Player Pro', free: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = _coach ? _coachFeatures : _playerFeatures;
    final price = _coach ? (_yearly ? r'$99.99 / year' : r'$12.99 / month') : (_yearly ? r'$49.99 / year' : r'$7.99 / month');
    final name = _coach ? 'Coach Pro' : 'Player Pro';
    return AppPage(
      title: name,
      subtitle: 'Sample paywall. Prices match the plan but nothing can be purchased yet.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/me'))],
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(onPressed: () => showFeatureMessage(context, 'Purchases are not connected yet. Nothing was charged.'), child: Text('Start $name · $price')),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: () => showFeatureMessage(context, 'Purchase restore is not connected yet.'), child: const Text('Restore purchases')),
              TextButton(onPressed: () => showFeatureMessage(context, 'Subscription management is not connected yet.'), child: const Text('Manage subscription')),
            ],
          ),
        ],
      ),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Player Pro')),
            ButtonSegment(value: true, label: Text('Coach Pro')),
          ],
          selected: {_coach},
          onSelectionChanged: (value) => setState(() => _coach = value.first),
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Monthly')),
            ButtonSegment(value: true, label: Text('Yearly')),
          ],
          selected: {_yearly},
          onSelectionChanged: (value) => setState(() => _yearly = value.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Text('Free', style: theme.textTheme.labelLarge),
                  const SizedBox(width: AppSpacing.lg),
                  Text('Pro', style: theme.textTheme.labelLarge),
                ],
              ),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(child: Text(feature.label)),
                      Icon(feature.free ? Icons.check : Icons.remove, semanticLabel: feature.free ? 'Included in Free' : 'Not in Free'),
                      const SizedBox(width: AppSpacing.lg),
                      Icon(Icons.check, color: theme.colorScheme.primary, semanticLabel: 'Included in Pro'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_coach) const Text('Rostered players get a 30-day Player Pro month when they join a Coach Pro team.'),
      ],
    );
  }
}

class SampleProgram {
  const SampleProgram({required this.id, required this.title, required this.detail, required this.price, required this.days, this.owned = false, this.dayReached = 0});

  final String id;
  final String title;
  final String detail;
  final String price;
  final int days;
  final bool owned;
  final int dayReached;
}

const samplePrograms = [
  SampleProgram(id: 'shooting-30', title: '30 Days to a Harder Shot', detail: 'Daily shooting routines with a lesson from Coach Jeremy.', price: r'$29.99', days: 30, owned: true, dayReached: 3),
  SampleProgram(id: 'hands-21', title: 'Elite Hands in 21 Days', detail: 'Stickhandling progressions from basics to game speed.', price: r'$19.99', days: 21),
  SampleProgram(id: 'power-skating-14', title: 'Power Skating Kickstart', detail: 'Two weeks of edges, crossovers, and explosive starts.', price: r'$14.99', days: 14),
];

SampleProgram? programById(String id) => samplePrograms.where((p) => p.id == id).firstOrNull;

class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Programs',
      subtitle: 'Signature programs are bought once and yours to keep. Sample catalog only.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/train'))],
      children: [
        for (final program in samplePrograms) ...[
          TrainingCard(
            onTap: () => context.push('/programs/${program.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrillMediaPlaceholder(title: 'Program preview', compact: true),
                const SizedBox(height: AppSpacing.md),
                Text(program.title, style: theme.textTheme.titleMedium),
                Text(program.detail, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(program.owned ? 'Owned · Day ${program.dayReached} of ${program.days}' : '${program.days} days · ${program.price}', style: theme.textTheme.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class ProgramDetailPage extends StatelessWidget {
  const ProgramDetailPage({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context) {
    final program = programById(programId);
    if (program == null) {
      return AppPage(
        title: 'Program not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('This program is unavailable.')],
      );
    }
    final theme = Theme.of(context);
    return AppPage(
      title: program.title,
      actions: [IconButton(tooltip: 'Back to Programs', icon: const Icon(Icons.close), onPressed: () => context.go('/programs'))],
      action: program.owned
          ? FilledButton(onPressed: () => context.push('/programs/${program.id}/day/${program.dayReached}'), child: Text('Continue · Day ${program.dayReached}'))
          : FilledButton(onPressed: () => showFeatureMessage(context, 'Purchases are not connected yet. Nothing was charged.'), child: Text('Buy for ${program.price}')),
      children: [
        const DrillMediaPlaceholder(title: 'Program trailer'),
        const SizedBox(height: AppSpacing.md),
        Text(program.detail),
        if (program.owned) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: program.dayReached / program.days, semanticsLabel: 'Day ${program.dayReached} of ${program.days}'),
          const SizedBox(height: AppSpacing.xs),
          Text('Day ${program.dayReached} of ${program.days}', style: theme.textTheme.bodySmall),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Pro members see a 20% discount once purchases are connected.', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Plan'),
        const SizedBox(height: AppSpacing.md),
        for (var day = 1; day <= 5; day++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(program.owned && day <= program.dayReached ? Icons.play_circle_outline : Icons.lock_outline),
            title: Text('Day $day'),
            subtitle: Text(day == 1 ? 'Free preview' : (program.owned ? 'Included' : 'Unlocks with purchase')),
            onTap: () {
              if (day == 1 || (program.owned && day <= program.dayReached)) {
                context.push('/programs/${program.id}/day/$day');
              } else {
                showFeatureMessage(context, program.owned ? 'Reach this day by finishing the earlier days.' : 'Buy this program to unlock this day.');
              }
            },
          ),
        Text('… and ${program.days - 5} more days', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class ProgramDayPage extends StatelessWidget {
  const ProgramDayPage({required this.programId, required this.day, super.key});

  final String programId;
  final int day;

  @override
  Widget build(BuildContext context) {
    final program = programById(programId);
    if (program == null || day < 1 || day > program.days) {
      return AppPage(
        title: 'Day not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('This program day is unavailable.')],
      );
    }
    final theme = Theme.of(context);
    return AppPage(
      title: 'Day $day of ${program.days}',
      subtitle: program.title,
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
      action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Open workout in Train')),
      children: [
        TrainingCard(
          onTap: () => context.push('/programs/$programId/day/$day/lesson'),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch the lesson', style: theme.textTheme.titleMedium),
                    Text('Coach Jeremy · 8 min', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: "Today's routine"),
        const SizedBox(height: AppSpacing.md),
        const TrainingCard(child: Text('3 drills · 25 min. The workout opens in Train with sample content until programs are connected.')),
      ],
    );
  }
}

class ProgramLessonPage extends StatelessWidget {
  const ProgramLessonPage({required this.programId, required this.day, super.key});

  final String programId;
  final int day;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Day $day lesson',
    subtitle: programById(programId)?.title,
    actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
    children: [
      const DrillMediaPlaceholder(title: 'Lesson video'),
      const SizedBox(height: AppSpacing.md),
      const Text('Sample lesson placeholder. Real lesson video will play from a signed link after the entitlement check.'),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Key cues'),
      const SizedBox(height: AppSpacing.sm),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Load the stick early')),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Shift weight through the shot')),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Follow through to the target')),
    ],
  );
}
