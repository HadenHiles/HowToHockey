import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';
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
