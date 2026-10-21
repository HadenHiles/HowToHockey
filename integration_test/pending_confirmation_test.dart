import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';
import 'package:how_to_hockey/features/sessions/session_repository.dart';
import 'package:how_to_hockey/main.dart' as app;

/// A child's workout stays pending, uncounted, until a grown-up confirms it; then the Cloud Function counts it.
/// Run against the local emulators (auth, firestore, functions):
///   npm --prefix functions run build
///   firebase emulators:exec --project how-to-hockey --only auth,firestore,functions \
///     "flutter test integration_test/pending_confirmation_test.dart -d DEVICE --dart-define=USE_EMULATORS=true"
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a pending workout is counted only after a parent confirms it', timeout: const Timeout(Duration(minutes: 3)), (tester) async {
    expect(const bool.fromEnvironment('USE_EMULATORS'), isTrue, reason: 'Run against the local emulators only.');
    final handler = FlutterError.onError;
    await app.main();
    FlutterError.onError = handler;
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    final now = DateTime.now();
    await FirebaseAuthService().createEmailAccount(email: 'pending${now.millisecondsSinceEpoch}@example.com', password: 'correct horse battery');
    final profiles = ProfileRepository();
    await profiles.createOwnProfile(displayName: 'Pat H.', birthYear: now.year - 30, now: now);
    final childId = await profiles.createChildProfile(displayName: 'Avery H.', birthYear: now.year - 9, now: now);

    final drills = parseDrillCatalog(await rootBundle.loadString(drillCatalogAsset));
    final corner = drills.firstWhere((d) => d.id == 'pick-your-corner');
    final at = now.toUtc();
    final record = WorkoutRecord(
      id: '${at.millisecondsSinceEpoch}',
      startedAt: at,
      explicitTzOffsetMinutes: 0,
      drills: [corner],
      logs: [(drillId: corner.id, log: SetLog(setIndex: 0, reps: 10, hits: 8, loggedAt: at))],
    );
    final repository = SessionRepository();
    await repository.upload(childId, SessionUpload(record: record, endedAt: at.add(const Duration(minutes: 5)), routineName: 'Garage shooting', activeSeconds: 300, pending: true));

    final pending = await repository.watchPending(childId).first;
    expect(pending.map((w) => w.id), [record.id]);
    final shown = await repository.loadPendingDrills(childId, record.id);
    expect(shown.single.sets.single.hits, 8);

    final stats = FirebaseFirestore.instance.doc('profiles/$childId/stats/lifetime');
    await tester.pump(const Duration(seconds: 6));
    expect((await stats.get()).exists, isFalse, reason: 'a pending workout must not be counted');

    await repository.confirm(pending.single);
    Map<String, dynamic>? data;
    for (var i = 0; i < 30 && data == null; i++) {
      await tester.pump(const Duration(seconds: 1));
      data = (await stats.get()).data();
    }
    debugPrint('E2E confirmed -> ${data?['workouts']} workout, ${data?['shots']} shots');
    expect(data?['workouts'], 1);
    expect(data?['shots'], 10);
    expect(await repository.watchPending(childId).first, isEmpty);

    final second = WorkoutRecord(
      id: '${at.millisecondsSinceEpoch + 1}',
      startedAt: at,
      explicitTzOffsetMinutes: 0,
      drills: [corner],
      logs: [(drillId: corner.id, log: SetLog(setIndex: 0, reps: 10, hits: 1, loggedAt: at))],
    );
    await repository.upload(childId, SessionUpload(record: second, endedAt: at, routineName: 'Oops', activeSeconds: 60, pending: true));
    await repository.discard((await repository.watchPending(childId).first).single);
    expect(await repository.watchPending(childId).first, isEmpty);
    await tester.pump(const Duration(seconds: 3));
    expect((await stats.get()).data()?['workouts'], 1, reason: 'a discarded workout is never counted');
    await FirebaseAuth.instance.signOut();
  });
}
