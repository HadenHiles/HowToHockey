import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_shapes.dart';
import '../design/tokens/app_spacing.dart';
import '../features/coach/outcomes.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'app_page.dart';
import 'sample_data.dart';

/// Remembers that the welcome walkthrough has been seen, so it only opens by itself on the first launch.
const welcomeSeenKey = 'welcomeSeen';

/// The first screens: what the app does for a player, a parent and a coach, one swipe each, then the ways in.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _leave(String route) {
    unawaited(ref.read(sharedPreferencesProvider).setBool(welcomeSeenKey, true));
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Words get more room at larger text sizes; the page still scrolls if it must.
    final pageHeight = MediaQuery.textScalerOf(context).scale(470);
    return AppPage(
      title: 'Welcome',
      showAppBar: false,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Center(child: BrandWordmark()),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: pageHeight,
          child: PageView(
            key: const ValueKey('welcome-pages'),
            controller: _pages,
            onPageChanged: (page) => setState(() => _page = page),
            children: const [_PlayerPage(), _ParentPage(), _CoachPage()],
          ),
        ),
        Semantics(
          label: 'Page ${_page + 1} of 3',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == _page ? theme.colorScheme.primary : theme.dividerColor, borderRadius: BorderRadius.circular(4)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: () => _leave('/signup'), child: const Text('Get started')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: () => _leave('/signin'), child: const Text('I already have an account')),
        TextButton(onPressed: () => _leave('/pair'), child: const Text('Set up a kid\'s device')),
        TextButton(onPressed: () => _leave('/train'), child: const Text('Look around first')),
      ],
    );
  }
}

/// One role's page: who it is for, the promise, a look at it, and what it does (or soon will).
class _RolePage extends StatelessWidget {
  const _RolePage({required this.eyebrow, required this.headline, required this.preview, required this.points});

  final String eyebrow;
  final String headline;
  final Widget preview;
  final List<(String, bool)> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(eyebrow, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.xxs),
          Text(headline, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          // A picture of the screen, not the screen: it can't be tapped and isn't read out.
          ExcludeSemantics(child: IgnorePointer(child: preview)),
          const SizedBox(height: AppSpacing.md),
          for (final (text, soon) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(soon ? Icons.schedule : Icons.check_circle, size: 20, color: soon ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                  if (soon)
                    Container(
                      margin: const EdgeInsets.only(left: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Text('Soon', style: theme.textTheme.labelSmall),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerPage extends StatelessWidget {
  const _PlayerPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _RolePage(
      eyebrow: 'FOR PLAYERS',
      headline: 'Get better at hockey, and have fun doing it.',
      preview: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final outcome in outcomes.take(4))
            Chip(
              avatar: Icon(outcome.pillar.icon, size: 18, color: theme.colorScheme.primary),
              label: Text(outcome.label),
            ),
        ],
      ),
      points: const [('Pick what you want to improve, then tap Start.', false), ('Follow along one drill at a time.', false), ('Watch your progress add up.', false)],
    );
  }
}

class _ParentPage extends StatelessWidget {
  const _ParentPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget kid(String initials, String name) => TrainingCard(
      child: Row(
        children: [
          CircleAvatar(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, child: Text(initials)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
    return _RolePage(
      eyebrow: 'FOR PARENTS',
      headline: 'Your kids train. You stay in charge.',
      preview: Column(
        children: [
          kid('A', 'Avery H.'),
          const SizedBox(height: AppSpacing.xs),
          kid('J', 'Jamie H.'),
        ],
      ),
      points: const [('Set up to 3 kids. No email needed for them.', false), ('Approve their team requests.', false), ('Confirm their workouts and fix their training time.', true)],
    );
  }
}

class _CoachPage extends StatelessWidget {
  const _CoachPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _RolePage(
      eyebrow: 'FOR COACHES',
      headline: 'Get your whole team training.',
      preview: TrainingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team code', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text('7F3A 9C21 B54E 08D6', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text('Example', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      points: const [('Create a team and share one code.', false), ('Approve players and add assistant coaches.', false), ('Share a routine with your whole team.', true)],
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.currentYear});

  final int? currentYear;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = widget.currentYear ?? DateTime.now().year;
    final year = _year;
    // Only the birth year is collected, so anyone who could still be 12 is treated as under 13.
    final needsParent = year != null && now - year < 14;
    return AppPage(
      title: 'Create account',
      subtitle: 'Pick your birth year. We only use it to keep young players safe.',
      actions: [IconButton(tooltip: 'Back to welcome', icon: const Icon(Icons.close), onPressed: () => context.go('/welcome'))],
      children: [
        DropdownButtonFormField<int>(
          initialValue: year,
          decoration: const InputDecoration(labelText: 'Birth year'),
          items: [for (var y = now; y >= now - 100; y--) DropdownMenuItem(value: y, child: Text('$y'))],
          onChanged: (value) => setState(() => _year = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (needsParent)
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.family_restroom, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('A parent needs to set this up', style: theme.textTheme.titleMedium)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Players under 13 can\'t create their own account. A parent creates a child profile from their account, then pairs this device.'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(onPressed: () => context.go('/welcome'), child: const Text('Back')),
              ],
            ),
          )
        else if (year != null) ...[
          FilledButton.icon(
            onPressed: () => showFeatureMessage(context, 'Sign in with Apple isn\'t set up yet. Use email for now.'),
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => showFeatureMessage(context, 'Google sign-in isn\'t set up yet. Use email for now.'),
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: () => context.go('/signup/email?year=$year'), icon: const Icon(Icons.mail_outline), label: const Text('Continue with email')),
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: () => context.go('/onboarding/role'), child: const Text('Skip for now (look around)')),
        ],
      ],
    );
  }
}

class RoleOnboardingPage extends StatefulWidget {
  const RoleOnboardingPage({super.key});

  @override
  State<RoleOnboardingPage> createState() => _RoleOnboardingPageState();
}

class _RoleOnboardingPageState extends State<RoleOnboardingPage> {
  final _roles = <String>{'player'};

  static const _options = [
    (id: 'player', icon: Icons.sports_hockey, title: 'Player', detail: 'Train, track your progress, and join a team', route: '/train'),
    (id: 'parent', icon: Icons.family_restroom, title: 'Parent', detail: 'Set up your kids, approve activity, and verify', route: '/parent/kids'),
    (id: 'coach', icon: Icons.groups, title: 'Coach', detail: 'Run your roster, assign homework, see who\'s on track', route: '/coach/roster'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = _options.firstWhere((o) => _roles.contains(o.id), orElse: () => _options.first);
    return AppPage(
      title: 'How will you use it?',
      subtitle: 'Pick every role that fits. You can switch any time from Me or Account.',
      action: FilledButton(onPressed: _roles.isEmpty ? null : () => context.go(first.route), child: Text('Continue as ${first.title}')),
      children: [
        for (final option in _options) ...[
          TrainingCard(
            onTap: () => setState(() => _roles.contains(option.id) ? _roles.remove(option.id) : _roles.add(option.id)),
            child: Semantics(
              selected: _roles.contains(option.id),
              child: Row(
                children: [
                  Icon(option.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: theme.textTheme.titleMedium),
                        Text(option.detail, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(_roles.contains(option.id) ? Icons.check_circle : Icons.circle_outlined, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        const Text('Role choices aren\'t saved yet.'),
      ],
    );
  }
}
