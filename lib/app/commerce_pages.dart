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

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key, this.coach = false});

  final bool coach;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  late var _coach = widget.coach;
  var _yearly = true;
  var _busy = false;
  List<PlanOffer>? _offers;
  var _offersFailed = false;

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
  void initState() {
    super.initState();
    unawaited(_loadOffers());
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await ref.read(purchasesProvider).offers();
      if (mounted) setState(() => _offers = offers);
    } on Object {
      if (mounted) setState(() => _offersFailed = true);
    }
  }

  PlanOffer? get _selected => _offers?.where((offer) => offer.coach == _coach && offer.yearly == _yearly).firstOrNull;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    try {
      final message = await action();
      if (mounted && message != null) showFeatureMessage(context, message);
    } on PurchaseFailure catch (failure) {
      if (mounted) showFeatureMessage(context, failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(PlanOffer offer) => _run(() async {
    final outcome = await ref.read(purchasesProvider).purchase(offer);
    if (outcome == PurchaseOutcome.cancelled) return null;
    if (mounted) context.canPop() ? context.pop() : context.go('/me');
    return 'You\'re all set. Thanks for supporting How To Hockey.';
  });

  Future<void> _restore() => _run(() async {
    final active = await ref.read(purchasesProvider).restore();
    if (active.contains(playerProEntitlement) || active.contains(coachProEntitlement)) return 'Your plan is back.';
    return 'No purchases found for this account.';
  });

  Future<void> _manage() => _run(() async {
    final opened = await launchUrl(await ref.read(purchasesProvider).manageUri(), mode: LaunchMode.externalApplication);
    return opened ? null : 'Couldn\'t open your subscriptions. Open them from your phone\'s store settings.';
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchases = ref.watch(purchasesProvider);
    final plans = ref.watch(accountPlansProvider);
    final signedIn = ref.watch(authStateProvider).value is SignedInAccount;
    final features = _coach ? _coachFeatures : _playerFeatures;
    final name = _coach ? 'Coach Pro' : 'Player Pro';
    final owned = _coach ? plans.coach : plans.player;
    final offer = _selected;
    final loading = purchases.available && _offers == null && !_offersFailed;
    final unavailable = !purchases.available || _offersFailed || (_offers != null && offer == null);

    final Widget primary;
    if (owned) {
      primary = FilledButton(onPressed: _busy ? null : _manage, child: const Text('Manage subscription'));
    } else if (!signedIn) {
      primary = FilledButton(onPressed: () => context.push('/signup'), child: const Text('Create a free account to subscribe'));
    } else if (offer != null) {
      primary = FilledButton(onPressed: _busy ? null : () => _buy(offer), child: Text('Start $name · ${offer.price} / ${_yearly ? 'year' : 'month'}'));
    } else {
      primary = FilledButton(onPressed: null, child: Text(loading ? 'Loading plans…' : 'Plans aren\'t available right now'));
    }

    return AppPage(
      title: name,
      subtitle: owned
          ? 'You have $name. Thank you!'
          : unavailable
          ? 'Plans aren\'t available right now. Nothing has been charged.'
          : 'One plan covers you and up to 3 kids.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/me'))],
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primary,
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (signedIn && purchases.available) TextButton(onPressed: _busy ? null : _restore, child: const Text('Restore purchases')),
              if (signedIn && purchases.available && !owned) TextButton(onPressed: _busy ? null : _manage, child: const Text('Manage subscription')),
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
        if (_coach) const Text('Players get a free month of Player Pro (30 days) when they join a Coach Pro team.'),
        const SizedBox(height: AppSpacing.sm),
        Text('Renews automatically until cancelled. Cancel any time in your phone\'s subscription settings.', style: theme.textTheme.bodySmall),
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
