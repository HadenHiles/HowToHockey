import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import 'app_page.dart';

// Local sample roster; replaced by team data when Phase 9/11 is built.
const _players = [
  (id: 'p1', name: 'Jordan M.', done: 3, assigned: 3, minutes: 142, verified: true),
  (id: 'p2', name: 'Sam T.', done: 2, assigned: 3, minutes: 96, verified: true),
  (id: 'p3', name: 'Casey L.', done: 1, assigned: 3, minutes: 44, verified: false),
  (id: 'p4', name: 'Morgan P.', done: 0, assigned: 3, minutes: 0, verified: false),
  (id: 'p5', name: 'Avery H.', done: 3, assigned: 3, minutes: 118, verified: false),
];

const _requests = [(name: 'Riley H.', detail: 'Requested via public listing · parent approved'), (name: 'Drew K.', detail: 'Joined with team code · awaiting your approval')];

const _routines = [(title: 'Wrist Shot Ladder', detail: '4 drills · 25 min'), (title: 'Stickhandling Box', detail: '3 drills · 20 min'), (title: 'Skating Edges Circuit', detail: '5 drills · 30 min')];

class _Notice extends StatelessWidget {
  const _Notice(this.text);

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

class _Entry extends StatelessWidget {
  const _Entry({required this.icon, required this.title, required this.detail, required this.onTap});

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

class CoachRosterPage extends StatelessWidget {
  const CoachRosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Roster',
      subtitle: 'Northside Novas · U12 · ${_players.length} of 30 players',
      children: [
        const _Notice('Coach screens use representative local sample data. Roster changes, approvals, and invites are not connected yet.'),
        const SizedBox(height: AppSpacing.xl),
        _Entry(icon: Icons.how_to_reg_outlined, title: 'Join requests', detail: '${_requests.length} waiting for approval', onTap: () => context.go('/coach/roster/requests')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Players'),
        const SizedBox(height: AppSpacing.md),
        for (final player in _players) ...[
          TrainingCard(
            child: Row(
              children: [
                CircleAvatar(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, child: Text(player.name.substring(0, 1))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: theme.textTheme.titleMedium),
                      Text('${player.minutes} active min this week', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (player.verified) Icon(Icons.verified, color: theme.colorScheme.primary, semanticLabel: 'Parent verified'),
                PopupMenuButton<String>(
                  tooltip: 'Manage ${player.name}',
                  onSelected: (_) => showFeatureMessage(context, 'Roster changes are not connected yet. Nothing was changed.'),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remove from team'))],
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

class CoachRequestsPage extends StatelessWidget {
  const CoachRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Join requests',
    subtitle: 'Coaches cannot search for players. Requests only arrive from your team code or public listing.',
    actions: [IconButton(tooltip: 'Back to Roster', icon: const Icon(Icons.close), onPressed: () => context.go('/coach/roster'))],
    children: [
      for (final request in _requests) ...[
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

class CoachHomeworkPage extends StatelessWidget {
  const CoachHomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Homework',
      action: FilledButton.icon(onPressed: () => context.go('/coach/homework/new'), icon: const Icon(Icons.add), label: const Text('Assign homework')),
      children: [
        const SectionHeading(title: 'Active'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wrist Shot Ladder', style: theme.textTheme.titleMedium),
              const Text('Due Friday · all players'),
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(value: .6, semanticsLabel: '60 percent complete'),
              const SizedBox(height: AppSpacing.xs),
              Text('3 of 5 players done', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Routine builder'),
        const SizedBox(height: AppSpacing.md),
        _Entry(
          icon: Icons.edit_note,
          title: 'Build a team routine',
          detail: 'Pick drills, set prescriptions, reorder',
          onTap: () => showFeatureMessage(context, 'The team routine builder is not connected yet.'),
        ),
      ],
    );
  }
}

class CoachAssignPage extends StatefulWidget {
  const CoachAssignPage({super.key});

  @override
  State<CoachAssignPage> createState() => _CoachAssignPageState();
}

class _CoachAssignPageState extends State<CoachAssignPage> {
  var _routine = 0;
  var _due = 1;
  final _selected = {for (final p in _players) p.id};

  static const _dueOptions = ['Tomorrow', 'In 3 days', 'Next week'];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Assign homework',
    subtitle: 'Players are notified when assignments are connected.',
    actions: [IconButton(tooltip: 'Back to Homework', icon: const Icon(Icons.close), onPressed: () => context.go('/coach/homework'))],
    action: FilledButton(
      onPressed: _selected.isEmpty ? null : () => showFeatureMessage(context, 'Assignments are not connected yet. Nothing was sent to ${_selected.length} players.'),
      child: Text('Assign to ${_selected.length} players'),
    ),
    children: [
      const SectionHeading(title: 'Routine'),
      RadioGroup<int>(
        groupValue: _routine,
        onChanged: (value) => setState(() => _routine = value ?? _routine),
        child: Column(
          children: [for (final (index, r) in _routines.indexed) RadioListTile<int>(value: index, title: Text(r.title), subtitle: Text(r.detail))],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeading(title: 'Due'),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.xs,
        children: [for (final (index, label) in _dueOptions.indexed) ChoiceChip(label: Text(label), selected: _due == index, onSelected: (_) => setState(() => _due = index))],
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeading(title: 'Players'),
      for (final player in _players)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(player.name),
          value: _selected.contains(player.id),
          onChanged: (value) => setState(() => value == true ? _selected.add(player.id) : _selected.remove(player.id)),
        ),
    ],
  );
}

class CoachCompliancePage extends StatefulWidget {
  const CoachCompliancePage({super.key});

  @override
  State<CoachCompliancePage> createState() => _CoachCompliancePageState();
}

class _CoachCompliancePageState extends State<CoachCompliancePage> {
  var _range = 0;

  static const _ranges = ['This week', 'Last 30 days', 'Season'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _players.fold<int>(0, (sum, p) => sum + p.done);
    final total = _players.fold<int>(0, (sum, p) => sum + p.assigned);
    return AppPage(
      title: 'Compliance',
      children: [
        const _Notice('Figures are sample data and do not change with the date range yet.'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          children: [for (final (index, label) in _ranges.indexed) ChoiceChip(label: Text(label), selected: _range == index, onSelected: (_) => setState(() => _range = index))],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: MetricTile(value: '${(completed * 100 / total).round()}%', label: 'Completion'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MetricTile(value: '${_players.fold<int>(0, (s, p) => s + p.minutes)}', label: 'Active min'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'By player'),
        const SizedBox(height: AppSpacing.md),
        for (final player in _players) ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(player.name, style: theme.textTheme.titleMedium)),
                    Text('${player.done}/${player.assigned}', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(value: player.done / player.assigned, semanticsLabel: '${player.name}: ${player.done} of ${player.assigned} assignments done'),
                const SizedBox(height: AppSpacing.xs),
                Text('${player.minutes} active min', style: theme.textTheme.bodySmall),
                if (player.done > 0 && !player.verified)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => showFeatureMessage(context, 'Verification is not connected yet. Nothing was verified.'), child: const Text('Verify workouts')),
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

class CoachTeamPage extends StatefulWidget {
  const CoachTeamPage({super.key});

  @override
  State<CoachTeamPage> createState() => _CoachTeamPageState();
}

class _CoachTeamPageState extends State<CoachTeamPage> {
  var _public = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Team',
      children: [
        const _Notice('Team settings and invites are not connected yet. Changes here last only until restart.'),
        const SizedBox(height: AppSpacing.xl),
        ArenaPanel(
          child: Column(
            children: [
              Text('NOVAS-4821', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.xs),
              Text('SAMPLE JOIN CODE · NOT VALID', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(onPressed: () => showFeatureMessage(context, 'Invite links are not connected yet.'), icon: const Icon(Icons.ios_share), label: const Text('Share invite')),
            OutlinedButton(onPressed: () => showFeatureMessage(context, 'Join codes are not connected yet. The code was not changed.'), child: const Text('New code')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Settings'),
        const SizedBox(height: AppSpacing.md),
        TrainingCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public listing'),
            subtitle: Text(_public ? 'Shown in team discovery with team name, coach name, and player count.' : 'Private. Players join only with your code.'),
            value: _public,
            onChanged: (value) => setState(() => _public = value),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Entry(icon: Icons.verified_outlined, title: 'Workout verification', detail: 'Review verified and unverified sessions', onTap: () => context.go('/coach/compliance')),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Mode'),
        const SizedBox(height: AppSpacing.md),
        _Entry(icon: Icons.sports_hockey, title: 'Switch to Player', detail: 'Currently in Coach mode', onTap: () => context.go('/train')),
      ],
    );
  }
}
