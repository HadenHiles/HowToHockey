import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_shapes.dart';
import '../design/tokens/app_spacing.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'training_state.dart';

class TrainPage extends ConsumerWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final setup = ref.watch(trainingSetupProvider);
    return AppPage(
      title: 'Train',
      appBarTitle: const BrandWordmark(),
      centerAppBarTitle: true,
      children: [
        TrainingHeroCard(
          eyebrow: 'Today on the ice',
          title: 'Build your\nfoundation',
          detail: 'A little better. Every day.',
          metrics: const [('20', 'minutes'), ('06', 'drills'), ('12', 'sets')],
          actionLabel: 'View workout',
          onTap: () => context.push('/routine'),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Your setup', action: 'Edit', onAction: () => context.push('/setup')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(label: Text(setup.location.label), avatar: const Icon(Icons.place_outlined), onPressed: () => context.push('/setup')),
            ActionChip(label: Text(setup.inventory.label), avatar: const Icon(Icons.sports_hockey_outlined), onPressed: () => context.push('/setup')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(onPressed: () => context.push('/setup'), icon: const Icon(Icons.tune), label: const Text('Build a workout')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(onPressed: () => context.push('/routines'), icon: const Icon(Icons.view_list_outlined), label: const Text('Manage routines')),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const TrainingProgressRing(progress: .6, value: '72', label: 'of 120 min this week'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_fire_department_outlined, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.xs),
                  Text('5-day streak', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Keep showing up.'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Explore drills', action: 'See all', onAction: () => context.push('/library')),
        const SizedBox(height: AppSpacing.md),
        for (final drill in sampleDrills.take(2)) ...[DrillListCard(drillId: drill.id), const SizedBox(height: AppSpacing.sm)],
        const SizedBox(height: AppSpacing.sm),
        Text('Just want to log?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ref.read(trainingSessionProvider.notifier).start([sampleDrills.first]);
                context.go('/train/session');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Shot logger'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(trainingSessionProvider.notifier).start([sampleDrills[1]]);
                context.go('/train/session');
              },
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Timer'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class DrillListCard extends StatelessWidget {
  const DrillListCard({required this.drillId, super.key});

  final String drillId;

  @override
  Widget build(BuildContext context) {
    final drill = sampleDrills.firstWhere((drill) => drill.id == drillId);
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return TrainingCard(
      onTap: () => context.push('/drills/$drillId'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(color: drill.pillar.color(pillars).withValues(alpha: .14), borderRadius: BorderRadius.circular(AppRadii.control)),
            child: Icon(drill.pillar.icon, size: 28, color: drill.pillar.color(pillars)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drill.pillar.label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: drill.pillar.color(pillars), letterSpacing: .8)),
                const SizedBox(height: AppSpacing.xs),
                Text(drill.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text('${drill.prescriptionLabel} · ${drill.trackingType.label}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.arrow_forward, color: theme.colorScheme.primary, size: 18),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return AppPage(
      title: 'Progress',
      subtitle: 'Your work is adding up.',
      children: [
        ArenaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS SEASON', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              Text('2,480', style: theme.textTheme.displayMedium),
              Text('SHOTS ON GOAL', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xl),
              const WeeklyTrainingChart(),
              const SizedBox(height: AppSpacing.md),
              Text('140 shots this week  ·  18.5 hours on ice', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Your skill map'),
        const SizedBox(height: AppSpacing.md),
        ArenaPanel(
          child: Column(
            children: [
              const SkillRadar(scores: [82, 68, 74, 57, 65, 61]),
              const SizedBox(height: AppSpacing.md),
              Text('ACCURACY IS YOUR TOP SKILL', style: theme.textTheme.labelMedium?.copyWith(color: pillars.shotAccuracy, letterSpacing: .6)),
              const SizedBox(height: AppSpacing.xs),
              Text('One more endurance session rounds out your game.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Personal bests'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            MetricTile(value: '84%', label: 'Shot accuracy', detail: 'Best session', accent: pillars.shotAccuracy),
            MetricTile(value: '47', label: 'Pass streak', detail: 'Clean touches', accent: pillars.passing),
            MetricTile(value: '5 days', label: 'Training streak', accent: pillars.speedStrength),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Lifetime totals'),
        const SizedBox(height: AppSpacing.md),
        const ArenaPanel(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _HistoryStat(value: '18.5 h', label: 'active hours'),
              _HistoryStat(value: '32', label: 'workouts'),
              _HistoryStat(value: '140', label: 'shots this week'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Recent training'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick hands, clean release', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('SAMPLE SESSION  ·  YESTERDAY', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.md),
                    const Text('24 active min · 80 shots · 4 drills · 6 sets'),
                    const SizedBox(height: AppSpacing.md),
                    const Text('This session is a design sample. Completed workouts are not saved to history yet.'),
                  ],
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Quick hands, clean release', style: Theme.of(context).textTheme.titleLarge)),
                  Icon(Icons.arrow_outward, color: Theme.of(context).colorScheme.primary, size: 18),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('YESTERDAY  ·  24 ACTIVE MIN', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.md),
              const Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.sm,
                children: [
                  _HistoryStat(value: '80', label: 'shots'),
                  _HistoryStat(value: '4', label: 'drills'),
                  _HistoryStat(value: '6', label: 'sets'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) {
              final colors = Theme.of(context).extension<AppColors>()!;
              final theme = Theme.of(context);
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Progress card preview', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? colors.surface : colors.textPrimary, borderRadius: BorderRadius.circular(AppRadii.card)),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HOW TO HOCKEY  ·  WEEKLY RECAP', style: theme.textTheme.labelSmall?.copyWith(color: colors.brandPrimaryOnDark)),
                              const SizedBox(height: AppSpacing.xl),
                              Text('140', style: theme.textTheme.displayMedium?.copyWith(color: theme.brightness == Brightness.dark ? colors.textPrimary : colors.brandCream)),
                              Text('SHOTS THIS WEEK', style: theme.textTheme.labelMedium?.copyWith(color: theme.brightness == Brightness.dark ? colors.textPrimary : colors.brandCream)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Preview only · Sample data · Sharing is not connected yet', style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              );
            },
          ),
          child: Row(
            children: [
              Icon(Icons.ios_share, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share your progress', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    const Text('A clean recap of the work you put in.'),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Progress is representative sample data. Workouts are not yet saved to history.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

enum _TeamPreviewState { member, noTeam, locked }

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  var _previewState = _TeamPreviewState.member;
  final Set<String> _sampleTaps = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Team',
      subtitle: _previewState == _TeamPreviewState.member ? 'North Stars · U15' : 'Find your locker room.',
      children: [
        TrainingCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: Text('Team content and actions are representative. Joining, invites, leaderboards, and stick taps are not connected yet.')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('PREVIEW TEAM STATE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: .8)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final state in _TeamPreviewState.values)
              ChoiceChip(
                label: Text(switch (state) {
                  _TeamPreviewState.member => 'Member',
                  _TeamPreviewState.noTeam => 'No team',
                  _TeamPreviewState.locked => 'Locked',
                }),
                selected: state == _previewState,
                onSelected: (_) => setState(() => _previewState = state),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ...switch (_previewState) {
          _TeamPreviewState.member => _memberContent(context),
          _TeamPreviewState.noTeam => _noTeamContent(context),
          _TeamPreviewState.locked => _lockedContent(context),
        },
      ],
    );
  }

  List<Widget> _memberContent(BuildContext context) {
    final theme = Theme.of(context);
    return [
      TrainingHeroCard(
        eyebrow: 'Coach Jeremy  ·  Due Friday',
        title: 'Team\nhomework',
        detail: 'Build your foundation',
        metrics: const [('20', 'minutes'), ('06', 'drills')],
        actionLabel: 'View assignment',
        onTap: () => context.push('/routine'),
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Locker room'),
      const SizedBox(height: AppSpacing.md),
      _TeamPostCard(
        initials: 'AR',
        name: 'Alex R.',
        update: 'Finished Build your foundation',
        detail: '24 active min  ·  80 shots  ·  5 day streak',
        tapCount: 8,
        tapped: _sampleTaps.contains('alex'),
        onTap: () => _toggleSampleTap(context, 'alex'),
      ),
      const SizedBox(height: AppSpacing.sm),
      _TeamPostCard(
        initials: 'MS',
        name: 'Morgan S.',
        update: 'Set a new accuracy best',
        detail: '84% accuracy  ·  Pick your corner',
        tapCount: 12,
        tapped: _sampleTaps.contains('morgan'),
        onTap: () => _toggleSampleTap(context, 'morgan'),
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Weekly leaderboard'),
      const SizedBox(height: AppSpacing.md),
      ArenaPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('ACTIVE TRAINING TIME', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: .8)),
                ),
                Text('THIS WEEK', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _LeaderboardRow(rank: 1, name: 'Morgan S.', minutes: 92),
            const _LeaderboardRow(rank: 2, name: 'Jamie H.', minutes: 76, isCurrentPlayer: true),
            const _LeaderboardRow(rank: 3, name: 'Alex R.', minutes: 64),
            const SizedBox(height: AppSpacing.sm),
            Text('Only verified active training time counts. Sample standings.', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeading(title: 'Team access', action: 'Find teams', onAction: () => _showTeamDiscovery(context)),
      const SizedBox(height: AppSpacing.md),
      TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('North Stars invite', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Share the coach-managed join code with a parent or teammate.', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showFeatureMessage(context, 'Invite sharing is a sample action and is not connected yet.'),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share invite'),
                ),
                TextButton.icon(onPressed: () => _showJoinInvite(context), icon: const Icon(Icons.key_outlined), label: const Text('Join with code')),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _noTeamContent(BuildContext context) {
    final theme = Theme.of(context);
    return [
      ArenaPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.groups_outlined, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Your next team starts here', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Discover a public team or review an invite from your coach. Team membership is managed per player profile.'),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(onPressed: () => _showTeamDiscovery(context), icon: const Icon(Icons.search), label: const Text('Find a team')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(onPressed: () => _showJoinInvite(context), icon: const Icon(Icons.key_outlined), label: const Text('Join with code')),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Pending invite'),
      const SizedBox(height: AppSpacing.md),
      TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Westside Wolves · U15', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            const Text('Invited by Coach Taylor. A parent approval is required for child profiles.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: () => showFeatureMessage(context, 'Invite review is not connected yet.'), child: const Text('Review invite')),
          ],
        ),
      ),
    ];
  }

  List<Widget> _lockedContent(BuildContext context) {
    final theme = Theme.of(context);
    return [
      ArenaPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Members only', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Locker room posts, homework, and team standings unlock after this player profile joins the team.'),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: () => setState(() => _previewState = _TeamPreviewState.noTeam), child: const Text('View joining options')),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      TrainingCard(
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            const Expanded(child: Text('Team activity is visible only to rostered members. Public discovery shows generic team details, not player activity.')),
          ],
        ),
      ),
    ];
  }

  void _toggleSampleTap(BuildContext context, String postId) {
    setState(() {
      if (!_sampleTaps.add(postId)) _sampleTaps.remove(postId);
    });
    showFeatureMessage(context, 'Sample preview only. Stick taps are not sent.');
  }

  Future<void> _showTeamDiscovery(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Discover teams', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Public team results use representative content. Player activity stays member-only.'),
            const SizedBox(height: AppSpacing.xl),
            _DiscoveryTeamCard(name: 'Westside Wolves', detail: 'U15 · Coach Taylor · 18 players', onRequest: () => _showUnavailableAction(sheetContext, 'Join requests are not connected yet.')),
            const SizedBox(height: AppSpacing.sm),
            _DiscoveryTeamCard(name: 'River City Rockets', detail: 'U14 · Coach Lee · 16 players', onRequest: () => _showUnavailableAction(sheetContext, 'Join requests are not connected yet.')),
          ],
        ),
      ),
    ),
  );

  Future<void> _showJoinInvite(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join with a team code', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('A constrained team-code entry will be connected with account and parent approval flows.'),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => _showUnavailableAction(sheetContext, 'Team-code lookup is not connected yet.'),
              icon: const Icon(Icons.key_outlined),
              label: const Text('Preview code lookup'),
            ),
          ],
        ),
      ),
    ),
  );

  void _showUnavailableAction(BuildContext sheetContext, String message) {
    Navigator.of(sheetContext).pop();
    showFeatureMessage(context, message);
  }
}

class _TeamPostCard extends StatelessWidget {
  const _TeamPostCard({required this.initials, required this.name, required this.update, required this.detail, required this.tapCount, required this.tapped, required this.onTap});

  final String initials;
  final String name;
  final String update;
  final String detail;
  final int tapCount;
  final bool tapped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TrainingCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, child: Text(initials)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: theme.textTheme.titleMedium)),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(update),
                const SizedBox(height: AppSpacing.xs),
                Text(detail, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(onPressed: onTap, icon: Icon(tapped ? Icons.sports_hockey : Icons.sports_hockey_outlined), label: Text('${tapCount + (tapped ? 1 : 0)} stick taps')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.name, required this.minutes, this.isCurrentPlayer = false});

  final int rank;
  final String name;
  final int minutes;
  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? theme.colorScheme.primary.withValues(alpha: .18) : theme.colorScheme.surface.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', style: theme.textTheme.titleMedium)),
          Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
          Text('$minutes min', style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _DiscoveryTeamCard extends StatelessWidget {
  const _DiscoveryTeamCard({required this.name, required this.detail, required this.onRequest});

  final String name;
  final String detail;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) => TrainingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(detail),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRequest, child: const Text('Request to join')),
      ],
    ),
  );
}

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  static const _profiles = [(initials: 'JH', name: 'Jamie H.', detail: 'Player profile'), (initials: 'AH', name: 'Avery H.', detail: 'Child profile · sample')];

  var _activeProfile = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    final profile = _profiles[_activeProfile];
    return AppPage(
      title: 'Me',
      children: [
        Semantics(
          button: true,
          label: 'Switch player profile. Current profile ${profile.name}',
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: _showProfileSwitcher,
            child: ArenaPanel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(profile.initials, style: theme.textTheme.titleLarge),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text('PLAYER  ·  SAMPLE PROFILE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.swap_horiz, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: Text('Profiles, roles, accounts, and subscriptions use representative local screens. They are not connected yet.')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Appearance'),
        const SizedBox(height: AppSpacing.sm),
        const Text('One app. Light, dark, or your device setting.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in AppAppearance.values)
              ChoiceChip(label: Text(option.label), selected: option == appearance, onSelected: (_) => unawaited(ref.read(appearanceProvider.notifier).setAppearance(option))),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data & services', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text('Screens currently use sample content. Workout results stay on this device until restart; history, team updates, and purchases are not connected yet.'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text('Appearance is saved to this device.', style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Profile & access'),
        const SizedBox(height: AppSpacing.md),
        _MeEntryCard(icon: Icons.people_outline, title: 'Switch player', detail: 'Active: ${profile.name}', onTap: _showProfileSwitcher),
        const SizedBox(height: AppSpacing.sm),
        _MeEntryCard(icon: Icons.switch_account_outlined, title: 'Switch role', detail: 'Player mode', onTap: _showRoleSwitcher),
        const SizedBox(height: AppSpacing.sm),
        _MeEntryCard(icon: Icons.person_outline, title: 'Account', detail: 'Anonymous sample session', onTap: _showAccount),
        const SizedBox(height: AppSpacing.sm),
        _MeEntryCard(icon: Icons.workspace_premium_outlined, title: 'Subscription', detail: 'Free plan', onTap: _showSubscription),
      ],
    );
  }

  Future<void> _showProfileSwitcher() => showModalBottomSheet<void>(
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
            Text('Switch player', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('The active profile is kept only for this preview session.'),
            const SizedBox(height: AppSpacing.md),
            RadioGroup<int>(
              groupValue: _activeProfile,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _activeProfile = value);
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                children: [for (final (index, profile) in _profiles.indexed) RadioListTile<int>(value: index, title: Text(profile.name), subtitle: Text(profile.detail))],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showRoleSwitcher() => showModalBottomSheet<void>(
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
            Text('Switch role', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Parent and Coach modes are sample previews.'),
            const SizedBox(height: AppSpacing.md),
            const ListTile(leading: Icon(Icons.sports_hockey), title: Text('Player'), subtitle: Text('Current role'), trailing: Icon(Icons.check)),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Parent'),
              subtitle: const Text('Sample preview'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go('/parent/kids');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Coach'),
              subtitle: const Text('Sample preview'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go('/coach/roster');
              },
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showAccount() => showModalBottomSheet<void>(
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
            Text('Account', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('This preview is using an anonymous session. Account linking and deletion are not connected yet.'),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(onPressed: () => _closeWithMessage(sheetContext, 'Account sign-in is not connected yet.'), icon: const Icon(Icons.login), label: const Text('Connect an account')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _closeWithMessage(sheetContext, 'Account deletion is not connected yet.'),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete account'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showSubscription() => showModalBottomSheet<void>(
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
            Text('Player Free', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('Player Pro purchase, restore, and subscription management will be connected through RevenueCat in the commerce slice.'),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: () => _closeWithMessage(sheetContext, 'Player Pro purchases are not connected yet.'), child: const Text('Explore Player Pro')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: () => _closeWithMessage(sheetContext, 'Purchase restore is not connected yet.'), child: const Text('Restore purchases')),
          ],
        ),
      ),
    ),
  );

  void _closeWithMessage(BuildContext sheetContext, String message) {
    Navigator.of(sheetContext).pop();
    showFeatureMessage(context, message);
  }
}

class _MeEntryCard extends StatelessWidget {
  const _MeEntryCard({required this.icon, required this.title, required this.detail, required this.onTap});

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TrainingCard(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
