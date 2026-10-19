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

  /// One profile, or null if it doesn't exist (yet) or can't be read.
  Stream<PlayerProfile?> watchProfile(String profileId) =>
      FirebaseFirestore.instance.collection('profiles').doc(profileId).snapshots().map((doc) => doc.exists ? PlayerProfile.fromJson({...doc.data()!, 'id': doc.id}) : null).handleError((Object _) {});

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
    final result = await _run(function, {'displayName': displayName, 'birthYear': birthYear});
    final id = result['profileId'];
    if (id is! String) throw const ProfileException('Something went wrong. Try again.');
    return id;
  }

  /// A parent asks for a short-lived code that pairs a kid's device to one child profile.
  Future<PairingCode> createPairingCode(String profileId) async {
    final result = await _run('createPairingCode', {'profileId': profileId});
    final code = result['code'];
    final expires = result['expiresAtMillis'];
    if (code is! String || expires is! int) throw const ProfileException('Something went wrong. Try again.');
    return PairingCode(code: code, expiresAt: DateTime.fromMillisecondsSinceEpoch(expires));
  }

  /// A kid's device trades a code for a sign-in token that is locked to one profile.
  Future<KidPairing> redeemPairingCode(String code) async {
    final digits = code.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{8}$').hasMatch(digits)) throw const ProfileException('Enter the 8 digits from your parent\'s phone.');
    final result = await _run('redeemPairingCode', {'code': digits});
    final token = result['token'];
    final profileId = result['profileId'];
    final name = result['displayName'];
    if (token is! String || profileId is! String || name is! String) throw const ProfileException('Something went wrong. Try again.');
    return KidPairing(token: token, profileId: profileId, displayName: name);
  }

  Future<Map<String, dynamic>> _run(String function, Map<String, dynamic> data) async {
    try {
      return await _call(function, data);
    } on FirebaseFunctionsException catch (error) {
      throw ProfileException(switch (error.code) {
        'unauthenticated' => 'Sign in to continue.',
        'failed-precondition' || 'invalid-argument' || 'already-exists' || 'not-found' || 'permission-denied' => error.message ?? 'We couldn\'t finish that.',
        'unavailable' || 'deadline-exceeded' => 'We couldn\'t reach the server. Check your connection and try again.',
        _ => 'Something went wrong. Try again.',
      });
    }
  }
}

class PairingCode {
  const PairingCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  /// Shown as `1234 5678` so it is easy to read out loud.
  String get spaced => '${code.substring(0, 4)} ${code.substring(4)}';
}

class KidPairing {
  const KidPairing({required this.token, required this.profileId, required this.displayName});

  final String token;
  final String profileId;
  final String displayName;
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

/// The signed-in account's child profiles. Empty for guests and signed-out visitors.
final childProfilesProvider = StreamProvider<List<PlayerProfile>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth is! SignedInAccount) return Stream.value(const <PlayerProfile>[]);
  return ref.watch(profileRepositoryProvider).watchChildProfiles(auth.uid);
});
