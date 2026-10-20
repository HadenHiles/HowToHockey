import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/progress_stats.dart';

/// A finished workout, ready to store.
class SessionUpload {
  const SessionUpload({required this.record, required this.endedAt, required this.routineName, required this.activeSeconds});

  final WorkoutRecord record;
  final DateTime endedAt;
  final String routineName;
  final int activeSeconds;
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
      'status': 'completed',
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

  /// The player's lifetime stats as the server last computed them, or null if nothing has been counted yet.
  Stream<LifetimeStats?> watchStats(String profileId) =>
      _db.collection('profiles').doc(profileId).collection('stats').doc('lifetime').snapshots().map((doc) => doc.exists ? LifetimeStats.fromJson(doc.data()) : null);
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());
