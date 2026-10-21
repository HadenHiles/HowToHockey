import 'dart:async';

import 'package:flutter/material.dart';

import 'package:clock/clock.dart';

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:how_to_hockey/features/commerce/entitlements.dart';
import 'package:how_to_hockey/features/commerce/purchases_service.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/display_name.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';
import 'package:how_to_hockey/features/session/rest_notifications.dart';
import 'package:how_to_hockey/features/sessions/session_repository.dart';
import 'package:how_to_hockey/features/session/session_cues.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';

/// Widget tests cannot finish real asset I/O under fake time, so they read the
/// same catalog file from disk and provide it directly.
final testCatalogOverride = drillCatalogProvider.overrideWithValue(AsyncData(parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())));

class _NoMedia implements DrillMediaSource {
  @override
  Future<DrillMedia?> load(String videoPath) async => null;

  @override
  Future<void> prefetch(String videoPath) async {}
}

/// Keeps widget tests off Firebase Storage; drills simply show their illustrated placeholder.
final testMediaOverride = drillMediaSourceProvider.overrideWithValue(_NoMedia());

/// Records which cues fired so tests never touch real audio or haptics.
class RecordingCues implements SessionCues {
  final events = <String>[];

  @override
  void leadInTick(int secondsLeft) => events.add('tick$secondsLeft');

  @override
  void setStarted() => events.add('start');

  @override
  void setFinished() => events.add('stop');

  @override
  void restFinished() => events.add('rest');
}

final testCues = RecordingCues();
final testCuesOverride = sessionCuesProvider.overrideWithValue(testCues);

/// Records reminder calls so tests never touch real notifications.
class RecordingReminders implements RestNotifications {
  final events = <String>[];
  DateTime? lastScheduledAt;
  String? lastBody;
  var permissionRequests = 0;

  @override
  Future<void> ensurePermission() async {
    permissionRequests++;
    events.add('permission');
  }

  @override
  Future<void> scheduleRestOver(DateTime at, {required String title, required String body}) async {
    lastScheduledAt = at;
    lastBody = body;
    events.add('schedule');
  }

  @override
  Future<void> cancel() async => events.add('cancel');
}

final testReminders = RecordingReminders();
final testRemindersOverride = restNotificationsProvider.overrideWithValue(testReminders);

/// A stand-in for sign-in that records calls and can be told to fail.
class FakeAuthService implements AuthService {
  FakeAuthService([AuthState initial = const GuestSession('guest-1')]) : _state = initial;

  AuthState _state;
  final _controller = StreamController<AuthState>.broadcast();
  final calls = <String>[];
  AuthProblem? failWith;

  void _set(AuthState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  AuthState get current => _state;

  @override
  Stream<AuthState> get changes => _controller.stream;

  @override
  Future<void> createEmailAccount({required String email, required String password}) async {
    calls.add('create:$email');
    if (failWith != null) throw failWith!;
    _set(SignedInAccount(uid: current is GuestSession ? (current as GuestSession).uid : 'new-user', email: email.trim(), emailVerified: false));
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    calls.add('signin:$email');
    if (failWith != null) throw failWith!;
    _set(SignedInAccount(uid: 'existing-user', email: email.trim(), emailVerified: true));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    if (failWith != null) throw failWith!;
  }

  /// Changes who is signed in without recording a call, for setting a test up.
  void signOutSilently(AuthState state) => _set(state);

  void signInSilently(AuthState state) => _set(state);

  @override
  Future<void> signInWithKidToken(String token) async {
    calls.add('kid:$token');
    if (failWith != null) throw failWith!;
    _set(KidDeviceSession(token.replaceFirst('token-', '')));
  }

  @override
  Future<void> signOut() async {
    calls.add('signout');
    _set(const GuestSession('guest-2'));
  }
}

/// Records profile calls and can be told to fail.
class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository() : super(call: (_, _) async => {'profileId': 'p'});

  final calls = <String>[];
  ProfileException? failWith;
  final children = <PlayerProfile>[];
  final _childChanges = StreamController<List<PlayerProfile>>.broadcast();

  PlayerProfile? own;

