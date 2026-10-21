import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/theme/app_theme.dart';
import '../features/commerce/entitlements.dart';
import '../features/settings/appearance_settings_controller.dart';
import '../features/accounts/auth_service.dart';
import 'account_pages.dart';
import 'coach_pages.dart';
import 'commerce_pages.dart';
import 'manual_logger_pages.dart';
import 'onboarding_pages.dart';
import 'parent_pages.dart';
import 'player_pages.dart';
import 'progress_pages.dart';
import 'app_page.dart';
import 'session_pages.dart';
import 'training_pages.dart';
import 'training_state.dart';
import 'team_pages.dart';
import 'own_profile_setup.dart';
import 'workout_sync.dart';

const _kidDeviceBlocked = ['/parent', '/coach', '/signup', '/signin', '/welcome', '/pair', '/onboarding', '/paywall', '/profile'];

/// A paired kid device only gets Player screens. Returns where to send it, or null to let it through.
String? kidDeviceRedirect(String path) => _kidDeviceBlocked.any((prefix) => path == prefix || path.startsWith('$prefix/')) ? '/train' : null;

/// Parent and Coach screens are for signed-in accounts. Guests are sent to sign up; kid devices back to Train.
String? roleRedirect(AuthState? auth, String path) {
  if (auth is KidDeviceSession) return kidDeviceRedirect(path);
  final roleScreen = path == '/parent' || path.startsWith('/parent/') || path == '/coach' || path.startsWith('/coach/');
  return roleScreen && auth is! SignedInAccount ? '/signup' : null;
}

/// Where the app opens. `main()` sends a first launch to the welcome walkthrough; everything else opens Train.
final initialLocationProvider = Provider<String>((_) => '/train');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => authChanged.value++);
  final router = GoRouter(
    initialLocation: ref.read(initialLocationProvider),
    refreshListenable: authChanged,
    redirect: (_, state) => roleRedirect(ref.read(authStateProvider).value, state.uri.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _PlayerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (_, _) => const TrainPage(),
                routes: [
                  GoRoute(
                    path: 'session',
                    pageBuilder: (_, state) => CustomTransitionPage<void>(key: state.pageKey, opaque: false, child: const SizedBox.shrink(), transitionsBuilder: (_, _, _, child) => child),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/progress', builder: (_, _) => const ProgressPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/team', builder: (_, _) => const PlayerTeamsPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const MePage())],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ParentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/kids',
                builder: (_, _) => const ParentKidsPage(),
                routes: [
                  GoRoute(path: 'add', builder: (_, _) => const AddChildPage()),
                  GoRoute(path: 'approvals', builder: (_, _) => const LiveTeamRequestsPage(parent: true)),
                  GoRoute(path: 'train-together', builder: (_, _) => const ParentTrainTogetherPage()),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ParentChildPage(kidId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'teams',
                        builder: (_, state) => PlayerTeamsPage(profileId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'pair',
                        builder: (_, state) => KidPairingPage(kidId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/parent/verify', builder: (_, _) => const ParentVerifyPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/parent/account', builder: (_, _) => const ParentAccountPage())],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _CoachShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach/roster',
                builder: (_, _) => const LiveCoachRosterPage(),
                routes: [GoRoute(path: 'requests', builder: (_, _) => const LiveTeamRequestsPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach/homework',
                builder: (_, _) => const CoachHomeworkPage(),
                routes: [GoRoute(path: 'new', builder: (_, _) => const CoachAssignPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/coach/compliance', builder: (_, _) => const CoachCompliancePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/coach/team', builder: (_, _) => const LiveCoachTeamPage())],
          ),
        ],
      ),
      GoRoute(path: '/log/shots', builder: (_, _) => const ShotLoggerPage()),
      GoRoute(path: '/log/timer', builder: (_, _) => const TimerSetupPage()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
      GoRoute(
        path: '/signup/email',
        builder: (_, state) => EmailSignupPage(birthYear: int.tryParse(state.uri.queryParameters['year'] ?? '')),
      ),
      GoRoute(path: '/signin', builder: (_, _) => const SignInPage()),
      GoRoute(path: '/profile/setup', builder: (_, _) => const OwnProfileSetupPage()),
      GoRoute(path: '/coach/create', builder: (_, _) => const CreateTeamPage()),
      GoRoute(
        path: '/join',
        builder: (_, state) => JoinTeamPage(key: ValueKey(state.uri.toString()), code: state.uri.queryParameters['code'] ?? '', profileId: state.uri.queryParameters['profile']),
      ),
      GoRoute(
        path: '/teams/discover',
        builder: (_, state) => DiscoverTeamsPage(profileId: state.uri.queryParameters['profile']),
      ),
      GoRoute(path: '/pair', builder: (_, _) => const PairDevicePage()),
      GoRoute(path: '/onboarding/role', builder: (_, _) => const RoleOnboardingPage()),
      GoRoute(
        path: '/paywall',
        builder: (_, state) {
          final coach = state.uri.queryParameters['plan'] == 'coach';
          return PaywallPage(key: ValueKey(coach), coach: coach);
        },
      ),
      GoRoute(
        path: '/programs',
        builder: (_, _) => const ProgramsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ProgramDetailPage(programId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'day/:day',
                builder: (_, state) => ProgramDayPage(programId: state.pathParameters['id']!, day: int.tryParse(state.pathParameters['day']!) ?? 0),
                routes: [
                  GoRoute(
                    path: 'lesson',
                    builder: (_, state) => ProgramLessonPage(programId: state.pathParameters['id']!, day: int.tryParse(state.pathParameters['day']!) ?? 0),
                  ),
                ],
              ),
            ],
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
      GoRoute(path: '/history', builder: (_, _) => const HistoryListPage()),
      GoRoute(path: '/progress/drills', builder: (_, _) => const DrillBreakdownPage()),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) => SummaryPage(workoutId: state.pathParameters['id']),
      ),
    ],
    errorBuilder: (context, state) => AppPage(
      title: 'Screen not found',
      action: FilledButton(onPressed: () => context.go('/train'), child: const Text('Back to Train')),
      children: [Text('We can\'t find that screen: ${state.uri.path}')],
    ),
  );
  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});

