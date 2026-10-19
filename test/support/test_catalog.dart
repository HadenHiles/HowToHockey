import 'dart:async';

import 'package:clock/clock.dart';

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/display_name.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/session/rest_notifications.dart';
import 'package:how_to_hockey/features/session/session_cues.dart';

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

  @override
  Stream<List<PlayerProfile>> watchChildProfiles(String ownerUid) async* {
    yield List.of(children);
    yield* _childChanges.stream;
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
    children.add(PlayerProfile(id: id, ownerUid: 'u', displayName: displayName, birthYear: birthYear, isChild: true));
    _childChanges.add(List.of(children));
    return id;
  }
}

final testAuth = FakeAuthService();
final testProfiles = FakeProfileRepository();
final testAuthOverride = authServiceProvider.overrideWithValue(testAuth);
final testProfilesOverride = profileRepositoryProvider.overrideWithValue(testProfiles);
