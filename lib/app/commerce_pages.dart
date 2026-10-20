import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/commerce/entitlements.dart';
import '../features/commerce/purchases_service.dart';
import '../features/drills/drill_media.dart';
import 'app_page.dart';
import 'drill_media_card.dart';

/// The plan to show for the player being trained, for example on Me and Account.
String planLabel(WidgetRef ref) {
  if (ref.watch(coachProProvider)) return 'Coach Pro';
  return ref.watch(effectiveProProvider) ? 'Player Pro' : 'Free plan';
}

/// Restores the account's purchases and tells the person what happened.
Future<void> restorePurchasesWithMessage(BuildContext context, WidgetRef ref) async {
  final String message;
  try {
    final active = await ref.read(purchasesProvider).restore();
    message = active.contains(playerProEntitlement) || active.contains(coachProEntitlement) ? 'Your plan is back.' : 'No purchases found for this account.';
  } on PurchaseFailure catch (failure) {
    if (context.mounted) showFeatureMessage(context, failure.message);
    return;
  }
  if (context.mounted) showFeatureMessage(context, message);
}

/// The plans screen. What a new subscriber sees (wording, plans, look) is RevenueCat's paywall, edited in its
/// dashboard. This wrapper only handles what the app itself knows: who is signed in and what they already own.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key, this.coach = false});

  final bool coach;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  Future<Widget?>? _paywall;
  var _busy = false;

  String get _name => widget.coach ? 'Coach Pro' : 'Player Pro';

  void _close() => context.canPop() ? context.pop() : context.go('/me');

  Future<void> _manage() async {
    setState(() => _busy = true);
    try {
      final opened = await launchUrl(await ref.read(purchasesProvider).manageUri(), mode: LaunchMode.externalApplication);
      if (!opened && mounted) showFeatureMessage(context, 'Couldn\'t open your subscriptions. Open them from your phone\'s store settings.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    final plans = ref.watch(accountPlansProvider);
    final signedIn = ref.watch(authStateProvider).value is SignedInAccount;
    final owned = widget.coach ? plans.coach : plans.player;
    final close = IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: _close);

    if (owned) {
      return AppPage(
        title: _name,
        subtitle: 'You have $_name. Thank you!',
        actions: [close],
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(onPressed: _busy ? null : _manage, child: const Text('Manage subscription')),
            TextButton(onPressed: () => unawaited(restorePurchasesWithMessage(context, ref)), child: const Text('Restore purchases')),
          ],
        ),
        children: const [Text('One plan covers you and up to 3 kids. Change or cancel any time in your phone\'s subscription settings.')],
      );
    }
    if (!signedIn) {
      return AppPage(
        title: _name,
        subtitle: 'Create a free account to subscribe, so your plan follows you to a new phone.',
        actions: [close],
        action: FilledButton(onPressed: () => context.push('/signup'), child: const Text('Create a free account')),
        children: const [],
      );
    }

    _paywall ??= purchases.paywall(widget.coach ? 'coach' : 'player', onFinished: _close).catchError((Object _) => null);
    return FutureBuilder<Widget?>(
      future: _paywall,
      builder: (context, snapshot) {
        final paywall = snapshot.data;
        if (paywall != null) return Scaffold(body: paywall);
        if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return AppPage(
          title: _name,
          subtitle: 'Plans aren\'t available right now. Nothing has been charged.',
          actions: [close],
          action: FilledButton(onPressed: _close, child: const Text('Back')),
          children: const [],
        );
      },
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
  SampleProgram(id: 'shooting-30', title: '30 Days to a Harder Shot', detail: 'Daily shooting work with a lesson from Coach Jeremy.', price: r'$29.99', days: 30, owned: true, dayReached: 3),
  SampleProgram(id: 'hands-21', title: 'Elite Hands in 21 Days', detail: 'Stickhandling that builds from the basics to game speed.', price: r'$19.99', days: 21),
  SampleProgram(id: 'power-skating-14', title: 'Power Skating Kickstart', detail: 'Two weeks of edges, crossovers and explosive starts.', price: r'$14.99', days: 14),
];

SampleProgram? programById(String id) => samplePrograms.where((p) => p.id == id).firstOrNull;

class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'Programs',
      subtitle: 'Buy a program once and keep it. These are examples for now.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/train'))],
      children: [
        for (final program in samplePrograms) ...[
          TrainingCard(
            onTap: () => context.push('/programs/${program.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrillMediaPlaceholder(title: 'Program video', compact: true),
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
        children: const [Text('We can\'t find this program.')],
      );
    }
    final theme = Theme.of(context);
    return AppPage(
      title: program.title,
      actions: [IconButton(tooltip: 'Back to Programs', icon: const Icon(Icons.close), onPressed: () => context.go('/programs'))],
      action: program.owned
          ? FilledButton(onPressed: () => context.push('/programs/${program.id}/day/${program.dayReached}'), child: Text('Continue · Day ${program.dayReached}'))
          : FilledButton(onPressed: () => showFeatureMessage(context, 'Purchases aren\'t live yet. You weren\'t charged.'), child: Text('Buy for ${program.price}')),
      children: [
        const DrillMediaCard(title: 'Program trailer', mediaPath: placeholderLessonMediaPath),
        const SizedBox(height: AppSpacing.md),
        Text(program.detail),
        if (program.owned) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: program.dayReached / program.days, semanticsLabel: 'Day ${program.dayReached} of ${program.days}'),
          const SizedBox(height: AppSpacing.xs),
          Text('Day ${program.dayReached} of ${program.days}', style: theme.textTheme.bodySmall),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Pro members get 20% off once purchases go live.', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Plan'),
        const SizedBox(height: AppSpacing.md),
        for (var day = 1; day <= 5; day++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(program.owned && day <= program.dayReached ? Icons.play_circle_outline : Icons.lock_outline),
            title: Text('Day $day'),
            subtitle: Text(day == 1 ? 'Free to watch' : (program.owned ? 'Included' : 'Unlocks when you buy')),
            onTap: () {
              if (day == 1 || (program.owned && day <= program.dayReached)) {
                context.push('/programs/${program.id}/day/$day');
              } else {
                showFeatureMessage(context, program.owned ? 'Finish the earlier days to reach this one.' : 'Buy this program to unlock this day. Purchases aren\'t live yet.');
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
        children: const [Text('We can\'t find this program day.')],
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
        const TrainingCard(child: Text('3 drills · 25 min. The workout opens in Train with example drills until programs go live.')),
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
      const DrillMediaCard(title: 'Lesson video', mediaPath: placeholderLessonMediaPath),
      const SizedBox(height: AppSpacing.md),
      const Text('Example lesson. Coach Jeremy\'s lesson videos are coming soon.'),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeading(title: 'Key cues'),
      const SizedBox(height: AppSpacing.sm),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Load the stick early')),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Shift weight through the shot')),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check), title: Text('Follow through to the target')),
    ],
  );
}
