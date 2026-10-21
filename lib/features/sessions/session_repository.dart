import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drills/models/drill.dart';
import '../progress/progress_stats.dart';

/// A finished workout, ready to store.
class SessionUpload {
  const SessionUpload({required this.record, required this.endedAt, required this.routineName, required this.activeSeconds, this.pending = false});

  final WorkoutRecord record;
  final DateTime endedAt;
  final String routineName;
  final int activeSeconds;

  /// A child's device sends its workout as pending: a parent confirms it before it is counted.
  final bool pending;
}

/// A workout a child finished that is waiting for a grown-up.
class PendingWorkout {
  const PendingWorkout({required this.profileId, required this.id, required this.routineName, required this.startedAt, required this.drillCount, required this.activeSeconds});

  final String profileId;
  final String id;
  final String routineName;
  final DateTime startedAt;
  final int drillCount;
  final int activeSeconds;
}

/// One drill of a pending workout, with the child's sets, for the grown-up to check.
class PendingDrill {
  const PendingDrill({required this.title, required this.trackingType, required this.sets});

  final String title;
  final TrackingType trackingType;
  final List<SetLog> sets;
}

/// Stores finished workouts under a player profile and reads back the stats a Cloud Function builds from them.
class SessionRepository {
  SessionRepository([FirebaseFirestore? firestore]) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Writes the workout and its sets in one batch, so the server never sees half of it.
  /// Saving the same workout again is fine: it counts once.
  Future<void> upload(String profileId, SessionUpload upload) async {
    final sessionRef = _db.collection('profiles').doc(profileId).collection('sessions').doc(upload.record.id);
    final byId = {for (final drill in upload.record.drills) drill.id: drill};
    final order = [for (final drill in upload.record.drills) drill.id];
    final batch = _db.batch();
    batch.set(sessionRef, {
      'status': upload.pending ? 'pending' : 'completed',
      'startedAt': Timestamp.fromDate(upload.record.startedAt),
      'endedAt': Timestamp.fromDate(upload.endedAt),
      'tzOffsetMinutes': upload.record.tzOffsetMinutes,
      'routineName': upload.routineName.length > 80 ? upload.routineName.substring(0, 80) : upload.routineName,
      'drillCount': order.length,
      'activeSeconds': upload.activeSeconds.clamp(0, 86400),
    });
    for (final (index, id) in order.indexed) {
      final drill = byId[id]!;
      batch.set(sessionRef.collection('drills').doc('$index'), {
        'drillId': drill.id,
        'title': drill.title.length > 80 ? drill.title.substring(0, 80) : drill.title,
        'trackingType': drill.trackingType.name,
        'skillWeights': {for (final entry in drill.skillWeights.entries) entry.key.name: entry.value},
        'estimatedSecondsPerSet': drill.estimatedSecondsPerSet,
        'sets': [
          for (final entry in upload.record.logs)
            if (entry.drillId == id)
              {
                'reps': entry.log.reps,
                'hits': entry.log.hits,
                'seconds': entry.log.seconds,
                'streak': entry.log.streak,
                'completed': entry.log.completed,
                'loggedAt': Timestamp.fromDate(entry.log.loggedAt),
              },
        ],
      });
    }
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      // Sessions can't be rewritten, so "permission denied" on a workout that is already there means it was saved before.
      if (error.code == 'permission-denied' && (await sessionRef.get()).exists) return;
      rethrow;
    }
  }

  /// Workouts a child has finished that no grown-up has confirmed yet, oldest first.
  Stream<List<PendingWorkout>> watchPending(String profileId) => _db.collection('profiles').doc(profileId).collection('sessions').where('status', isEqualTo: 'pending').snapshots().map((snapshot) {
    final workouts = [
      for (final doc in snapshot.docs)
        PendingWorkout(
          profileId: profileId,
          id: doc.id,
          routineName: (doc.data()['routineName'] as String?) ?? 'Workout',
          startedAt: (doc.data()['startedAt'] as Timestamp).toDate(),
          drillCount: (doc.data()['drillCount'] as num?)?.toInt() ?? 0,
          activeSeconds: (doc.data()['activeSeconds'] as num?)?.toInt() ?? 0,
        ),
    ];
    return workouts..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  });

  /// The drills and sets of a pending workout.
  Future<List<PendingDrill>> loadPendingDrills(String profileId, String sessionId) async {
    final snapshot = await _db.collection('profiles').doc(profileId).collection('sessions').doc(sessionId).collection('drills').get();
    final docs = [...snapshot.docs]..sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
    return [
      for (final doc in docs)
        PendingDrill(
          title: (doc.data()['title'] as String?) ?? (doc.data()['drillId'] as String? ?? 'Drill'),
          trackingType: TrackingType.values.asNameMap()[doc.data()['trackingType']] ?? TrackingType.volume,
          sets: [
            for (final (index, raw) in ((doc.data()['sets'] as List?) ?? const []).indexed)
              SetLog(
                setIndex: index,
                reps: (raw['reps'] as num?)?.toInt(),
                hits: (raw['hits'] as num?)?.toInt(),
                seconds: (raw['seconds'] as num?)?.toInt(),
                streak: (raw['streak'] as num?)?.toInt(),
                completed: raw['completed'] as bool?,
                loggedAt: (raw['loggedAt'] as Timestamp).toDate(),
              ),
          ],
        ),
    ];
  }

  /// A grown-up confirms the workout; the server then counts it.
  Future<void> confirm(PendingWorkout workout) => _sessionRef(workout).update({'status': 'completed', 'confirmedAt': FieldValue.serverTimestamp()});

  /// A grown-up throws the workout away.
  Future<void> discard(PendingWorkout workout) async {
    final ref = _sessionRef(workout);
    final drills = await ref.collection('drills').get();
    final batch = _db.batch();
    for (final doc in drills.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _sessionRef(PendingWorkout workout) => _db.collection('profiles').doc(workout.profileId).collection('sessions').doc(workout.id);

  /// The player's lifetime stats as the server last computed them, or null if nothing has been counted yet.
  Stream<LifetimeStats?> watchStats(String profileId) =>
      _db.collection('profiles').doc(profileId).collection('stats').doc('lifetime').snapshots().map((doc) => doc.exists ? LifetimeStats.fromJson(doc.data()) : null);
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());
