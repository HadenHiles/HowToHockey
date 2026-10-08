import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/theme/app_theme.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'player_pages.dart';
import 'app_page.dart';
import 'session_pages.dart';
import 'training_pages.dart';
import 'training_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/train',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _PlayerShell(shell: shell, sessionActive: state.matchedLocation == '/train/session'),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (_, _) => const TrainPage(),
                routes: [GoRoute(path: 'session', builder: (_, _) => const SessionPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/progress', builder: (_, _) => const ProgressPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/team', builder: (_, _) => const TeamPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const MePage())],
          ),
        ],
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupPage()),
      GoRoute(path: '/focus', builder: (_, _) => const FocusPage()),
      GoRoute(path: '/routine', builder: (_, _) => const RoutinePage()),
      GoRoute(path: '/routines', builder: (_, _) => const RoutineLibraryPage()),
      GoRoute(path: '/routines/new', builder: (_, _) => const RoutineBuilderPage()),
      GoRoute(
        path: '/routines/:id/edit',
        builder: (_, state) => RoutineBuilderPage(routineId: state.pathParameters['id']),
      ),
      GoRoute(path: '/library', builder: (_, _) => const LibraryPage()),
      GoRoute(
        path: '/drills/:id',
        builder: (_, state) => DrillDetailPage(drillId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session-drills/:id',
        builder: (_, state) => DrillDetailPage(drillId: state.pathParameters['id']!, fromSession: true),
      ),
      GoRoute(path: '/rest', redirect: (_, _) => '/train/session'),
      GoRoute(path: '/session', redirect: (_, _) => '/train/session'),
      GoRoute(path: '/summary', builder: (_, _) => const SummaryPage()),
    ],
    errorBuilder: (context, state) => AppPage(
      title: 'Screen not found',
      action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
      children: [Text('The requested screen is unavailable: ${state.uri.path}')],
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class HockeyApp extends ConsumerWidget {
  const HockeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'How To Hockey',
    debugShowCheckedModeBanner: false,
    theme: HockeyTheme.light,
    darkTheme: HockeyTheme.dark,
    themeMode: ref.watch(appearanceProvider).themeMode,
    routerConfig: ref.watch(appRouterProvider),
  );
}

class _PlayerShell extends ConsumerWidget {
  const _PlayerShell({required this.shell, required this.sessionActive});

  final StatefulNavigationShell shell;
  final bool sessionActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetProgress = sessionActive ? ref.watch(workoutSheetProgressProvider) : 0.0;
    final navigationHeight = 80 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      // The navigation keeps its layout slot so the session sheet's viewport stays
      // fixed; matching the sheet colour keeps the vacated strip from flashing.
      backgroundColor: sessionActive ? HockeyTheme.dark.scaffoldBackgroundColor : null,
      body: shell,
      bottomNavigationBar: Transform.translate(
        key: const ValueKey('player-navigation-motion'),
        offset: Offset(0, navigationHeight * sheetProgress),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) {
            Feedback.forTap(context);
            shell.goBranch(index, initialLocation: index == shell.currentIndex);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.sports_hockey_outlined),
              selectedIcon: _NavSelectionIcon(icon: Icons.sports_hockey, selected: shell.currentIndex == 0),
              label: 'Train',
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: _NavSelectionIcon(icon: Icons.insights, selected: shell.currentIndex == 1),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: _NavSelectionIcon(icon: Icons.groups, selected: shell.currentIndex == 2),
              label: 'Team',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: _NavSelectionIcon(icon: Icons.person, selected: shell.currentIndex == 3),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavSelectionIcon extends StatelessWidget {
  const _NavSelectionIcon({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: selected || reduceMotion ? 1 : .78,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: .14) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        child: Icon(icon),
      ),
    );
  }
}
