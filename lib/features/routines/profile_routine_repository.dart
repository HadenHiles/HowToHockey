import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../teams/team_repository.dart';

/// A routine a parent saved for a child: library drills with set counts.
class ProfileRoutine {
  const ProfileRoutine({required this.id, required this.routine});

  final String id;
  final TeamRoutine routine;
}

class RoutineException implements Exception {
  const RoutineException(this.message);
  final String message;
}

/// A child's routines live on their profile, so a parent's changes reach the child's own device.
class ProfileRoutineRepository {
  Stream<List<ProfileRoutine>> watch(String profileId) => FirebaseFirestore.instance.collection('profiles/$profileId/routines').snapshots().map((snapshot) {
    final routines = [
      for (final doc in snapshot.docs)
        if (TeamRoutine.fromJson(doc.data()) case final routine?) ProfileRoutine(id: doc.id, routine: routine),
    ];
    return routines..sort((a, b) => a.routine.name.compareTo(b.routine.name));
  });

  /// Saves a new routine, or replaces [routineId]. The server keeps the free-plan cap.
  Future<void> save(String profileId, TeamRoutine routine, {String? routineId}) => _call('saveProfileRoutine', {
    'profileId': profileId,
    'routineId': ?routineId,
    'routine': {
      'name': routine.name,
      'drills': [
        for (final drill in routine.drills) {'drillId': drill.drillId, 'sets': drill.sets},
      ],
    },
  });

  Future<void> delete(String profileId, String routineId) => _call('deleteProfileRoutine', {'profileId': profileId, 'routineId': routineId});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await FirebaseFunctions.instance.httpsCallable(name).call<Map<Object?, Object?>>(data);
    } on FirebaseFunctionsException catch (error) {
      throw RoutineException(switch (error.code) {
        'invalid-argument' || 'permission-denied' || 'not-found' || 'failed-precondition' || 'resource-exhausted' => error.message ?? 'We could not finish that request.',
        'unavailable' || 'deadline-exceeded' => 'We could not reach the server. Check your connection and try again.',
        _ => 'Something went wrong. Try again.',
      });
    }
  }
}

final profileRoutineRepositoryProvider = Provider<ProfileRoutineRepository>((ref) => ProfileRoutineRepository());

final profileRoutinesProvider = StreamProvider.family<List<ProfileRoutine>, String>((ref, profileId) => ref.watch(profileRoutineRepositoryProvider).watch(profileId));
