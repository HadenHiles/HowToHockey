import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../accounts/auth_service.dart';
import '../profiles/profile_repository.dart';
import '../settings/appearance_settings_controller.dart';

class TeamException implements Exception {
  const TeamException(this.message);
  final String message;
}

class Team {
  const Team({required this.id, required this.name, required this.memberCount, this.coachName = 'Coach', this.visibility = 'private', this.joinCode = '', this.memberProfileIds = const []});

  final String id;
  final String name;
  final String coachName;
  final int memberCount;
  final String visibility;
  final String joinCode;
  final List<String> memberProfileIds;

  factory Team.fromJson(String id, Map<String, dynamic> data) => Team(
    id: id,
    name: data['name'] as String,
    coachName: data['coachName'] as String? ?? 'Coach',
    memberCount: data['memberCount'] as int,
    visibility: data['visibility'] as String? ?? 'public',
    joinCode: data['joinCode'] as String? ?? '',
    memberProfileIds: (data['memberProfileIds'] as List?)?.cast<String>() ?? const [],
  );
}

class TeamPerson {
  const TeamPerson({required this.profileId, required this.displayName});
  final String profileId;
  final String displayName;
}

class TeamRequest {
  const TeamRequest({required this.teamId, required this.profileId, required this.teamName, required this.displayName, required this.status});
  final String teamId;
  final String profileId;
  final String teamName;
  final String displayName;
  final String status;

  factory TeamRequest.fromJson(Map<String, dynamic> data) => TeamRequest(
    teamId: data['teamId'] as String,
    profileId: data['profileId'] as String,
    teamName: data['teamName'] as String,
    displayName: data['displayName'] as String,
    status: data['status'] as String,
  );
}

class TeamInvitation {
  const TeamInvitation({required this.teamId, required this.name, required this.kind});
  final String teamId;
  final String name;
  final String kind;
}

String inviteCodeFrom(String input) {
  final value = input.trim();
  final uri = Uri.tryParse(value);
  return (uri?.queryParameters['code'] ?? value).replaceAll(RegExp(r'\s'), '').toUpperCase();
}

String teamInviteLink(String code) => Uri(scheme: 'howtohockey', host: 'app', path: '/join', queryParameters: {'code': code}).toString();

class TeamRepository {
  TeamRepository({CallFunction? call}) : _call = call ?? _callFirebase;
  final CallFunction _call;

  static Future<Map<String, dynamic>> _callFirebase(String name, Map<String, dynamic> data) async {
    final result = await FirebaseFunctions.instance.httpsCallable(name).call<Map<Object?, Object?>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  Stream<List<Team>> watchTeams(AuthState auth, {required bool coaching}) {
    final (field, value) = switch (auth) {
      SignedInAccount(:final uid) => (coaching ? 'coachUids' : 'memberOwnerUids', uid),
      KidDeviceSession(:final profileId) when !coaching => ('memberProfileIds', profileId),
      _ => ('', ''),
    };
    if (field.isEmpty) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('teams')
        .where(field, arrayContains: value)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) Team.fromJson(doc.id, doc.data())]..sort((a, b) => a.name.compareTo(b.name)));
  }

  Stream<List<Team>> discover(String prefix) {
    final search = prefix.trim().toLowerCase();
    if (search.isEmpty) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('teamDirectory')
        .orderBy('searchName')
        .startAt([search])
        .endAt(['$search\u{10ffff}'])
        .limit(20)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) Team.fromJson(doc.id, doc.data())]);
  }

  Stream<List<TeamPerson>> watchMembers(String teamId) => FirebaseFirestore.instance
      .collection('teams/$teamId/members')
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) TeamPerson(profileId: doc.id, displayName: doc.data()['displayName'] as String)]..sort((a, b) => a.displayName.compareTo(b.displayName)));

  Stream<List<TeamRequest>> watchCoachRequests(String teamId) => FirebaseFirestore.instance
      .collection('teams/$teamId/joinRequests')
      .where('status', isEqualTo: 'coachPending')
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) TeamRequest.fromJson(doc.data())]);

  Stream<List<TeamRequest>> watchParentRequests(String uid) =>
      FirebaseFirestore.instance.collection('users/$uid/teamRequests').snapshots().map((snapshot) => [for (final doc in snapshot.docs) TeamRequest.fromJson(doc.data())]);

  Future<Map<String, dynamic>> _run(String name, Map<String, dynamic> data) async {
    try {
      return await _call(name, data);
    } on FirebaseFunctionsException catch (error) {
      throw TeamException(switch (error.code) {
        'unauthenticated' => 'Sign in to continue.',
        'invalid-argument' || 'permission-denied' || 'not-found' || 'failed-precondition' || 'resource-exhausted' => error.message ?? 'We could not finish that request.',
        'unavailable' || 'deadline-exceeded' => 'We could not reach the server. Check your connection and try again.',
        _ => 'Something went wrong. Try again.',
      });
    }
  }

  Future<void> _mutate(String name, Map<String, dynamic> data, bool Function(Map<String, dynamic>) confirmed) async {
    if (!confirmed(await _run(name, data))) throw const TeamException('The server did not confirm that change. Try again.');
  }

  Future<void> create(String name) => _mutate('createTeam', {'name': name}, (data) => data['teamId'] is String && (data['teamId'] as String).isNotEmpty);
  Future<void> setVisibility(String teamId, bool isPublic) => _mutate('updateTeam', {'teamId': teamId, 'visibility': isPublic ? 'public' : 'private'}, (data) => data['updated'] == true);
  Future<String> createInvite(String teamId, {required bool coach}) async {
    final result = await _run('createTeamInvite', {'teamId': teamId, 'kind': coach ? 'coach' : 'player'});
    if (result['code'] case final String code) return code;
    throw const TeamException('The server did not return an invitation. Try again.');
  }

  Future<TeamInvitation> preview(String input) async {
    final code = inviteCodeFrom(input);
    if (!RegExp(r'^[A-F0-9]{16}$').hasMatch(code)) throw const TeamException('Enter the 16-character invitation code, or paste the invite link.');
    final result = await _run('previewTeamInvite', {'code': code});
    if (result case {'teamId': final String id, 'name': final String name, 'kind': final String kind} when kind == 'coach' || kind == 'player') {
      return TeamInvitation(teamId: id, name: name, kind: kind);
    }
    throw const TeamException('The server did not return a valid invitation. Try again.');
  }

  Future<String> join({required String profileId, String? code, String? teamId}) async {
    final result = await _run('joinTeam', {'profileId': profileId, if (code != null) 'code': inviteCodeFrom(code), 'teamId': ?teamId});
    if (result['status'] case final String status when const ['joined', 'parentPending', 'coachPending'].contains(status)) return status;
    throw const TeamException('The server did not confirm your request. Try again.');
  }

  Future<void> acceptCoach(String code) => _mutate('acceptCoachInvite', {'code': inviteCodeFrom(code)}, (data) => data['teamId'] is String && (data['teamId'] as String).isNotEmpty);
  Future<void> review(TeamRequest request, bool approve) => _mutate('reviewTeamRequest', {
    'teamId': request.teamId,
    'profileId': request.profileId,
    'approve': approve,
  }, (data) => (approve ? const ['joined', 'coachPending'] : const ['declined']).contains(data['status']));
  Future<void> remove(String teamId, String profileId) => _mutate('removeTeamMember', {'teamId': teamId, 'profileId': profileId}, (data) => data['removed'] == true);
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) => TeamRepository());

