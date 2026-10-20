import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/profiles/active_player.dart';
import '../features/teams/team_repository.dart';
import 'app_page.dart';

class TeamAction extends ConsumerStatefulWidget {
  const TeamAction({required this.label, required this.action, this.enabled = true, super.key});
  final String label;
  final Future<void> Function(WidgetRef ref) action;
  final bool enabled;

  @override
  ConsumerState<TeamAction> createState() => _TeamActionState();
}

class _TeamActionState extends ConsumerState<TeamAction> {
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.action(ref);
    } on TeamException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton(onPressed: _busy || !widget.enabled ? null : _run, child: Text(_busy ? 'Working...' : widget.label)),
      if (_error != null)
        Semantics(
          liveRegion: true,
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
    ],
  );
}

class TeamLoadError extends StatelessWidget {
  const TeamLoadError({required this.retry, super.key});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => TrainingCard(
    child: Column(
      children: [
        const Text('We could not load team data. Check your connection and try again.'),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}

class PlayerTeamsPage extends ConsumerWidget {
  const PlayerTeamsPage({this.profileId, super.key});
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    final profile = profileId == null ? ref.watch(activePlayerProvider) : ref.watch(switchablePlayersProvider).where((p) => p.id == profileId).firstOrNull;
    final teams = ref.watch(memberTeamsProvider);
    return AppPage(
      title: profileId == null ? 'Team' : '${profile?.displayName ?? 'Player'} teams',
      subtitle: profile == null ? 'Choose a player profile to join a team.' : 'Teams for ${profile.displayName}',
      children: [
        if (auth is SignedInAccount || auth is KidDeviceSession) ...[
          FilledButton(onPressed: () => context.push('/join${profile == null ? '' : '?profile=${profile.id}'}'), child: const Text('Join with code or invite')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => context.push('/teams/discover${profile == null ? '' : '?profile=${profile.id}'}'), child: const Text('Find a team')),
        ] else
          FilledButton(onPressed: () => context.push('/signup'), child: const Text('Create an account to join')),
        const SizedBox(height: AppSpacing.lg),
        if (teams.hasError)
          TeamLoadError(retry: () => ref.invalidate(memberTeamsProvider))
        else if (teams.isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (!(teams.value ?? []).any((t) => t.memberProfileIds.contains(profile?.id))) const TrainingCard(child: Text('No team yet for this player. Use your coach\'s code or find a public team.')),
          for (final team in teams.value ?? <Team>[])
            if (profile != null && team.memberProfileIds.contains(profile.id)) ...[
              TrainingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(team.name, style: Theme.of(context).textTheme.titleLarge),
                    Text('Coach: ${team.coachName}'),
                    Text('${team.memberCount} players'),
                    const Text('Feed, homework and standings are not available yet.'),
                    if (auth is SignedInAccount)
                      TeamAction(
                        label: 'Leave team',
                        action: (ref) async {
                          if (await _confirm(context, 'Leave ${team.name}?', 'This player keeps their training history.')) {
                            await ref.read(teamRepositoryProvider).remove(team.id, profile.id);
                          }
                        },
                      ),
                    if (auth is KidDeviceSession) const Text('Ask your parent to manage team membership.'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
  }
}

class JoinTeamPage extends ConsumerStatefulWidget {
  const JoinTeamPage({this.code = '', this.profileId, this.publicTeam, super.key});
  final String code;
  final String? profileId;
  final Team? publicTeam;
  @override
  ConsumerState<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends ConsumerState<JoinTeamPage> {
  late final _code = TextEditingController(text: widget.code);
  TeamInvitation? _invitation;
  String? _profileId;
  String? _status;
  bool _submitting = false;
  @override
  void initState() {
    super.initState();
    if (widget.code.isNotEmpty) {
      Future.microtask(() {
        if (mounted) ref.read(pendingTeamInviteProvider.notifier).remember(inviteCodeFrom(widget.code));
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    final players = ref.watch(switchablePlayersProvider);
    final selected = players.where((p) => p.id == (_profileId ?? widget.profileId)).firstOrNull ?? players.firstOrNull;
    final invitation = _invitation;
    final teamName = widget.publicTeam?.name ?? invitation?.name;
    return AppPage(
      title: 'Join a team',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.go('/team'))],
      children: [
        if (auth is! SignedInAccount && auth is! KidDeviceSession) ...[
          const Text('Sign in or create an account, then open this invitation again. Your code stays below.'),
          SelectableText(_code.text),
          FilledButton(onPressed: () => context.push('/signin'), child: const Text('Sign in')),
          OutlinedButton(onPressed: () => context.push('/signup'), child: const Text('Create account')),
        ] else if (_status != null) ...[
          TrainingCard(
            child: Text(switch (_status) {
              'joined' => 'Joined $teamName.',
              'coach' => 'You can now manage $teamName in Coach mode.',
              'parentPending' => 'Request sent to your parent for approval.',
              _ => 'Request sent. Waiting for a coach to approve.',
            }),
          ),
          FilledButton(onPressed: () => context.go(_status == 'coach' ? '/coach/team' : '/team'), child: const Text('Done')),
        ] else ...[
          if (widget.publicTeam == null) ...[
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Team code or invite link'),
              autocorrect: false,
              enabled: !_submitting,
              onChanged: (_) => setState(() => _invitation = null),
            ),
            TeamAction(
              label: 'Look up invitation',
              enabled: !_submitting,
              action: (ref) async {
                final input = _code.text;
                final found = await ref.read(teamRepositoryProvider).preview(input);
                if (mounted && _code.text == input) {
                  ref.read(pendingTeamInviteProvider.notifier).remember(inviteCodeFrom(input));
                  setState(() => _invitation = found);
                }
              },
            ),
          ],
          if (teamName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(teamName, style: Theme.of(context).textTheme.titleLarge),
            if (invitation?.kind == 'coach') ...[
              const Text('Coach access lets you manage this team and roster. This invitation is single use and expires after 24 hours. Adult accounts only.'),
              if (auth is SignedInAccount)
                TeamAction(
                  label: 'Accept coach invitation',
                  action: (ref) async {
                    setState(() => _submitting = true);
                    try {
                      await ref.read(teamRepositoryProvider).acceptCoach(_code.text);
                      if (mounted) {
                        ref.read(pendingTeamInviteProvider.notifier).clear();
                        setState(() => _status = 'coach');
                      }
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
                )
              else
                const Text('Ask an adult to open this coach invitation on their own account.'),
            ] else if (players.isEmpty)
              const Text('Finish setting up a player profile from Me, or add a child from Parent mode first.')
            else ...[
              DropdownButtonFormField<String>(
                key: ValueKey(selected?.id),
                initialValue: selected?.id,
                decoration: const InputDecoration(labelText: 'Player joining'),
                isExpanded: true,
                items: [for (final player in players) DropdownMenuItem(value: player.id, child: Text(player.displayName, maxLines: 1, overflow: TextOverflow.ellipsis))],
                onChanged: _submitting ? null : (id) => setState(() => _profileId = id),
              ),
              if (auth is KidDeviceSession) const Text('Your parent must approve before you join.'),
              TeamAction(
                label: widget.publicTeam != null ? 'Request to join' : 'Join team',
                action: (ref) async {
                  setState(() => _submitting = true);
                  try {
                    final status = await ref.read(teamRepositoryProvider).join(profileId: selected!.id, code: widget.publicTeam == null ? _code.text : null, teamId: widget.publicTeam?.id);
                    if (mounted) {
                      ref.read(pendingTeamInviteProvider.notifier).clear();
                      setState(() => _status = status);
                    }
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                },
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class DiscoverTeamsPage extends ConsumerStatefulWidget {
  const DiscoverTeamsPage({this.profileId, super.key});
  final String? profileId;
  @override
  ConsumerState<DiscoverTeamsPage> createState() => _DiscoverTeamsPageState();
}

class _DiscoverTeamsPageState extends ConsumerState<DiscoverTeamsPage> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final results = ref.watch(teamDiscoveryProvider(_search));
    return AppPage(
      title: 'Find a team',
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Search team names'),
          onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Public listings never show players or private team activity.'),
        if (results.hasError)
          TeamLoadError(retry: () => ref.invalidate(teamDiscoveryProvider(_search)))
        else if (results.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_search.isNotEmpty && results.value!.isEmpty)
          const Text('No teams found.')
        else
          for (final team in results.value ?? <Team>[])
            TrainingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(team.name, style: Theme.of(context).textTheme.titleLarge),
                  Text('Coach: ${team.coachName}'),
                  Text('${team.memberCount} players'),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => JoinTeamPage(publicTeam: team, profileId: widget.profileId),
                      ),
                    ),
                    child: const Text('Review team'),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class CoachTeamPicker extends ConsumerWidget {
  const CoachTeamPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(coachedTeamsProvider);
    final selected = ref.watch(selectedCoachTeamProvider);
    if (teams.hasError) return TeamLoadError(retry: () => ref.invalidate(coachedTeamsProvider));
    if (teams.isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null)
          DropdownButtonFormField<String>(
            key: ValueKey(selected.id),
            initialValue: selected.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Coaching team'),
            items: [for (final team in teams.value!) DropdownMenuItem(value: team.id, child: Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis))],
            onChanged: (value) {
              if (value != null) ref.read(selectedCoachTeamIdProvider.notifier).choose(value);
            },
          )
        else
          const Text('You are not coaching a team yet. Create one or accept a coach invitation.'),
        TextButton(onPressed: () => context.push('/coach/create'), child: const Text('Create team')),
        TextButton(onPressed: () => context.push('/join'), child: const Text('Accept coach invite')),
      ],
    );
  }
}

class CreateTeamPage extends ConsumerStatefulWidget {
  const CreateTeamPage({super.key});
  @override
  ConsumerState<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends ConsumerState<CreateTeamPage> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Create team',
    children: [
      const Text('Teams start private. Share a player code to add players, or create a separate invitation for an assistant coach.'),
      TextField(
        controller: _name,
        maxLength: 60,
        decoration: const InputDecoration(labelText: 'Team name'),
      ),
      TeamAction(
        label: 'Create team',
        action: (ref) async {
          if (_name.text.trim().length < 2) throw const TeamException('Enter a team name of at least 2 characters.');
          await ref.read(teamRepositoryProvider).create(_name.text.trim());
          if (context.mounted) context.go('/coach/team');
        },
      ),
    ],
  );
}

class LiveCoachTeamPage extends ConsumerWidget {
  const LiveCoachTeamPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(selectedCoachTeamProvider);
    return AppPage(
      title: 'Team',
      children: [
        const CoachTeamPicker(),
        if (team != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Player join code', style: Theme.of(context).textTheme.titleLarge),
          SelectableText(team.joinCode),
          TeamAction(
            label: 'Copy player invite',
            action: (_) async {
              await Clipboard.setData(ClipboardData(text: teamInviteLink(team.joinCode)));
              if (context.mounted) showFeatureMessage(context, 'Player invite copied.');
            },
          ),
          TeamAction(label: 'Share player invite', action: (_) => _shareInvite(context, team.joinCode)),
          TeamAction(
            label: 'Replace player code',
            action: (ref) async {
              if (await _confirm(context, 'Replace player code?', 'Old player invites will stop working. Existing members stay on the team.')) {
                await ref.read(teamRepositoryProvider).createInvite(team.id, coach: false);
              }
            },
          ),
          TeamAction(
            label: 'Invite assistant coach',
            action: (ref) async {
              final code = await ref.read(teamRepositoryProvider).createInvite(team.id, coach: true);
              if (!context.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Coach invitation'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Works once, for 24 hours. Only share with an adult you trust to manage this team.'), SelectableText(code)]),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: teamInviteLink(code)));
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Copy invite'),
                    ),
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Done')),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public listing'),
            subtitle: const Text('Public teams can be discovered. Coaches approve requests; private activity stays members-only.'),
            value: team.visibility == 'public',
            onChanged: null,
          ),
          TeamAction(label: team.visibility == 'public' ? 'Make private' : 'Make public', action: (ref) => ref.read(teamRepositoryProvider).setVisibility(team.id, team.visibility != 'public')),
        ],
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(onPressed: () => context.push('/paywall?plan=coach'), child: const Text('Coach Pro')),
        OutlinedButton(onPressed: () => context.go('/train'), child: const Text('Switch to Player')),
      ],
    );
  }
}

class LiveCoachRosterPage extends ConsumerWidget {
  const LiveCoachRosterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(selectedCoachTeamProvider);
    final members = team == null ? null : ref.watch(teamMembersProvider(team.id));
    return AppPage(
      title: 'Roster',
      children: [
        const CoachTeamPicker(),
        if (team != null) ...[
          OutlinedButton(onPressed: () => context.go('/coach/roster/requests'), child: const Text('Join requests')),
          const SectionHeading(title: 'Players'),
          if (members!.hasError)
            TeamLoadError(retry: () => ref.invalidate(teamMembersProvider(team.id)))
          else if (members.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (members.value!.isEmpty)
            const Text('No players yet. Share your player invite from Team.')
          else
            for (final person in members.value!)
              TrainingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(person.displayName),
                    TeamAction(
                      label: 'Remove ${person.displayName}',
                      action: (ref) async {
                        if (await _confirm(context, 'Remove ${person.displayName}?', 'Their training history is kept.')) {
                          await ref.read(teamRepositoryProvider).remove(team.id, person.profileId);
                        }
                      },
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}

class LiveTeamRequestsPage extends ConsumerWidget {
  const LiveTeamRequestsPage({this.parent = false, super.key});
  final bool parent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = parent ? null : ref.watch(selectedCoachTeamProvider);
    final requests = parent
        ? ref.watch(parentTeamRequestsProvider)
        : team == null
        ? const AsyncData<List<TeamRequest>>([])
        : ref.watch(coachTeamRequestsProvider(team.id));
    return AppPage(
      title: parent ? 'Join approvals' : 'Join requests',
      children: [
        if (!parent) const CoachTeamPicker(),
        if (requests.hasError)
          TeamLoadError(
            retry: () {
              if (parent) {
                ref.invalidate(parentTeamRequestsProvider);
              } else if (team != null) {
                ref.invalidate(coachTeamRequestsProvider(team.id));
              }
            },
          )
        else if (requests.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (requests.value!.isEmpty)
          const TrainingCard(child: Text('No requests waiting.'))
        else
          for (final request in requests.value!)
            TrainingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${request.displayName} - ${request.teamName}'),
                  if (parent && request.status == 'coachPending')
                    const Text('Waiting for coach approval.')
                  else ...[
                    TeamAction(key: ValueKey('approve-${request.teamId}-${request.profileId}'), label: 'Approve', action: (ref) => ref.read(teamRepositoryProvider).review(request, true)),
                    TeamAction(label: 'Decline', action: (ref) => ref.read(teamRepositoryProvider).review(request, false)),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirm')),
        ],
      ),
    ) ??
    false;

Future<void> _shareInvite(BuildContext context, String code) async {
  final box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(ShareParams(text: teamInviteLink(code), sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size));
  } on PlatformException {
    throw const TeamException('Could not open sharing. Use Copy player invite instead.');
  }
}
