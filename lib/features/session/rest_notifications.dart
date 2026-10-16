import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../settings/appearance_settings_controller.dart';

/// A reminder that a rest has ended, for players whose phone is locked or in another app.
abstract class RestNotifications {
  /// Asks for notification permission the first time it is needed and never again after that.
  Future<void> ensurePermission();

  Future<void> scheduleRestOver(DateTime at, {required String title, required String body});

  Future<void> cancel();
}

/// Whether rest reminders are on. Saved on the device; on by default.
class RestRemindersEnabled extends Notifier<bool> {
  static const storageKey = 'restRemindersEnabled';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(storageKey) ?? true;

  Future<void> set(bool enabled) async {
    if (!await ref.read(sharedPreferencesProvider).setBool(storageKey, enabled)) {
      throw StateError('Couldn\'t save the rest reminders setting.');
    }
    state = enabled;
  }
}

final restRemindersEnabledProvider = NotifierProvider<RestRemindersEnabled, bool>(RestRemindersEnabled.new);

class DeviceRestNotifications implements RestNotifications {
  DeviceRestNotifications({required this.preferences, FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Saved so the system prompt is shown at most once from the app.
  static const askedKey = 'restNotificationsPermissionAsked';
  static const _notificationId = 7001;
  static const _channel = AndroidNotificationDetails(
    'rest_over',
    'Rest timer',
    channelDescription: 'Lets you know when a rest between sets is over.',
    importance: Importance.high,
    priority: Priority.high,
  );

  final SharedPreferences preferences;
  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;

  Future<void> _init() => _initialized ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_rest'),
      iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    ),
  );

  @override
  Future<void> ensurePermission() async {
    if (preferences.getBool(askedKey) == true) return;
    await _init();
    await preferences.setBool(askedKey, true);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true);
  }

  @override
  Future<void> scheduleRestOver(DateTime at, {required String title, required String body}) async {
    await _init();
    // An absolute moment, so no time zone database is needed.
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _notificationId);
  }
}

final restNotificationsProvider = Provider<RestNotifications>((ref) => DeviceRestNotifications(preferences: ref.read(sharedPreferencesProvider)));

/// Reports and swallows reminder failures: a missing reminder must never interrupt a workout.
void reportReminderError(Object error, StackTrace stack) => FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'rest reminders'));
