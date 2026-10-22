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
import '../features/drills/drill_catalog.dart';
import '../features/drills/drill_media.dart';
import 'app_page.dart';
import 'drill_media_card.dart';
import 'sample_data.dart';
import 'training_state.dart';

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
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
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

class TrainingProgram {
  const TrainingProgram({required this.id, required this.title, required this.skill, required this.detail, required this.price, required this.days, required this.templates, required this.challenges});

  final String id;
  final String title;
  final String skill;
  final String detail;
  final String price;
  final int days;
  final List<List<({String drillId, int sets})>> templates;
  final List<({String title, String description})> challenges;

  List<({String drillId, int sets})> routineFor(int day) => templates[(day - 1) % templates.length];

  ({String title, String description}) challengeFor(int day) => challenges[(day - 1) % challenges.length];

  String get entitlement => 'program_$id';
}

const programs = [
  TrainingProgram(
    id: 'shooting-30',
    title: '30 Days to a Harder Shot',
    skill: 'Shot power',
    detail: 'Build a quicker, stronger release with focused shooting sessions and a new challenge each day.',
    price: r'$29.99',
    days: 30,
    templates: [
      [(drillId: 'quick-release-wrist-shots', sets: 3), (drillId: 'shot-burst-30', sets: 2)],
      [(drillId: 'pick-your-corner', sets: 2), (drillId: 'quick-release-wrist-shots', sets: 3)],
      [(drillId: 'shot-burst-30', sets: 3), (drillId: 'quick-release-wrist-shots', sets: 2)],
    ],
    challenges: [
      (title: 'Beat your best', description: 'Count your shots in 30 seconds. Try to beat your own score.'),
      (title: 'Pick a corner', description: 'Choose one target and hit it 5 times before switching sides.'),
      (title: 'Smooth streak', description: 'Take 10 smooth shots in a row. Reset if your form slips.'),
    ],
  ),
  TrainingProgram(
    id: 'hands-21',
    title: 'Elite Hands in 21 Days',
    skill: 'Quick hands',
    detail: 'Build soft hands and faster puck control with short, varied stickhandling sessions.',
    price: r'$19.99',
    days: 21,
    templates: [
      [(drillId: 'quiet-hands-quick-feet', sets: 3), (drillId: 'pass-and-settle', sets: 2)],
      [(drillId: 'quiet-hands-quick-feet', sets: 2), (drillId: 'athletic-stance-reset', sets: 2)],
      [(drillId: 'pass-and-settle', sets: 3), (drillId: 'quiet-hands-quick-feet', sets: 2)],
    ],
    challenges: [
      (title: 'Eyes up', description: 'Keep your eyes up for the whole final set.'),
      (title: 'Quick feet', description: 'Stay light on your feet while keeping the puck close.'),
      (title: 'Clean touches', description: 'Try to finish the set without losing control of the puck.'),
    ],
  ),
  TrainingProgram(
    id: 'power-skating-14',
    title: 'Power Skating Kickstart',
    skill: 'Speed & explosiveness',
    detail: 'Practice a balanced stance, quick feet and powerful starts in a two-week plan.',
    price: r'$14.99',
    days: 14,
    templates: [
      [(drillId: 'athletic-stance-reset', sets: 3), (drillId: 'quiet-hands-quick-feet', sets: 2)],
      [(drillId: 'athletic-stance-reset', sets: 2), (drillId: 'shot-burst-30', sets: 2)],
      [(drillId: 'quiet-hands-quick-feet', sets: 3), (drillId: 'athletic-stance-reset', sets: 2)],
    ],
    challenges: [
      (title: 'Strong position', description: 'Hold a balanced athletic stance through every rep.'),
      (title: 'Fast start', description: 'Make each first step quick and controlled.'),
      (title: 'Stay steady', description: 'Keep your balance from the first rep to the last.'),
    ],
  ),
];

TrainingProgram? programById(String id) => programs.where((p) => p.id == id).firstOrNull;

String programStoreOffering(String programId) => 'program_$programId';

