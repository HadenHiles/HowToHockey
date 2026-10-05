import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/theme/app_theme.dart';
import '../features/settings/appearance_settings_controller.dart';
import 'player_pages.dart';
import 'preview_page.dart';
import 'session_pages.dart';
import 'training_pages.dart';

final previewRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/train',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _PlayerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/train', builder: (_, _) => const TrainPreviewPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/progress', builder: (_, _) => const ProgressPreviewPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/team', builder: (_, _) => const TeamPreviewPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const MePreviewPage())],
          ),
        ],
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupPreviewPage()),
      GoRoute(path: '/focus', builder: (_, _) => const FocusPreviewPage()),
      GoRoute(path: '/routine', builder: (_, _) => const RoutinePreviewPage()),
      GoRoute(path: '/library', builder: (_, _) => const LibraryPreviewPage()),
      GoRoute(
        path: '/drills/:id',
        builder: (_, state) => DrillDetailPreviewPage(drillId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/session', builder: (_, _) => const SessionPreviewPage()),
      GoRoute(
        path: '/rest',
        builder: (_, state) => RestPreviewPage(seconds: state.extra is int ? state.extra! as int : 45),
      ),
      GoRoute(path: '/summary', builder: (_, _) => const SummaryPreviewPage()),
    ],
    errorBuilder: (context, state) => PreviewPage(
      title: 'Screen not found',
      action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
      children: [Text('The requested preview screen is unavailable: ${state.uri.path}')],
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class UxPreviewApp extends ConsumerWidget {
  const UxPreviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(title: 'How To Hockey · UX Preview', debugShowCheckedModeBanner: false, theme: HockeyTheme.light, darkTheme: HockeyTheme.dark, themeMode: ref.watch(appearanceProvider).themeMode, routerConfig: ref.watch(previewRouterProvider));
}

class _PlayerShell extends StatelessWidget {
  const _PlayerShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.sports_hockey_outlined), selectedIcon: Icon(Icons.sports_hockey), label: 'Train'),
        NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
      ],
    ),
  );
}