class PendingTeamInvite extends Notifier<String?> {
  static const _key = 'pendingTeamInvite';
  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);
  void remember(String code) {
    state = code;
    _save(ref.read(sharedPreferencesProvider).setString(_key, code));
  }

  void clear() {
    state = null;
    _save(ref.read(sharedPreferencesProvider).remove(_key));
  }

  void _save(Future<bool> write) {
    unawaited(
      write.then((saved) {
        if (!saved) FlutterError.reportError(FlutterErrorDetails(exception: StateError('Could not save the pending team invitation.'), library: 'team invitations'));
      }),
    );
  }
}

final pendingTeamInviteProvider = NotifierProvider<PendingTeamInvite, String?>(PendingTeamInvite.new);
String? pendingTeamInviteRoute(WidgetRef ref) {
  final code = ref.read(pendingTeamInviteProvider);
  return code == null ? null : Uri(path: '/join', queryParameters: {'code': code}).toString();
}

final coachedTeamsProvider = StreamProvider<List<Team>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  return auth == null ? Stream.value(const []) : ref.watch(teamRepositoryProvider).watchTeams(auth, coaching: true);
});
final memberTeamsProvider = StreamProvider<List<Team>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  return auth == null ? Stream.value(const []) : ref.watch(teamRepositoryProvider).watchTeams(auth, coaching: false);
});
final teamMembersProvider = StreamProvider.family<List<TeamPerson>, String>((ref, id) => ref.watch(teamRepositoryProvider).watchMembers(id));
final coachTeamRequestsProvider = StreamProvider.family<List<TeamRequest>, String>((ref, id) => ref.watch(teamRepositoryProvider).watchCoachRequests(id));
final parentTeamRequestsProvider = StreamProvider<List<TeamRequest>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  return auth is SignedInAccount ? ref.watch(teamRepositoryProvider).watchParentRequests(auth.uid) : Stream.value(const []);
});
final teamDiscoveryProvider = StreamProvider.family<List<Team>, String>((ref, prefix) => ref.watch(teamRepositoryProvider).discover(prefix));

class SelectedCoachTeam extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authStateProvider.select((auth) => auth.value == null ? null : identityOf(auth.value!)));
    return null;
  }

  void choose(String id) => state = id;
}

final selectedCoachTeamIdProvider = NotifierProvider<SelectedCoachTeam, String?>(SelectedCoachTeam.new);
final selectedCoachTeamProvider = Provider<Team?>((ref) {
  final teams = ref.watch(coachedTeamsProvider).asData?.value ?? const [];
  final selected = ref.watch(selectedCoachTeamIdProvider);
  return teams.where((team) => team.id == selected).firstOrNull ?? teams.firstOrNull;
});
