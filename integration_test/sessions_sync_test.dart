import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/app/training_state.dart';
import 'package:how_to_hockey/app/workout_history.dart';
import 'package:how_to_hockey/app/workout_sync.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart' as app;
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A finished workout travels from the phone, through the security rules and the Cloud Function, and
/// comes back as stats. Run against the local emulators (auth, firestore, functions):
///   npm --prefix functions run build
///   firebase emulators:start --only auth,firestore,functions --project how-to-hockey
///   flutter test integration_test/sessions_sync_test.dart -d DEVICE --dart-define=USE_EMULATORS=true
/// The start of the `E2E` lines shows what happened; the test fails if the stats never arrive.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a finished workout is counted by the server', timeout: const Timeout(Duration(minutes: 3)), (tester) async {
    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();

    // Start from a clean guest session: iOS keeps the previous run's sign-in.
    await container.read(authServiceProvider).signOut();
    await tester.pump(const Duration(seconds: 1));

    // A guest finishes a workout, then makes an account: it is claimed by the new profile.
    final catalog = await container.read(drillCatalogProvider.future);
    Drill one(String id) => catalog.firstWhere((d) => d.id == id).copyWith(defaultPrescription: catalog.firstWhere((d) => d.id == id).defaultPrescription.copyWith(sets: 1));
    final at = DateTime.now().toUtc();
    final session = TrainingSession(
      drills: [one('pick-your-corner'), one('ball-bounce-streak'), one('quiet-hands-quick-feet')],
      startedAt: at,
      endedAt: at.add(const Duration(minutes: 8)),
      logs: [
        (drillId: 'pick-your-corner', log: SetLog(setIndex: 0, reps: 10, hits: 8, loggedAt: at)),
        (drillId: 'ball-bounce-streak', log: SetLog(setIndex: 0, streak: 22, loggedAt: at)),
        (drillId: 'quiet-hands-quick-feet', log: SetLog(setIndex: 0, seconds: 30, loggedAt: at)),
      ],
    );
    container.listen(workoutSyncProvider, (_, _) {});
    container.read(workoutHistoryProvider.notifier).add(session);
    debugPrint('E2E guest workout queued: ${container.read(workoutSyncProvider).length}');

    final now = DateTime.now();
    await container.read(authServiceProvider).createEmailAccount(email: 'sync${now.millisecondsSinceEpoch}@example.com', password: 'correct horse battery');
    final profileId = await container.read(profileRepositoryProvider).createOwnProfile(displayName: 'Syd T.', birthYear: now.year - 30, now: now);
    debugPrint('E2E profile $profileId');

    final id = workoutId(session);
    final stats = FirebaseFirestore.instance.doc('profiles/$profileId/stats/lifetime');
    Map<String, dynamic>? data;
    for (var i = 0; i < 40 && data == null; i++) {
      await tester.pump(const Duration(seconds: 1));
      await container.read(workoutSyncProvider.notifier).flush();
      data = (await stats.get()).data();
    }
    debugPrint('E2E stats ${data?['workouts']} workouts, ${data?['shots']} shots, ${data?['seconds']} s, recent ${data?['recent']}');
    expect(data, isNotNull, reason: 'the function never counted the workout');
    expect(data!['workouts'], 1);
    expect(data['shots'], 10);
    expect(data['recent'], [id]);

    await tester.pump(const Duration(seconds: 2));
    final shown = container.read(progressStatsProvider);
    debugPrint('E2E shown ${shown.workouts} workouts, ${shown.shots} shots, bests ${shown.bests.keys.toList()}');
    expect(shown.workouts, 1);
    expect(shown.bests.keys, containsAll(['accuracy:pick-your-corner', 'streak:ball-bounce-streak']));
    for (var i = 0; i < 10 && container.read(workoutSyncProvider).isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(container.read(workoutSyncProvider), isEmpty, reason: 'nothing left to track once the server counted it');

    await FirebaseAuth.instance.signOut();
    debugPrint('E2E done');
  });
}
