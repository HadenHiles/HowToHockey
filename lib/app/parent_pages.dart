import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import 'app_page.dart';

class ParentKid {
  const ParentKid({required this.id, required this.initials, required this.name, required this.team, required this.age, this.hiddenFromLeaderboards = false, this.pendingVerification = 0});

  final String id;
  final String initials;
  final String name;
  final String? team;
  final String age;
  final bool hiddenFromLeaderboards;
  final int pendingVerification;

  ParentKid copyWith({bool? hiddenFromLeaderboards}) =>
      ParentKid(id: id, initials: initials, name: name, team: team, age: age, hiddenFromLeaderboards: hiddenFromLeaderboards ?? this.hiddenFromLeaderboards, pendingVerification: pendingVerification);
}

// Local sample children; replaced by profile data when Phase 4 is built.
class ParentKids extends Notifier<List<ParentKid>> {
  @override
  List<ParentKid> build() => const [
    ParentKid(id: 'avery', initials: 'AH', name: 'Avery H.', team: 'Northside Novas · U12', age: 'Age 11', pendingVerification: 2),
    ParentKid(id: 'riley', initials: 'RH', name: 'Riley H.', team: null, age: 'Age 9', pendingVerification: 1),
  ];

  void setHidden(String id, bool hidden) => state = [
    for (final kid in state)
      if (kid.id == id) kid.copyWith(hiddenFromLeaderboards: hidden) else kid,
  ];
}

final parentKidsProvider = NotifierProvider<ParentKids, List<ParentKid>>(ParentKids.new);

const _sampleRequests = [(name: 'Riley H.', detail: 'Wants to join Westside Wolves · U10'), (name: 'Avery H.', detail: 'New device sign-in request · Kid tablet')];

