import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/profiles/active_player.dart';
import '../features/profiles/display_name.dart';
import '../features/profiles/player_profile.dart';
import '../features/profiles/profile_repository.dart';
import 'account_pages.dart';
import 'app_page.dart';

class ParentKid {
  const ParentKid({required this.id, required this.initials, required this.name, required this.team, required this.age, this.hiddenFromLeaderboards = false});

  final String id;
  final String initials;
  final String name;
  final String? team;
  final String age;
  final bool hiddenFromLeaderboards;

  factory ParentKid.fromProfile(PlayerProfile profile, {required DateTime now, bool hidden = false}) {
    return ParentKid(id: profile.id, initials: initialsOf(profile.displayName), name: profile.displayName, team: null, age: 'Age ${now.year - profile.birthYear}', hiddenFromLeaderboards: hidden);
  }
}

// Kept until you restart the app; saving this to the account comes with team settings.
class HiddenKids extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void setHidden(String id, bool hidden) => state = hidden ? {...state, id} : ({...state}..remove(id));
}

final hiddenKidsProvider = NotifierProvider<HiddenKids, Set<String>>(HiddenKids.new);

final parentKidsProvider = Provider<List<ParentKid>>((ref) {
  final hidden = ref.watch(hiddenKidsProvider);
  final profiles = ref.watch(childProfilesProvider).value ?? const <PlayerProfile>[];
  return [for (final profile in profiles) ParentKid.fromProfile(profile, now: clock.now(), hidden: hidden.contains(profile.id))];
});

class _SampleNotice extends StatelessWidget {
  const _SampleNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => TrainingCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.detail, required this.onTap});

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TrainingCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class ParentKidsPage extends ConsumerWidget {
  const ParentKidsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kids = ref.watch(parentKidsProvider);
    final profiles = ref.watch(childProfilesProvider);
    final signedIn = ref.watch(authStateProvider).value is SignedInAccount;
    return AppPage(
      title: 'Kids',
      children: [
        SectionHeading(title: 'Your players', action: kids.length >= maxChildProfiles ? null : 'Add child', onAction: () => context.go('/parent/kids/add')),
        const SizedBox(height: AppSpacing.md),
        if (!signedIn)
          const _SampleNotice('Create an account to add child profiles. Guests can\'t manage kids.')
        else if (profiles.hasError)
          const _SampleNotice('We couldn\'t load your kids. Check your connection and try again.')
        else if (profiles.isLoading && kids.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (kids.isEmpty)
          const TrainingCard(child: Text('No child profiles yet. Tap Add child to set up your first player.')),
        if (kids.length >= maxChildProfiles) const _SampleNotice('You\'ve added the most child profiles an account can have ($maxChildProfiles).'),
        for (final kid in kids) ...[
          TrainingCard(
            onTap: () => context.go('/parent/kids/${kid.id}'),
            child: Semantics(
              label: '${kid.name}, ${kid.age}, ${kid.team ?? 'no team'}',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(kid.initials, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kid.name, style: theme.textTheme.titleMedium),
                        Text('${kid.age} · ${kid.team ?? 'No team yet'}', style: theme.textTheme.bodySmall),
                        if (kid.hiddenFromLeaderboards) Text('Hidden from leaderboards', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        _ActionCard(icon: Icons.how_to_reg_outlined, title: 'Join approvals', detail: 'Team joins and new devices', onTap: () => context.go('/parent/kids/approvals')),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.sports_hockey, title: 'Train Together', detail: 'Do a workout alongside your child', onTap: () => context.go('/parent/kids/train-together')),
      ],
    );
  }
}

class ParentChildPage extends ConsumerWidget {
  const ParentChildPage({required this.kidId, super.key});

  final String kidId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(parentKidsProvider).where((k) => k.id == kidId).firstOrNull;
    if (kid == null) {
      return AppPage(
        title: 'Child not found',
        action: FilledButton(onPressed: () => context.go('/parent/kids'), child: const Text('Back to Kids')),
        children: const [Text('We can\'t find this child profile.')],
      );
    }
    return AppPage(
      title: kid.name,
      subtitle: '${kid.age} · Child profile',
      actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
      children: [
        ArenaPanel(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(kid.initials, style: theme.textTheme.titleLarge),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(kid.team ?? 'Not on a team yet', style: theme.textTheme.titleMedium)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Training'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(
          icon: Icons.play_circle_outline,
          title: 'Train as ${kid.name}',
          detail: 'Opens Player mode as ${kid.name}',
          onTap: () {
            ref.read(activePlayerIdProvider.notifier).choose(kid.id);
            context.go('/train');
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.verified_outlined, title: 'Verify workouts', detail: 'Confirm finished workouts', onTap: () => context.go('/parent/verify')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Controls'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide from leaderboards'),
            subtitle: const Text('Team results won\'t show this player. Only kept until you restart the app.'),
            value: kid.hiddenFromLeaderboards,
            onChanged: (value) => ref.read(hiddenKidsProvider.notifier).setHidden(kid.id, value),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (kid.team != null) ...[
          OutlinedButton.icon(onPressed: () => _confirmRemove(context, kid), icon: const Icon(Icons.exit_to_app), label: const Text('Remove from team')),
          const SizedBox(height: AppSpacing.sm),
        ],
        _ActionCard(icon: Icons.tablet_mac_outlined, title: 'Pair a kid device', detail: 'Lock a device to ${kid.name}', onTap: () => context.go('/parent/kids/${kid.id}/pair')),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, ParentKid kid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${kid.name} from the team?'),
        content: const Text('They\'ll lose access to team homework and the locker room.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) showFeatureMessage(context, 'Team changes aren\'t live yet. Nothing was removed.');
  }
}

class ParentApprovalsPage extends StatelessWidget {
  const ParentApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Join approvals',
    subtitle: 'Kids can\'t join a team or sign in on a new device until you approve.',
    actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
    children: const [TrainingCard(child: Text('No requests waiting. Team joins and device sign-ins will show up here for you to approve.'))],
  );
}

class KidPairingPage extends ConsumerStatefulWidget {
  const KidPairingPage({required this.kidId, super.key});

  final String kidId;

  @override
  ConsumerState<KidPairingPage> createState() => _KidPairingPageState();
}

class _KidPairingPageState extends ConsumerState<KidPairingPage> {
  PairingCode? _code;
  var _busy = false;
  String? _error;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref.read(profileRepositoryProvider).createPairingCode(widget.kidId);
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      if (mounted) setState(() => _code = code);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(parentKidsProvider).where((k) => k.id == widget.kidId).firstOrNull;
    final code = _code;
    final remaining = code?.expiresAt.difference(clock.now());
    final live = code != null && remaining != null && !remaining.isNegative;
    return AppPage(
      title: 'Pair a kid device',
      subtitle: kid == null ? null : 'This device will open Player mode for ${kid.name} only.',
      actions: [IconButton(tooltip: 'Back', icon: const Icon(Icons.close), onPressed: () => context.go(kid == null ? '/parent/kids' : '/parent/kids/${kid.id}'))],
      children: [
        if (kid != null)
          ArenaPanel(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Column(
                  children: [
                    if (live) ...[
                      Semantics(
                        label: 'Pairing code ${code.code.split('').join(' ')}',
                        child: ExcludeSemantics(child: Text(code.spaced, style: theme.textTheme.displaySmall)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Works once. Expires in ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}', style: theme.textTheme.labelSmall),
                    ] else
                      Text(code == null ? 'No code yet' : 'That code expired', style: theme.textTheme.titleMedium),
                  ],
                );
              },
            ),
          )
        else
          const Text('We can\'t find this child profile.'),
        const SizedBox(height: AppSpacing.md),
        const _SampleNotice('On your child\'s device, open How To Hockey and choose "Set up a kid\'s device". A paired device only opens Player mode for this child.'),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (kid != null) FilledButton(onPressed: _busy ? null : _generate, child: Text(_busy ? 'Making a code…' : (code == null ? 'Make a code' : 'Make a new code'))),
      ],
    );
  }
}

class ParentTrainTogetherPage extends StatefulWidget {
  const ParentTrainTogetherPage({super.key});

  @override
  State<ParentTrainTogetherPage> createState() => _ParentTrainTogetherPageState();
}

class _ParentTrainTogetherPageState extends State<ParentTrainTogetherPage> {
  var _selected = 0;

  static const _options = [
    (title: 'Backyard Shooting Basics', detail: '3 drills · 25 min'),
    (title: 'Stickhandling Warm-up', detail: '4 drills · 20 min'),
    (title: 'Skate & Shoot Circuit', detail: '5 drills · 35 min'),
  ];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Train Together',
    subtitle: 'Pick a workout to do side by side. You each log your own sets.',
    actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
    action: FilledButton(onPressed: () => showFeatureMessage(context, 'Shared workouts aren\'t live yet. Nothing was started.'), child: const Text('Start together')),
    children: [
      RadioGroup<int>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value ?? _selected),
        child: Column(
          children: [for (final (index, option) in _options.indexed) RadioListTile<int>(value: index, title: Text(option.title), subtitle: Text(option.detail))],
        ),
      ),
    ],
  );
}

