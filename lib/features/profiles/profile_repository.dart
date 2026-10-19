import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/auth_service.dart';
import 'display_name.dart';
import 'player_profile.dart';

/// Something went wrong creating a profile, with wording that is safe to show the player or parent.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef CallFunction = Future<Map<String, dynamic>> Function(String name, Map<String, dynamic> data);

/// Creates profiles through Cloud Functions, which check names and enforce the child-profile cap.
class ProfileRepository {
  ProfileRepository({CallFunction? call}) : _call = call ?? _callFirebase;

  final CallFunction _call;

  static Future<Map<String, dynamic>> _callFirebase(String name, Map<String, dynamic> data) async {
    final result = await FirebaseFunctions.instance.httpsCallable(name).call<Map<Object?, Object?>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// The child profiles an account manages, newest last. Updates as profiles are added.
  Stream<List<PlayerProfile>> watchChildProfiles(String ownerUid) => FirebaseFirestore.instance
      .collection('profiles')
      .where('ownerUid', isEqualTo: ownerUid)
      .where('isChild', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) PlayerProfile.fromJson({...doc.data(), 'id': doc.id}),
        ]..sort((a, b) => a.displayName.compareTo(b.displayName)),
      );

  /// A parent adds a child. Returns the new profile's id.
  Future<String> createChildProfile({required String displayName, required int birthYear, required DateTime now}) async {
    final name = normalizeDisplayName(displayName);
    if (name == null) throw const ProfileException('Use a first name and last initial, like "Jamie H."');
    if (!canBeChildProfile(birthYear, now)) throw const ProfileException('Child profiles are for players 17 and under.');
    return _create('createChildProfile', name, birthYear);
  }

  /// An adult sets up their own player profile. Returns the profile id.
  Future<String> createOwnProfile({required String displayName, required int birthYear, required DateTime now}) async {
    final name = normalizeDisplayName(displayName);
    if (name == null) throw const ProfileException('Use a first name and last initial, like "Jamie H."');
    if (!canHaveOwnAccount(birthYear, now)) throw const ProfileException('Players under 13 can\'t have their own account. A parent can set up a child profile.');
    return _create('createOwnProfile', name, birthYear);
  }

  Future<String> _create(String function, String displayName, int birthYear) async {
    try {
      final result = await _call(function, {'displayName': displayName, 'birthYear': birthYear});
      final id = result['profileId'];
      if (id is! String) throw const ProfileException('Something went wrong. Try again.');
      return id;
    } on FirebaseFunctionsException catch (error) {
      throw ProfileException(switch (error.code) {
        'unauthenticated' => 'Sign in to continue.',
        'failed-precondition' || 'invalid-argument' || 'already-exists' => error.message ?? 'We couldn\'t save that profile.',
        'unavailable' || 'deadline-exceeded' => 'We couldn\'t reach the server. Check your connection and try again.',
        _ => 'Something went wrong. Try again.',
      });
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

/// The signed-in account's child profiles. Empty for guests and signed-out visitors.
final childProfilesProvider = StreamProvider<List<PlayerProfile>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth is! SignedInAccount) return Stream.value(const <PlayerProfile>[]);
  return ref.watch(profileRepositoryProvider).watchChildProfiles(auth.uid);
});