  @override
  Stream<PlayerProfile?> watchProfile(String profileId) async* {
    yield profileId == own?.id ? own : children.where((p) => p.id == profileId).firstOrNull;
  }

  @override
  Stream<List<PlayerProfile>> watchChildProfiles(String ownerUid) async* {
    yield List.of(children);
    yield* _childChanges.stream;
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('delete-account');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<PairingCode> createPairingCode(String profileId) async {
    calls.add('pair:$profileId');
    if (failWith != null) throw failWith!;
    return PairingCode(code: '12345678', expiresAt: clock.now().add(const Duration(minutes: 10)));
  }

  @override
  Future<KidPairing> redeemPairingCode(String code) async {
    calls.add('redeem:$code');
    if (failWith != null) throw failWith!;
    if (code.replaceAll(' ', '') != '12345678') throw const ProfileException('That code didn\'t work. Ask your parent for a new one.');
    return const KidPairing(token: 'token-child-1', profileId: 'child-1', displayName: 'Avery H.');
  }

  @override
  Future<String> createOwnProfile({required String displayName, required int birthYear, required DateTime now}) async {
    calls.add('own:$displayName:$birthYear');
    if (failWith != null) throw failWith!;
    return 'profile-1';
  }

  @override
  Future<String> createChildProfile({required String displayName, required int birthYear, required DateTime now}) async {
    displayName = normalizeDisplayName(displayName)!;
    calls.add('child:$displayName:$birthYear');
    if (failWith != null) throw failWith!;
    final id = 'child-${children.length + 1}';
    children.add(PlayerProfile(id: id, ownerUid: 'existing-user', displayName: displayName, birthYear: birthYear, isChild: true));
    _childChanges.add(List.of(children));
    return id;
  }
}

final testAuth = FakeAuthService();
final testProfiles = FakeProfileRepository();
final testAuthOverride = authServiceProvider.overrideWithValue(testAuth);
final testProfilesOverride = profileRepositoryProvider.overrideWithValue(testProfiles);

class FakeTeamRepository extends TeamRepository {
  FakeTeamRepository() : super(call: (_, _) async => {});
  final calls = <String>[];
  List<Team> teams = const [];
  List<TeamPerson> members = const [];
  List<TeamRequest> requests = const [];
  TeamException? failWith;
  String joinStatus = 'joined';
  String inviteKind = 'player';

  void check() {
    if (failWith != null) throw failWith!;
  }

  @override
  Stream<List<Team>> watchTeams(AuthState auth, {required bool coaching}) => Stream.value(teams);
  @override
  Stream<List<Team>> discover(String prefix) => Stream.value(prefix.isEmpty ? [] : teams);
  @override
  Stream<List<TeamPerson>> watchMembers(String teamId) => Stream.value(members);
  @override
  Stream<List<TeamRequest>> watchCoachRequests(String teamId) => Stream.value(requests.where((r) => r.status == 'coachPending').toList());
  @override
  Stream<List<TeamRequest>> watchParentRequests(String uid) => Stream.value(requests);
  @override
  Future<void> create(String name) async {
    check();
    calls.add('create:$name');
  }

  @override
  Future<void> setVisibility(String teamId, bool isPublic) async {
    check();
    calls.add('public:$teamId:$isPublic');
  }

  @override
  Future<String> createInvite(String teamId, {required bool coach}) async {
    check();
    calls.add('invite:$teamId:$coach');
    return 'ABCDEF0123456789';
  }

  @override
  Future<TeamInvitation> preview(String input) async {
    check();
    calls.add('preview:${inviteCodeFrom(input)}');
    return TeamInvitation(teamId: 't1', name: 'North Stars', kind: inviteKind);
  }

  @override
  Future<String> join({required String profileId, String? code, String? teamId}) async {
    check();
    calls.add('join:$profileId');
    return joinStatus;
  }

  @override
  Future<void> acceptCoach(String code) async {
    check();
    calls.add('coach:$code');
  }

  @override
  Future<void> review(TeamRequest request, bool approve) async {
    check();
    calls.add('review:${request.profileId}:$approve');
  }

