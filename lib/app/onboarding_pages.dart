import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/drills/drill_media.dart';
import 'app_page.dart';
import 'drill_media_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Welcome',
      showAppBar: false,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Center(child: BrandWordmark()),
        const SizedBox(height: AppSpacing.xl),
        const DrillMediaCard(title: 'Coach Jeremy', mediaPath: placeholderLessonMediaPath),
        const SizedBox(height: AppSpacing.xl),
        Text('Feel more confident in your next game.', style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('Off-ice workouts with clear instruction, your progress, and your team in one place.'),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: () => context.go('/signup'), child: const Text('Get started')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: () => showFeatureMessage(context, 'Sign-in isn\'t live yet. Nothing was changed.'), child: const Text('I already have an account')),
        TextButton(onPressed: () => context.go('/train'), child: const Text('Look around first')),
      ],
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
            onPressed: () => showFeatureMessage(context, 'Apple sign-in isn\'t live yet. Nothing was changed.'),
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => showFeatureMessage(context, 'Google sign-in isn\'t live yet. Nothing was changed.'),
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => showFeatureMessage(context, 'Email sign-up isn\'t live yet. Nothing was changed.'),
            icon: const Icon(Icons.mail_outline),
            label: const Text('Continue with email'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: () => context.go('/onboarding/role'), child: const Text('Skip for now (look around)')),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Text('Accounts aren\'t live yet. Nothing here creates an account.'),
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
