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
import '../features/drills/models/drill.dart';
import '../features/programs/program_repository.dart';
import '../features/profiles/active_player.dart';
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

String programStoreOffering(String programId) => 'program_$programId';

class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalog = ref.watch(programCatalogProvider);
    final player = ref.watch(activePlayerProvider);
    final dashboard = player == null ? null : ref.watch(programDashboardProvider(player.id));
    final entitlements = {...?ref.watch(purchasedEntitlementsProvider).value, ...?dashboard?.value?.ownedProgramIds};
    return AppPage(
      title: 'Programs',
      subtitle: 'Pick what you want to get better at. Every program starts with a free training day.',
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/train'))],
      children: [
        if (dashboard?.hasError == true)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Couldn’t check this player’s program access. ${dashboard!.error}'),
              TextButton(onPressed: () => ref.invalidate(programDashboardProvider(player!.id)), child: const Text('Try again')),
            ],
          )
        else if (catalog.hasError)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Couldn’t load programs. Check your connection and try again.'),
              TextButton(onPressed: () => ref.invalidate(programCatalogProvider), child: const Text('Try again')),
            ],
          )
        else if (catalog.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          for (final program in catalog.value!) ...[
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
    final catalog = ref.watch(programCatalogProvider);
    if (catalog.hasError) return _programCatalogError(context, ref);
    if (catalog.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final program = catalog.value!.where((item) => item.id == programId).firstOrNull;
    if (program == null) return _programNotFound(context);
    final theme = Theme.of(context);
    final player = ref.watch(activePlayerProvider);
    final dashboard = player == null ? null : ref.watch(programDashboardProvider(player.id));
    if (dashboard?.hasError == true) return _programAccessError(context, ref, player!.id);
    if (dashboard?.isLoading == true) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement) || (dashboard?.value?.ownedProgramIds.contains(program.entitlement) ?? false);
    final progressState = player == null ? null : ref.watch(programProgressProvider((profileId: player.id, programId: program.id)));
    if (progressState?.hasError == true) {
      return AppPage(
        title: program.title,
        action: FilledButton(onPressed: () => ref.invalidate(programProgressProvider((profileId: player!.id, programId: program.id))), child: const Text('Try again')),
        children: const [Text('Couldn’t load program progress. Please try again.')],
      );
    }
    if (progressState?.isLoading == true) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final progress = progressState?.value ?? const ProgramProgress();
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
          LinearProgressIndicator(value: progress.completedDays.length / program.days, semanticsLabel: '${progress.completedDays.length} of ${program.days} program days complete'),
          const SizedBox(height: AppSpacing.xs),
          Text('Day ${progress.nextDay.clamp(1, program.days)} of ${program.days}', style: theme.textTheme.bodySmall),
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
            leading: Icon(progress.isComplete(day) ? Icons.check_circle_outline : (day == 1 || (owned && (player == null || progress.isAvailable(day))) ? Icons.play_circle_outline : Icons.lock_outline)),
            title: Text('Day $day'),
            subtitle: Text(
              progress.isComplete(day)
                  ? (progress.isChallengeComplete(day) ? 'Workout and challenge complete' : 'Workout complete')
                  : day == 1
                  ? 'Free preview · routine and challenge'
                  : (owned ? (player == null || progress.isAvailable(day) ? 'Ready to train' : 'Finish Day ${progress.nextDay} first') : 'Unlocks with the full program'),
            ),
            onTap: () {
              if (day == 1 || (owned && (player == null || progress.isAvailable(day)))) {
                context.push('/programs/${program.id}/day/$day');
              } else if (owned) {
                context.push('/programs/${program.id}/day/${progress.nextDay}');
              } else {
                context.push('/programs/${program.id}/purchase');
              }
            },
          ),
      ],
    );
  }
}

class ProgramDayPage extends ConsumerStatefulWidget {
  const ProgramDayPage({required this.programId, required this.day, super.key});

  final String programId;
  final int day;

