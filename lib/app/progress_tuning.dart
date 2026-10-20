import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/progress/progress_stats.dart';
import '../features/settings/appearance_settings_controller.dart';

/// Remote Config parameter names. The same ones are read by the Cloud Function that counts workouts.
abstract final class TuningKeys {
  static const maxShotsPerSecond = 'progress_max_shots_per_second';
  static const maxSessionSeconds = 'progress_max_session_seconds';
  static const maxDaySeconds = 'progress_max_day_seconds';
  static const levelOneSeconds = 'progress_level_one_seconds';
  static const levelGrowth = 'progress_level_growth';
}

/// Where the tuning numbers come from. A seam so tests don't need Firebase.
abstract class TuningSource {
  Future<Map<String, num>> fetch();
}

class RemoteConfigTuningSource implements TuningSource {
  @override
  Future<Map<String, num>> fetch() async {
    final config = FirebaseRemoteConfig.instance;
    await config.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(seconds: 10), minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 12)));
    await config.fetchAndActivate();
    const keys = [TuningKeys.maxShotsPerSecond, TuningKeys.maxSessionSeconds, TuningKeys.maxDaySeconds, TuningKeys.levelOneSeconds, TuningKeys.levelGrowth];
    return {
      for (final key in keys)
        if (config.getValue(key).source == ValueSource.valueRemote) key: config.getDouble(key),
    };
  }
}

final tuningSourceProvider = Provider<TuningSource>((ref) => RemoteConfigTuningSource());

/// The rules' tunable numbers: what was last fetched (remembered on the device), or the built-in defaults.
class ProgressTuningNotifier extends Notifier<ProgressTuning> {
  static const storageKey = 'progressTuning';

  @override
  ProgressTuning build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    Future.microtask(refresh);
    if (stored == null) return ProgressTuning.defaults;
    try {
      return _from((jsonDecode(stored) as Map).cast<String, num>());
    } on Object {
      return ProgressTuning.defaults;
    }
  }

  ProgressTuning _from(Map<String, num> values) => ProgressTuning.fromValues(
    maxShotsPerSecond: values[TuningKeys.maxShotsPerSecond],
    maxSessionSeconds: values[TuningKeys.maxSessionSeconds],
    maxDaySeconds: values[TuningKeys.maxDaySeconds],
    levelOneSeconds: values[TuningKeys.levelOneSeconds],
    levelGrowth: values[TuningKeys.levelGrowth],
  );

  /// Asks Remote Config for fresh numbers. Offline or not set up, the current ones stay.
  Future<void> refresh() async {
    try {
      final values = await ref.read(tuningSourceProvider).fetch();
      if (values.isEmpty) return;
      final next = _from(values);
      if (next == state) return;
      state = next;
      await ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(values));
    } on Object catch (error) {
      debugPrint('Using the saved progress settings: $error');
    }
  }
}

final progressTuningProvider = NotifierProvider<ProgressTuningNotifier, ProgressTuning>(ProgressTuningNotifier.new);