class HockeyApp extends ConsumerWidget {
  const HockeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps finished workouts flowing to the player's account for as long as the app is open.
    ref.listen(workoutSyncProvider, (_, _) {});
    ref.watch(purchasesIdentityProvider);
    return MaterialApp.router(
      title: 'How To Hockey',
      debugShowCheckedModeBanner: false,
      theme: HockeyTheme.light,
      darkTheme: HockeyTheme.dark,
      themeMode: ref.watch(appearanceProvider).themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class _PlayerShell extends ConsumerWidget {
  const _PlayerShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trainingSessionProvider);
    final progress = ref.watch(workoutSheetProgressProvider);
    final routerDelegate = ref.watch(appRouterProvider).routerDelegate;
    return ListenableBuilder(
      listenable: routerDelegate,
      builder: (context, _) {
        final sessionActive = routerDelegate.currentConfiguration.uri.path == '/train/session';
        final showSession = !session.dismissed && (session.startedAt != null || sessionActive);
        final sheetProgress = showSession ? progress : 0.0;
        final deviceBottom = MediaQuery.paddingOf(context).bottom;
        final navigationHeight = 80 + deviceBottom;
        return Scaffold(
          // The navigation keeps its layout slot so the session sheet's viewport stays
          // fixed; matching the sheet colour keeps the vacated strip from flashing.
          backgroundColor: showSession ? HockeyTheme.dark.scaffoldBackgroundColor : null,
          extendBody: true,
          body: Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: navigationHeight + (showSession ? WorkoutSessionPanel.headerHeightOf(context) : 0)),
                    child: MediaQuery(
                      data: media.copyWith(padding: media.padding.copyWith(bottom: 0), viewPadding: media.viewPadding.copyWith(bottom: 0)),
                      child: shell,
                    ),
                  ),
                  if (showSession)
                    Positioned.fill(
                      child: MediaQuery(
                        data: media.copyWith(padding: media.padding.copyWith(bottom: deviceBottom)),
                        child: WorkoutSessionPanel(key: ValueKey(session.startedAt), expandRequested: sessionActive, navigationHeight: navigationHeight),
                      ),
                    ),
                ],
              );
            },
          ),
          bottomNavigationBar: Transform.translate(
            key: const ValueKey('player-navigation-motion'),
            offset: Offset(0, navigationHeight * sheetProgress),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) {
                Feedback.forTap(context);
                shell.goBranch(index, initialLocation: index == 0 || index == shell.currentIndex);
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
      },
    );
  }
}

class _ParentShell extends StatelessWidget {
  const _ParentShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) {
        Feedback.forTap(context);
        shell.goBranch(index, initialLocation: index == shell.currentIndex);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.family_restroom_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.family_restroom, selected: shell.currentIndex == 0),
          label: 'Kids',
        ),
        NavigationDestination(
          icon: const Icon(Icons.verified_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.verified, selected: shell.currentIndex == 1),
          label: 'Verify',
        ),
        NavigationDestination(
          icon: const Icon(Icons.manage_accounts_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.manage_accounts, selected: shell.currentIndex == 2),
          label: 'Account',
        ),
      ],
    ),
  );
}

class _CoachShell extends StatelessWidget {
  const _CoachShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) {
        Feedback.forTap(context);
        shell.goBranch(index, initialLocation: index == shell.currentIndex);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.groups_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.groups, selected: shell.currentIndex == 0),
          label: 'Roster',
        ),
        NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.assignment, selected: shell.currentIndex == 1),
          label: 'Homework',
        ),
        NavigationDestination(
          icon: const Icon(Icons.fact_check_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.fact_check, selected: shell.currentIndex == 2),
          label: 'Compliance',
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: _NavSelectionIcon(icon: Icons.settings, selected: shell.currentIndex == 3),
          label: 'Team',
        ),
      ],
    ),
  );
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