  @override
  ConsumerState<ProgramDayPage> createState() => _ProgramDayPageState();
}

class _ProgramDayPageState extends ConsumerState<ProgramDayPage> {
  var _starting = false;

  Future<void> _start(List<Drill> routine, String? profileId) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final runId = profileId == null ? null : await ref.read(programRepositoryProvider).startDay(profileId: profileId, programId: widget.programId, day: widget.day);
      if (!mounted) return;
      ref.read(trainingSessionProvider.notifier).start(routine, programRunId: runId);
      context.go('/train/session');
    } on ProgramException catch (error) {
      if (mounted) showFeatureMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(programCatalogProvider);
    if (catalogState.hasError) return _programCatalogError(context, ref);
    if (catalogState.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final program = catalogState.value!.where((item) => item.id == widget.programId).firstOrNull;
    if (program == null || widget.day < 1 || widget.day > program.days) {
      return AppPage(
        title: 'Day not found',
        action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
        children: const [Text('We can\'t find this program day.')],
      );
    }
    final player = ref.watch(activePlayerProvider);
    final dashboard = player == null ? null : ref.watch(programDashboardProvider(player.id));
    if (dashboard?.hasError == true) return _programAccessError(context, ref, player!.id);
    if (player != null && dashboard!.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement) || (dashboard?.value?.ownedProgramIds.contains(program.entitlement) ?? false);
    final progressKey = player == null ? null : (profileId: player.id, programId: program.id);
    final progressState = progressKey == null ? null : ref.watch(programProgressProvider(progressKey));
    if (progressState?.hasError == true) {
      return AppPage(
        title: 'Day ${widget.day} of ${program.days}',
        subtitle: program.title,
        action: FilledButton(onPressed: () => ref.invalidate(programProgressProvider(progressKey!)), child: const Text('Try again')),
        children: const [Text('Couldn’t load program progress. Please try again.')],
      );
    }
    if (progressState?.isLoading == true) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final progress = progressState?.value ?? const ProgramProgress();
    if (widget.day != 1 && !owned) {
      return AppPage(
        title: 'Unlock this day',
        subtitle: program.title,
        action: FilledButton(onPressed: () => context.push('/programs/${program.id}/purchase'), child: Text('Unlock for ${program.price}')),
        children: const [Text('Day 1 is free to try. Unlock the full program to train every day.')],
      );
    }
    if (player != null && widget.day > progress.nextDay) {
      return AppPage(
        title: 'Finish Day ${progress.nextDay} first',
        subtitle: program.title,
        action: FilledButton(onPressed: () => context.go('/programs/${program.id}/day/${progress.nextDay}'), child: Text('Go to Day ${progress.nextDay}')),
        children: const [Text('Complete each workout in order to unlock the next day.')],
      );
    }
    final theme = Theme.of(context);
    final drillCatalogState = ref.watch(drillCatalogProvider);
    if (drillCatalogState.hasError) {
      return AppPage(
        title: 'Day ${widget.day} of ${program.days}',
        subtitle: program.title,
        action: FilledButton(onPressed: () => ref.invalidate(drillCatalogProvider), child: const Text('Try again')),
        children: const [Text('Couldn’t load this program workout. Please try again.')],
      );
    }
    final catalog = drillCatalogState.value;
    if (catalog == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final drillById = {for (final drill in catalog) drill.id: drill};
    final content = program.day(widget.day);
    final routine = [
      for (final step in content.drills)
        if (drillById[step.drillId] case final drill?) drill.copyWith(defaultPrescription: drill.defaultPrescription.copyWith(sets: step.sets)),
    ];
    final missingDrills = content.drills.where((step) => !drillById.containsKey(step.drillId)).toList();
    return AppPage(
      title: 'Day ${widget.day} of ${program.days}',
      subtitle: program.title,
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
      action: FilledButton(
        onPressed: routine.isEmpty || missingDrills.isNotEmpty || _starting ? null : () => _start(routine, player?.id),
        child: Text(_starting ? 'Getting workout ready…' : 'Start this workout'),
      ),
      children: [
        TrainingCard(
          onTap: () => context.push('/programs/${program.id}/day/${widget.day}/lesson'),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.lessonTitle, style: theme.textTheme.titleMedium),
                    Text('Coach Jeremy · ${content.lessonMinutes} min', style: theme.textTheme.bodySmall),
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
                Text(content.challengeTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(content.challengeDescription),
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
    final catalog = ref.watch(programCatalogProvider);
    if (catalog.hasError) return _programCatalogError(context, ref);
    if (catalog.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final program = catalog.value!.where((item) => item.id == widget.programId).firstOrNull;
    if (program == null) return _programNotFound(context);
    final close = IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop());
    final player = ref.watch(activePlayerProvider);
    final dashboard = player == null ? null : ref.watch(programDashboardProvider(player.id));
    if (dashboard?.hasError == true) return _programAccessError(context, ref, player!.id);
    if (dashboard?.isLoading == true) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final owned = ref.watch(purchasedEntitlementsProvider).value?.contains(program.entitlement) == true || (dashboard?.value?.ownedProgramIds.contains(program.entitlement) ?? false);
    if (owned) {
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
            if (!mounted) return;
            if (player != null) ref.invalidate(programDashboardProvider(player.id));
            context.go('/programs/${program.id}');
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
    final catalog = ref.watch(programCatalogProvider);
    if (catalog.hasError) return _programCatalogError(context, ref);
    if (catalog.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final program = catalog.value!.where((item) => item.id == programId).firstOrNull;
    if (program == null || day < 1 || day > program.days) return _programNotFound(context);
    final player = ref.watch(activePlayerProvider);
    final dashboard = player == null ? null : ref.watch(programDashboardProvider(player.id));
    if (dashboard?.hasError == true) return _programAccessError(context, ref, player!.id);
    if (dashboard?.isLoading == true) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final owned = (ref.watch(purchasedEntitlementsProvider).value ?? const <String>{}).contains(program.entitlement) || (dashboard?.value?.ownedProgramIds.contains(program.entitlement) ?? false);
    if (day != 1 && !owned) {
      return AppPage(
        title: 'Unlock this lesson',
        subtitle: program.title,
        action: FilledButton(onPressed: () => context.push('/programs/${program.id}/purchase'), child: Text('Unlock for ${program.price}')),
        children: const [Text('Day 1 is free to try. Unlock the full program to watch every lesson.')],
      );
    }
    final content = program.day(day);
    return AppPage(
      title: 'Day $day lesson',
      subtitle: program.title,
      actions: [IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop())],
      children: [
        const DrillMediaCard(title: 'Lesson video', mediaPath: placeholderLessonMediaPath),
        const SizedBox(height: AppSpacing.md),
        Text('${content.lessonTitle}. Coach Jeremy’s lesson videos are coming soon.'),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeading(title: 'Key cues'),
        const SizedBox(height: AppSpacing.sm),
        Text(content.challengeDescription),
      ],
    );
  }
}

Widget _programCatalogError(BuildContext context, WidgetRef ref) => AppPage(
  title: 'Programs unavailable',
  subtitle: 'Couldn’t load programs. Check your connection and try again.',
  action: FilledButton(onPressed: () => ref.invalidate(programCatalogProvider), child: const Text('Try again')),
  children: const [],
);

Widget _programAccessError(BuildContext context, WidgetRef ref, String profileId) => AppPage(
  title: 'Program access unavailable',
  subtitle: 'Couldn’t check this player’s program access. Check your connection and try again.',
  action: FilledButton(onPressed: () => ref.invalidate(programDashboardProvider(profileId)), child: const Text('Try again')),
  children: const [],
);

Widget _programNotFound(BuildContext context) => AppPage(
  title: 'Program not found',
  action: FilledButton(onPressed: () => context.go('/programs'), child: const Text('Back to Programs')),
  children: const [Text('We can’t find this program.')],
);