  @override
  Future<void> remove(String teamId, String profileId) async {
    check();
    calls.add('remove:$teamId:$profileId');
  }
}

final testTeams = FakeTeamRepository();
final testTeamsOverride = teamRepositoryProvider.overrideWithValue(testTeams);

/// Keeps widget tests off Firestore: uploads are recorded, and stats come from whatever a test puts in [stats].
class FakeSessionRepository extends SessionRepository {
  final uploads = <(String, String)>[];
  final pendingUploads = <String>[];
  final pending = <String, List<PendingWorkout>>{};
  final pendingDrills = <PendingDrill>[];
  final reviewed = <String>[];
  final stats = <String, LifetimeStats>{};
  final _changes = StreamController<String>.broadcast();
  Object? failWith;

  void setStats(String profileId, LifetimeStats value) {
    stats[profileId] = value;
    _changes.add(profileId);
  }

  @override
  Future<void> upload(String profileId, SessionUpload upload) async {
    if (failWith != null) throw failWith!;
    uploads.add((profileId, upload.record.id));
    if (upload.pending) pendingUploads.add(upload.record.id);
  }

  void setPending(String profileId, List<PendingWorkout> workouts) {
    pending[profileId] = workouts;
    _changes.add('pending:$profileId');
  }

  @override
  Stream<List<PendingWorkout>> watchPending(String profileId) async* {
    yield pending[profileId] ?? const [];
    await for (final changed in _changes.stream) {
      if (changed == 'pending:$profileId') yield pending[profileId] ?? const [];
    }
  }

  @override
  Future<List<PendingDrill>> loadPendingDrills(String profileId, String sessionId) async => pendingDrills;

  @override
  Future<void> confirm(PendingWorkout workout) async {
    reviewed.add('confirm:${workout.id}');
    setPending(workout.profileId, [
      for (final w in pending[workout.profileId] ?? const <PendingWorkout>[])
        if (w.id != workout.id) w,
    ]);
  }

  @override
  Future<void> discard(PendingWorkout workout) async {
    reviewed.add('discard:${workout.id}');
    setPending(workout.profileId, [
      for (final w in pending[workout.profileId] ?? const <PendingWorkout>[])
        if (w.id != workout.id) w,
    ]);
  }

  @override
  Stream<LifetimeStats?> watchStats(String profileId) async* {
    yield stats[profileId];
    await for (final changed in _changes.stream) {
      if (changed == profileId) yield stats[profileId];
    }
  }
}

final testSessions = FakeSessionRepository();
final testSessionsOverride = sessionRepositoryProvider.overrideWithValue(testSessions);

/// A store that sells the four plans at the roadmap prices and remembers what was bought.
class FakePurchases implements PurchasesService {
  FakePurchases({this.available = true});

  @override
  final bool available;
  final _controller = StreamController<Set<String>>.broadcast();
  final identified = <String?>[];
  final bought = <String>[];
  Set<String> active = {};
  Set<String> restorable = {};
  PurchaseFailure? failWith;

  @override
  Stream<Set<String>> get entitlements => _controller.stream;

  void setActive(Set<String> next) {
    active = next;
    _controller.add(next);
  }

  @override
  Future<void> identify(String? uid) async => identified.add(uid);

  /// Stands in for RevenueCat's paywall: shows which offering was asked for and a button that "buys" it.
  @override
  Future<Widget?> paywall(String offeringId, {required VoidCallback onFinished}) async {
    if (!available) return null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Paywall for $offeringId'),
        TextButton(
          onPressed: () {
            bought.add(offeringId);
            setActive(offeringId == 'coach' ? {playerProEntitlement, coachProEntitlement} : {playerProEntitlement});
            onFinished();
          },
          child: Text('Buy $offeringId'),
        ),
      ],
    );
  }

  @override
  Future<Set<String>> restore() async {
    if (failWith != null) throw failWith!;
    setActive({...active, ...restorable});
    return restorable;
  }

  @override
  Future<Uri> manageUri() async => defaultManageUri();
}

final testPurchases = FakePurchases();
final testPurchasesOverride = purchasesProvider.overrideWithValue(testPurchases);