class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entitlements = ref.watch(purchasedEntitlementsProvider).value ?? const <String>{};
    return AppPage(
      title: 'Programs',
      subtitle: 'Pick what you want to get better at. Every program starts with a free training day.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/train'))],
      children: [
        for (final program in programs) ...[
          TrainingCard(
            onTap: () => context.push('/programs/${program.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrillMediaPlaceholder(title: 'Program video', compact: true),
                const SizedBox(height: AppSpacing.md),
                Text(program.title, style: theme.textTheme.titleMedium),
                Text('${program.skill} · ${program.days} days', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(program.detail, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(entitlements.contains(program.entitlement) ? 'Owned · Continue training' : 'Day 1 free · ${program.price} to unlock all days', style: theme.textTheme.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class ProgramDetailPage extends ConsumerWidget {
  const ProgramDetailPage({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = programById(programId);
    if (program == null) {
      return AppPage(
        title: 'Program not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('We can\'t find this program.')],
      );
    }
    final theme = Theme.of(context);
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement);
    return AppPage(
      title: program.title,
      actions: [IconButton(tooltip: 'Back to Programs', icon: const Icon(Icons.close), onPressed: () => context.go('/programs'))],
      action: owned
          ? FilledButton(onPressed: () => context.push('/programs/${program.id}/day/1'), child: const Text('Start training'))
          : FilledButton(onPressed: () => context.push('/programs/${program.id}/day/1'), child: const Text('Try Day 1 free')),
      children: [
        const DrillMediaCard(title: 'Program trailer', mediaPath: placeholderLessonMediaPath),
        const SizedBox(height: AppSpacing.md),
        Text(program.skill.toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(program.detail),
        if (owned) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Start at Day 1 · ${program.days} days', style: theme.textTheme.bodySmall),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Try the first day free. Unlock the full program with a one-time purchase.', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Plan'),
        const SizedBox(height: AppSpacing.md),
        for (var day = 1; day <= program.days; day++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(day == 1 || owned ? Icons.play_circle_outline : Icons.lock_outline),
            title: Text('Day $day'),
            subtitle: Text(day == 1 ? 'Free preview · routine and challenge' : (owned ? 'Included' : 'Unlocks with the full program')),
            onTap: () {
              if (day == 1 || owned) {
                context.push('/programs/${program.id}/day/$day');
              } else {
                context.push('/programs/${program.id}/purchase');
              }
            },
          ),
      ],
    );
  }
}

class ProgramDayPage extends ConsumerWidget {
  const ProgramDayPage({required this.programId, required this.day, super.key});

  final String programId;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = programById(programId);
    if (program == null || day < 1 || day > program.days) {
      return AppPage(
        title: 'Day not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('We can\'t find this program day.')],
      );
    }
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement);
    if (day != 1 && !owned) {
      return AppPage(
        title: 'Unlock this day',
        subtitle: program.title,
        action: FilledButton(onPressed: () => context.push('/programs/${program.id}/purchase'), child: Text('Unlock for ${program.price}')),
        children: const [Text('Day 1 is free to try. Unlock the full program to train every day.')],
      );
    }
    final theme = Theme.of(context);
    final catalogState = ref.watch(drillCatalogProvider);
    if (catalogState.hasError) {
      return AppPage(
        title: 'Day $day of ${program.days}',
        subtitle: program.title,
        action: FilledButton(onPressed: () => ref.invalidate(drillCatalogProvider), child: const Text('Try again')),
        children: const [Text('Couldn’t load this program workout. Please try again.')],
      );
    }
    final catalog = catalogState.value;
    if (catalog == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final drillById = {for (final drill in catalog) drill.id: drill};
    final routine = [
      for (final step in program.routineFor(day))
        if (drillById[step.drillId] case final drill?) drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: step.sets)),
    ];
    final missingDrills = program.routineFor(day).where((step) => !drillById.containsKey(step.drillId)).toList();
    final challenge = program.challengeFor(day);
    return AppPage(
      title: 'Day $day of ${program.days}',
      subtitle: program.title,
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
      action: FilledButton(
        onPressed: routine.isEmpty || missingDrills.isNotEmpty
            ? null
            : () {
                ref.read(trainingSessionProvider.notifier).start(routine);
                context.go('/train/session');
              },
        child: const Text('Start this workout'),
      ),
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
        if (routine.isEmpty || missingDrills.isNotEmpty)
          const Text('This workout is temporarily unavailable. Please try again later.')
        else ...[
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${routine.length} drills · Guided workout', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final drill in routine)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(primaryPillar(drill).icon, color: theme.colorScheme.primary),
                    title: Text(drill.title),
                    subtitle: Text('${drill.defaultPrescription.sets} sets · ${drill.targetLabel}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeading(title: 'Today’s challenge'),
          const SizedBox(height: AppSpacing.sm),
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(challenge.description),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ProgramPurchasePage extends ConsumerStatefulWidget {
  const ProgramPurchasePage({required this.programId, super.key});

  final String programId;

  @override
  ConsumerState<ProgramPurchasePage> createState() => _ProgramPurchasePageState();
}

class _ProgramPurchasePageState extends ConsumerState<ProgramPurchasePage> {
  Future<Widget?>? _paywall;

  @override
  Widget build(BuildContext context) {
    final program = programById(widget.programId);
    if (program == null) {
      return AppPage(
        title: 'Program not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('We can’t find this program.')],
      );
    }
    final close = IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop());
    if (ref.watch(purchasedEntitlementsProvider).value?.contains(program.entitlement) == true) {
      return AppPage(
        title: 'Program unlocked',
        actions: [close],
        subtitle: 'You own ${program.title}.',
        action: FilledButton(onPressed: () => context.go('/programs/${program.id}/day/1'), child: const Text('Start training')),
        children: const [],
      );
    }
    if (ref.watch(authStateProvider).value is! SignedInAccount) {
      return AppPage(
        title: 'Unlock ${program.title}',
        actions: [close],
        subtitle: 'Create a free account to buy this program and keep it with you.',
        action: FilledButton(onPressed: () => context.push('/signup'), child: const Text('Create a free account')),
        children: const [],
      );
    }
    _paywall ??= ref
        .read(purchasesProvider)
        .paywall(
          programStoreOffering(program.id),
          onFinished: () {
            if (mounted) context.go('/programs/${program.id}');
          },
        );
    return FutureBuilder<Widget?>(
      future: _paywall,
      builder: (context, snapshot) {
        if (snapshot.data case final paywall?) return Scaffold(body: paywall);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return AppPage(
            title: 'Unlock ${program.title}',
            subtitle: 'Couldn’t load purchase options. Day 1 is still free to try.',
            actions: [close],
            action: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(onPressed: () => setState(() => _paywall = null), child: const Text('Try again')),
                TextButton(onPressed: () => context.go('/programs/${program.id}/day/1'), child: const Text('Try Day 1 free')),
              ],
            ),
            children: const [],
          );
        }
        return AppPage(
          title: 'Unlock ${program.title}',
          subtitle: 'Purchases aren’t available right now. You can still try Day 1 for free.',
          actions: [close],
          action: FilledButton(onPressed: () => context.go('/programs/${program.id}/day/1'), child: const Text('Try Day 1 free')),
          children: const [],
        );
      },
    );
  }
}

class ProgramLessonPage extends ConsumerWidget {
  const ProgramLessonPage({required this.programId, required this.day, super.key});

  final String programId;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = programById(programId);
    if (program == null) {
      return AppPage(
        title: 'Program not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('We can’t find this program.')],
      );
    }
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement);
    if (day != 1 && !owned) {
      return AppPage(
        title: 'Unlock this lesson',
        subtitle: program.title,
        action: FilledButton(onPressed: () => context.push('/programs/${program.id}/purchase'), child: Text('Unlock for ${program.price}')),
        children: const [Text('Day 1 is free to try. Unlock the full program to watch every lesson.')],
      );
    }
    final challenge = program.challengeFor(day);
    return AppPage(
      title: 'Day $day lesson',
      subtitle: program.title,
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
      children: [
        const DrillMediaCard(title: 'Lesson video', mediaPath: placeholderLessonMediaPath),
        const SizedBox(height: AppSpacing.md),
        const Text('Example lesson. Coach Jeremy’s lesson videos are coming soon.'),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Key cues'),
        const SizedBox(height: AppSpacing.sm),
        Text(challenge.description),
      ],
    );
  }
}
