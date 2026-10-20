import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_shapes.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_catalog.dart';
import '../features/drills/models/drill.dart';
import '../features/accounts/auth_service.dart';
import 'commerce_pages.dart';
import '../features/profiles/active_player.dart';
import '../features/profiles/display_name.dart';
import '../features/profiles/player_profile.dart';
import '../features/session/rest_notifications.dart';
import '../features/session/session_cues.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'sample_data.dart';
import 'app_page.dart';
import 'account_pages.dart';
import '../features/progress/progress_stats.dart';
import 'coach_state.dart';
import '../features/progress/drill_trends.dart';
import '../features/share/share_data.dart';
import 'progress_pages.dart';
import 'share_sheet.dart';
import 'progress_state.dart';
import 'progress_tuning.dart';
import 'workout_sync.dart';
import 'training_state.dart';
import 'workout_history.dart';

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
        _TodayWorkoutCard(),
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
        const _WeekCard(),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Explore drills', action: 'See all', onAction: () => context.push('/library')),
        const SizedBox(height: AppSpacing.md),
        for (final drill in sampleDrills.take(2)) ...[DrillListCard(drill: drill), const SizedBox(height: AppSpacing.sm)],
        const SizedBox(height: AppSpacing.sm),
        Text('Just want to log some work?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(onPressed: () => context.push('/log/shots'), icon: const Icon(Icons.add_circle_outline), label: const Text('Shot logger')),
            OutlinedButton.icon(onPressed: () => context.push('/log/timer'), icon: const Icon(Icons.timer_outlined), label: const Text('Timer')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class DrillListCard extends StatelessWidget {
  const DrillListCard({required this.drill, super.key});

  final Drill drill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    return TrainingCard(
      onTap: () => context.push('/drills/${drill.id}'),
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
                Text([drill.prescriptionLabel, ?drill.trackingNote].join(' · '), style: theme.textTheme.bodySmall),
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

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    final stats = ref.watch(progressStatsProvider);
    final pro = ref.watch(playerProProvider);
    final now = clock.now();
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    final week = stats.lastSevenDays(now);
    final busiest = week.fold(0.0, (most, day) => day.stats.seconds > most ? day.stats.seconds : most);
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final streak = stats.currentStreak(now);
    final focus = ref.watch(trainingFocusProvider);
    final tuning = ref.watch(progressTuningProvider);
    final scores = radarScores(stats, tuning);
    final topScore = scores.fold(0, (most, score) => score > most ? score : most);
    final focusTop = focus.values.fold(1, (most, points) => points > most ? points : most);
    final plan = [for (final pillar in SkillPillar.values) ((focus[pillar] ?? 0) / focusTop * (topScore < 20 ? 60 : topScore)).round()];
    final strongest = topScore == 0 ? null : SkillPillar.values[scores.indexOf(topScore)];
    return AppPage(
      title: 'Progress',
      subtitle: history.isEmpty && stats.workouts == 0 ? 'Finish a workout and your progress starts here.' : 'Your work is adding up.',
      children: [
        ArenaPanel(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALL TIME', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_grouped(stats.shots), style: theme.textTheme.displayMedium),
                  Text('SHOTS LOGGED', style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xl),
                  WeeklyTrainingChart(
                    values: [for (final day in week) busiest == 0 ? 0.0 : day.stats.seconds / busiest],
                    days: [for (final day in week) weekdays[day.day.weekday - 1]],
                    semanticLabel: 'Training this week. ${[for (final day in week) '${workoutDateLabel(day.day, now)} ${(day.stats.seconds / 60).round()} minutes'].join(', ')}.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('${stats.weekShots(now)} shots this week  ·  ${_duration(stats.weekSeconds(now))} active', style: theme.textTheme.bodySmall),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Your skill map'),
        const SizedBox(height: AppSpacing.md),
        ProLocked(
          unlocked: pro,
          message: 'See how every skill levels up with the time you put in.',
          child: ArenaPanel(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Column(
                  children: [
                    SkillRadar(scores: scores, plan: plan),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      strongest == null ? 'YOUR MAP FILLS IN AS YOU TRAIN' : '${strongest.label.toUpperCase()} IS YOUR TOP SKILL',
                      style: theme.textTheme.labelMedium?.copyWith(color: strongest?.color(pillars), letterSpacing: .6),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Each skill levels up with training time, 1 to 10. The grey outline is where your focus points want to put your time.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final pillar in SkillPillar.values)
              ActionChip(label: Text('${pillar.label} · Lv ${stats.levelOf(pillar, tuning).level}'), onPressed: pro ? () => _showSkill(context, ref, pillar) : null),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Personal bests'),
        const SizedBox(height: AppSpacing.md),
        ProLocked(
          unlocked: pro,
          message: 'Keep every personal best, with the date and the workout.',
          child: stats.bests.isEmpty
              ? const TrainingCard(child: Text('Your bests show up here as you log sets. Accuracy needs at least 10 shots in a set.'))
              : _PersonalBests(bests: stats.bests.values.toList()),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Your totals'),
        const SizedBox(height: AppSpacing.sm),
        const Text('From the workouts you\'ve finished on this device.'),
        const SizedBox(height: AppSpacing.md),
        ArenaPanel(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              HistoryStat(value: _duration(stats.seconds), label: 'active time'),
              HistoryStat(value: '${stats.workouts}', label: stats.workouts == 1 ? 'workout' : 'workouts'),
              HistoryStat(value: streak == 0 ? 'None' : '$streak ${streak == 1 ? 'day' : 'days'}', label: 'current streak'),
              HistoryStat(value: '${stats.longestStreak()} ${stats.longestStreak() == 1 ? 'day' : 'days'}', label: 'longest streak'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Drill by drill'),
        const SizedBox(height: AppSpacing.md),
        ProLocked(
          unlocked: pro,
          message: 'See how every drill has gone, workout by workout.',
          child: Builder(
            builder: (context) {
              final trends = drillTrends([for (final workout in history) workout.toRecord()]);
              if (trends.isEmpty) return const TrainingCard(child: Text('Finish a workout and each drill\'s results show up here.'));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final trend in trends.take(3)) ...[DrillTrendCard(trend: trend), const SizedBox(height: AppSpacing.sm)],
                  if (trends.length > 3) OutlinedButton(onPressed: () => context.push('/progress/drills'), child: Text('See all ${trends.length} drills')),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Recent training', action: history.length > 5 ? 'See all' : null, onAction: () => context.push('/history')),
        const SizedBox(height: AppSpacing.md),
        if (history.isEmpty)
          const TrainingCard(child: Text('No workouts yet. Finish one and it shows up here.'))
        else
          for (final workout in history.take(5)) ...[WorkoutHistoryCard(workout: workout), const SizedBox(height: AppSpacing.sm)],
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          onTap: () => showShareSheet(
            context,
            data: weekCard(stats: stats, now: now, dateLabel: 'Last 7 days'),
            fileStem: 'how-to-hockey-week',
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
        Text('Your progress is saved on this device for now. It moves to your account when workouts sync.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class HistoryStat extends StatelessWidget {
  const HistoryStat({required this.value, required this.label, super.key});

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

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    final kidDevice = ref.watch(authStateProvider).value is KidDeviceSession;
    final player = ref.watch(activePlayerProvider);
    final playerName = player?.displayName ?? 'Guest player';
    final playerLabel = switch (player) {
      null => 'GUEST  ·  CREATE AN ACCOUNT TO SET UP YOUR PROFILE',
      PlayerProfile(isChild: true) => 'CHILD PROFILE',
      _ => 'PLAYER',
    };
    return AppPage(
      title: 'Me',
      children: [
        Semantics(
          button: true,
          label: 'Switch player profile. Current profile $playerName',
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: _showProfileSwitcher,
            child: ArenaPanel(
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: Text(player == null ? '?' : initialsOf(player.displayName), style: theme.textTheme.titleLarge),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(playerName, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(playerLabel, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.swap_horiz, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  );
                },
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
              const Expanded(child: Text('Accounts, profiles and team membership are connected. Team feeds, standings and homework are still coming.')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Appearance'),
        const SizedBox(height: AppSpacing.sm),
        const Text('Light, dark, or match your device.'),
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
        const SectionHeading(title: 'Workout'),
        const SizedBox(height: AppSpacing.sm),
        TrainingCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sounds and haptics'),
            subtitle: const Text('Countdown beeps and rest chimes. They play alongside your music and stay quiet on silent.'),
            value: ref.watch(workoutCuesEnabledProvider),
            onChanged: (value) => unawaited(ref.read(workoutCuesEnabledProvider.notifier).set(value)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TrainingCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rest reminders'),
            subtitle: const Text('Get a notification when a rest ends and the app is in the background. We ask permission the first time you rest.'),
            value: ref.watch(restRemindersEnabledProvider),
            onChanged: (value) => unawaited(ref.read(restRemindersEnabledProvider.notifier).set(value)),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data & services', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text('Signed-in workouts sync to the active player profile. Guest workouts stay on this device.'),
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
        if (!kidDevice) ...[
          if (ref.watch(authStateProvider).value is SignedInAccount && !ref.watch(ownProfileProvider).isLoading && ref.watch(ownProfileProvider).value == null)
            _MeEntryCard(icon: Icons.person_add_outlined, title: 'Finish player setup', detail: 'Your account needs its own player profile', onTap: () => context.push('/profile/setup')),
          if (ref.watch(ownProfileProvider).hasError) TextButton(onPressed: () => ref.invalidate(ownProfileProvider), child: const Text('Could not load your profile. Retry')),
          _MeEntryCard(icon: Icons.people_outline, title: 'Switch player', detail: 'Active: $playerName', onTap: _showProfileSwitcher),
          const SizedBox(height: AppSpacing.sm),
          _MeEntryCard(icon: Icons.switch_account_outlined, title: 'Switch role', detail: 'Player mode', onTap: _showRoleSwitcher),
          const SizedBox(height: AppSpacing.sm),
        ],
        _MeEntryCard(
          icon: Icons.person_outline,
          title: 'Account',
          detail: switch (ref.watch(authStateProvider).value) {
            SignedInAccount(:final email) => email ?? 'Signed in',
            KidDeviceSession() => 'Kid device',
            _ => 'Guest session',
          },
          onTap: _showAccount,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MeEntryCard(icon: Icons.workspace_premium_outlined, title: 'Subscription', detail: kidDevice ? 'Managed by your parent' : planLabel(ref), onTap: _showSubscription),
        const SizedBox(height: AppSpacing.sm),
        _MeEntryCard(icon: Icons.school_outlined, title: 'Programs', detail: 'Signature programs from Coach Jeremy', onTap: () => context.push('/programs')),
        if (ref.watch(authStateProvider).value is! SignedInAccount && !kidDevice) ...[
          const SizedBox(height: AppSpacing.sm),
          _MeEntryCard(icon: Icons.waving_hand_outlined, title: 'Welcome & sign-up preview', detail: 'See the first-run screens', onTap: () => context.push('/welcome')),
        ],
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
            const Text('Each player keeps their own workouts and team memberships.'),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, _) {
                final players = ref.watch(switchablePlayersProvider);
                final active = ref.watch(activePlayerProvider);
                if (players.isEmpty) return const Text('Create an account to set up your player profile and add your kids.');
                return RadioGroup<String>(
                  groupValue: active?.id,
                  onChanged: (value) {
                    if (value == null) return;
                    if (switchPlayer(ref, context, value)) Navigator.of(sheetContext).pop();
                  },
                  child: Column(
                    children: [
                      for (final player in players) RadioListTile<String>(value: player.id, title: Text(player.displayName), subtitle: Text(player.isChild ? 'Child profile' : 'Player profile')),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showRoleSwitcher() {
    final signedIn = ref.read(authStateProvider).value is SignedInAccount;
    return _showRoleSheet(signedIn);
  }

  Future<void> _showRoleSheet(bool signedIn) => showModalBottomSheet<void>(
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
            Text(signedIn ? 'Choose which part of your account to manage.' : 'Parent and Coach need an account.'),
            const SizedBox(height: AppSpacing.md),
            const ListTile(leading: Icon(Icons.sports_hockey), title: Text('Player'), subtitle: Text('Current role'), trailing: Icon(Icons.check)),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Parent'),
              subtitle: Text(signedIn ? 'Add and manage your kids' : 'Needs an account'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go('/parent/kids');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Coach'),
              subtitle: Text(signedIn ? 'Manage your teams and roster' : 'Needs an account'),
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
            AccountSummary(
              onNavigate: (route) {
                Navigator.of(sheetContext).pop();
                context.push(route);
              },
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showSubscription() {
    final kidDevice = ref.read(authStateProvider).value is KidDeviceSession;
    final plan = planLabel(ref);
    final pro = plan != 'Free plan';
    return showModalBottomSheet<void>(
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
              Text(pro ? plan : 'Player Free', style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                kidDevice
                    ? 'A parent manages the plan from their own phone.'
                    : (pro ? 'Thanks for supporting How To Hockey.' : 'Player Pro unlocks the skill radar, PR Vault, session breakdowns and unlimited saved routines.'),
              ),
              if (!kidDevice) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/paywall');
                  },
                  child: Text(pro ? 'Manage plan' : 'Explore Player Pro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(restorePurchasesWithMessage(context, ref));
                  },
                  child: const Text('Restore purchases'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

class _TodayWorkoutCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(trainingFocusProvider);
    return switch (ref.watch(generatedRoutineProvider)) {
      AsyncData(:final value) when value.drills.isNotEmpty => TrainingHeroCard(
        eyebrow: 'Today\'s workout',
        title: routineTitle(focus),
        detail: routineDetail(focus),
        metrics: [('${value.estimatedMinutes}', 'minutes'), (value.drills.length.toString().padLeft(2, '0'), 'drills'), ('${value.totalSets}', 'sets')],
        actionLabel: 'View workout',
        onTap: () => context.push('/routine'),
      ),
      AsyncData() => TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Let\'s set up your workout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('No drills fit this setup yet. Try another place, more pucks, or a ball or passer.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: () => context.push('/setup'), child: const Text('Change my setup')),
          ],
        ),
      ),
      AsyncError() => TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We couldn\'t load today\'s workout. Check your connection and try again.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: () => ref.invalidate(drillCatalogProvider), child: const Text('Try again')),
          ],
        ),
      ),
      _ => const TrainingCard(
        child: Center(
          child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

String _grouped(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String _duration(double seconds) => seconds >= 3600 ? '${(seconds / 3600).toStringAsFixed(1)} h' : '${(seconds / 60).round()} min';

/// Shows [child] normally for Player Pro, and blurred behind an unlock prompt for everyone else.
class ProLocked extends StatelessWidget {
  const ProLocked({required this.unlocked, required this.message, required this.child, super.key});

  final bool unlocked;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (unlocked) return child;
    final theme = Theme.of(context);
    // A blurred peek at the real thing, then the prompt below it where it can take whatever room it needs.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: SizedBox(
            height: 140,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Opacity(opacity: .55, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text('Player Pro', style: theme.textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(onPressed: () => context.push('/paywall'), child: const Text('Unlock with Player Pro')),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalBests extends ConsumerWidget {
  const _PersonalBests({required this.bests});

  final List<PersonalBest> bests;

  static const _groups = [
    (PersonalBestKind.accuracy, 'Accuracy'),
    (PersonalBestKind.shotsPerMinute, 'Shots per minute'),
    (PersonalBestKind.streak, 'Streaks'),
    (PersonalBestKind.reps, 'Most reps in a set'),
    (PersonalBestKind.seconds, 'Longest timed set'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(workoutHistoryProvider.notifier);
    ref.watch(workoutHistoryProvider);
    final now = clock.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (kind, heading) in _groups)
          if (bests.any((b) => b.kind == kind)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(heading.toUpperCase(), style: theme.textTheme.labelSmall),
            ),
            for (final best in (bests.where((b) => b.kind == kind).toList()..sort((a, b) => b.value.compareTo(a.value)))) ...[
              TrainingCard(
                onTap: () => history.byId(best.workoutId) == null ? _showOlderBest(context, best) : context.push('/history/${best.workoutId}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(best.title, style: theme.textTheme.titleMedium),
                          Text(workoutDateLabel(best.achievedAt.toLocal(), now), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(best.valueLabel, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

void _showSkill(BuildContext context, WidgetRef ref, SkillPillar pillar) {
  final tuning = ref.read(progressTuningProvider);
  final level = ref.read(progressStatsProvider).levelOf(pillar, tuning);
  final top = topDrillsFor(pillar, ref.read(workoutHistoryProvider));
  final nextHours = level.level >= maxLevel ? null : (secondsForLevel(level.level + 1, tuning) - level.seconds) / 3600;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(pillar.label, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                level.level == 0 ? 'Level 0 · ${level.hours.toStringAsFixed(1)} h of training' : 'Level ${level.level} · ${level.hours.toStringAsFixed(1)} h of training',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: level.level >= maxLevel ? 1 : level.progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                nextHours == null
                    ? 'Top level. Keep it sharp.'
                    : nextHours < 1
                    ? 'About ${(nextHours * 60).ceil()} min to level ${level.level + 1}.'
                    : 'About ${nextHours.toStringAsFixed(1)} h to level ${level.level + 1}.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Top drills lately', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (top.isEmpty) const Text('Train this skill and your top drills show up here.') else for (final drill in top) Text('${drill.title} · ${(drill.seconds / 60).round()} min'),
            ],
          ),
        ),
      );
    },
  );
}

class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(progressStatsProvider);
    final now = clock.now();
    final minutes = (stats.weekSeconds(now) / 60).round();
    final streak = stats.currentStreak(now);
    final trainedToday = stats.days.containsKey(dayKey(now));
    return TrainingCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TrainingProgressRing(progress: (minutes / weeklyGoalMinutes).clamp(0.0, 1.0), value: '$minutes', label: 'of $weeklyGoalMinutes min this week'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_fire_department_outlined, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(streak == 0 ? 'No streak yet' : '$streak-day streak', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                streak == 0
                    ? 'Train today to start one.'
                    : trainedToday
                    ? 'Keep grinding.'
                    : 'Train today to keep it going.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A personal best from a workout that has aged out of the latest 60 kept on the device.
void _showOlderBest(BuildContext context, PersonalBest best) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(best.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('${best.valueLabel} · ${workoutDateLabel(best.achievedAt.toLocal(), clock.now())}', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text('That workout is older than the latest 60 kept on this device, so its full summary isn\'t available. The best itself is saved to your account.'),
            ],
          ),
        ),
      );
    },
  );
}