const _sampleVerifications = [
  (kidId: 'avery', title: 'Wrist Shot Ladder', detail: 'Today · 20 min · 60 shots'),
  (kidId: 'avery', title: 'Stickhandling Box', detail: 'Yesterday · 15 min'),
  (kidId: 'riley', title: 'Edge Control Circuit', detail: 'Tuesday · 25 min'),
];

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
    return AppPage(
      title: 'Kids',
      children: [
        const _SampleNotice('Parent screens use representative local sample data. Approvals, pairing, and profile changes are not connected yet.'),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(title: 'Your players', action: 'Add child', onAction: () => showFeatureMessage(context, 'Creating child profiles is not connected yet.')),
        const SizedBox(height: AppSpacing.md),
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
        _ActionCard(icon: Icons.how_to_reg_outlined, title: 'Join approvals', detail: '${_sampleRequests.length} requests waiting', onTap: () => context.go('/parent/kids/approvals')),
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
    final theme = Theme.of(context);
    final kid = ref.watch(parentKidsProvider).where((k) => k.id == kidId).firstOrNull;
    if (kid == null) {
      return AppPage(
        title: 'Child not found',
        action: FilledButton(onPressed: () => context.go('/parent/kids'), child: const Text('Back to Kids')),
        children: const [Text('This child profile is unavailable.')],
      );
    }
    return AppPage(
      title: kid.name,
      subtitle: '${kid.age} · Child profile · sample',
      actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
      children: [
        ArenaPanel(
          child: Row(
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
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Training'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(
          icon: Icons.play_circle_outline,
          title: 'Train as ${kid.name}',
          detail: 'Opens Player mode',
          onTap: () {
            context.go('/train');
            showFeatureMessage(context, 'Player mode opened with the sample profile. Child profile switching is not connected yet.');
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.verified_outlined, title: 'Verify workouts', detail: '${kid.pendingVerification} waiting', onTap: () => context.go('/parent/verify')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Controls'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide from leaderboards'),
            subtitle: const Text('Team results will not show this player. Saved only until restart.'),
            value: kid.hiddenFromLeaderboards,
            onChanged: (value) => ref.read(parentKidsProvider.notifier).setHidden(kid.id, value),
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
        content: const Text('They will lose access to team homework and the locker room.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) showFeatureMessage(context, 'Team membership changes are not connected yet. Nothing was removed.');
  }
}

class ParentApprovalsPage extends StatelessWidget {
  const ParentApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Join approvals',
    subtitle: 'Children cannot join a team or sign in on a new device until you approve.',
    actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
    children: [
      for (final request in _sampleRequests) ...[
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.name, style: Theme.of(context).textTheme.titleMedium),
              Text(request.detail),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton(onPressed: () => showFeatureMessage(context, 'Approvals are not connected yet. Nothing was approved.'), child: const Text('Approve')),
                  OutlinedButton(onPressed: () => showFeatureMessage(context, 'Declining is not connected yet. Nothing was declined.'), child: const Text('Decline')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}

class KidPairingPage extends ConsumerWidget {
  const KidPairingPage({required this.kidId, super.key});

  final String kidId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kid = ref.watch(parentKidsProvider).where((k) => k.id == kidId).firstOrNull;
    return AppPage(
      title: 'Pair a kid device',
      subtitle: kid == null ? null : 'This device will open Player mode for ${kid.name} only.',
      actions: [IconButton(tooltip: 'Back', icon: const Icon(Icons.close), onPressed: () => context.go(kid == null ? '/parent/kids' : '/parent/kids/${kid.id}'))],
      children: [
        ArenaPanel(
          child: Column(
            children: [
              Semantics(
                label: 'Sample pairing code 4 8 2 9 1 7, not valid',
                child: ExcludeSemantics(child: Text('482 917', style: theme.textTheme.displaySmall)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('SAMPLE CODE · NOT VALID', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SampleNotice('Real codes will be short-lived. The paired device will have no access to Parent, billing, or account deletion.'),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(onPressed: () => showFeatureMessage(context, 'Pairing codes are not connected yet.'), child: const Text('Generate new code')),
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
    subtitle: 'Pick a workout to do side by side. Each of you logs your own sets.',
    actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
    action: FilledButton(onPressed: () => showFeatureMessage(context, 'Shared workouts are not connected yet.'), child: const Text('Start together')),
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

class ParentVerifyPage extends ConsumerWidget {
  const ParentVerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kids = {for (final kid in ref.watch(parentKidsProvider)) kid.id: kid};
    return AppPage(
      title: 'Verify',
      subtitle: 'Confirm that your child completed these workouts. Verified work is marked on team results.',
      children: [
        for (final item in _sampleVerifications) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kids[item.kidId]?.name ?? 'Child', style: Theme.of(context).textTheme.labelSmall),
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                Text(item.detail),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton(onPressed: () => showFeatureMessage(context, 'Verification is not connected yet. Nothing was verified.'), child: const Text('Verify')),
                    OutlinedButton(onPressed: () => showFeatureMessage(context, 'Verification is not connected yet.'), child: const Text('Not completed')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class ParentAccountPage extends StatelessWidget {
  const ParentAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Account',
      children: [
        const _SampleNotice('Account, billing, and deletion use representative local screens and are not connected yet.'),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Mode'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(icon: Icons.sports_hockey, title: 'Switch to Player', detail: 'Currently in Parent mode', onTap: () => context.go('/train')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Account & billing'),
        const SizedBox(height: AppSpacing.md),
        _ActionCard(icon: Icons.person_outline, title: 'Account', detail: 'Anonymous sample session', onTap: () => showFeatureMessage(context, 'Sign-in and account linking are not connected yet.')),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.workspace_premium_outlined, title: 'Subscription', detail: 'Free plan', onTap: () => showFeatureMessage(context, 'Subscriptions are not connected yet.')),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(icon: Icons.restore, title: 'Restore purchases', detail: 'Recover a previous purchase', onTap: () => showFeatureMessage(context, 'Purchase restore is not connected yet.')),
        const SizedBox(height: AppSpacing.xl),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: () => showFeatureMessage(context, 'Account deletion is not connected yet. Nothing was deleted.'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete account'),
        ),
      ],
    );
  }
}