class ParentVerifyPage extends StatelessWidget {
  const ParentVerifyPage({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(
    title: 'Verify',
    subtitle: 'Confirm your child finished their workouts. Verified work is marked on team results.',
    children: [TrainingCard(child: Text('Nothing to verify yet. Finished workouts will show up here once your child trains on their own device.'))],
  );
}

class ParentAccountPage extends ConsumerWidget {
  const ParentAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Account',
      children: [
        const _SampleNotice('You\'re looking at a preview. Billing goes live soon.'),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Mode'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(icon: Icons.sports_hockey, title: 'Switch to Player', detail: 'Currently in Parent mode', onTap: () => context.go('/train')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Account & billing'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(
          icon: Icons.person_outline,
          title: 'Account',
          detail: switch (ref.watch(authStateProvider).value) {
            SignedInAccount(:final email) => email ?? 'Signed in',
            _ => 'Guest session',
          },
          onTap: () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (sheetContext) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
                child: AccountSummary(
                  onNavigate: (route) {
                    Navigator.of(sheetContext).pop();
                    context.push(route);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.workspace_premium_outlined, title: 'Subscription', detail: 'Free plan', onTap: () => context.push('/paywall')),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.restore,
          title: 'Restore purchases',
          detail: 'Get back a past purchase',
          onTap: () => showFeatureMessage(context, 'Restoring purchases isn\'t live yet. You weren\'t charged.'),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (ref.watch(authStateProvider).value is SignedInAccount)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => unawaited(confirmAndDeleteAccount(context, ref)),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete account'),
          ),
      ],
    );
  }
}
