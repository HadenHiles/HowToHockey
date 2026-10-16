import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/appearance_settings_controller.dart';

/// Short sound-and-haptic cues during a workout.
abstract class SessionCues {
  void leadInTick(int secondsLeft);
  void setStarted();
  void setFinished();
  void restFinished();
}

/// Whether workout sounds and haptics are on. Saved on the device; on by default.
class WorkoutCuesEnabled extends Notifier<bool> {
  static const storageKey = 'workoutCuesEnabled';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(storageKey) ?? true;

  Future<void> set(bool enabled) async {
    if (!await ref.read(sharedPreferencesProvider).setBool(storageKey, enabled)) {
      throw StateError('Couldn\'t save the workout sounds setting.');
    }
    state = enabled;
  }
}

final workoutCuesEnabledProvider = NotifierProvider<WorkoutCuesEnabled, bool>(WorkoutCuesEnabled.new);

/// Audio session for short cues: iOS `ambient` mixes with the player's music and follows the
/// silent switch; Android takes no audio focus so music is never paused or ducked.
AudioContext workoutAudioContext() => AudioContext(
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none, usageType: AndroidUsageType.assistanceSonification, contentType: AndroidContentType.sonification, stayAwake: false),
);

/// Plays the bundled tones alongside whatever music is already playing (no ducking or pausing),
/// stays quiet when the phone's silent switch is on, and adds matching haptics.
class DeviceSessionCues implements SessionCues {
  DeviceSessionCues({required this.enabled}) {
    unawaited(AudioPlayer.global.setAudioContext(workoutAudioContext()).catchError(_report));
  }

  final bool Function() enabled;
  final _players = <String, AudioPlayer>{};

  void _report(Object error, [StackTrace? stack]) => FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'workout cues'));

  void _play(String asset, Future<void> Function() haptic) {
    if (!enabled()) return;
    // The normal player mode reports completion. Low-latency mode never does, which keeps a frame callback running.
    final player = _players.putIfAbsent(asset, AudioPlayer.new);
    unawaited(player.play(AssetSource(asset)).catchError(_report));
    unawaited(haptic().catchError(_report));
  }

  @override
  void leadInTick(int secondsLeft) => _play('audio/lead_in_tick.wav', HapticFeedback.selectionClick);

  @override
  void setStarted() => _play('audio/set_start.wav', HapticFeedback.heavyImpact);

  @override
  void setFinished() => _play('audio/set_stop.wav', () async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await HapticFeedback.heavyImpact();
  });

  @override
  void restFinished() => _play('audio/rest_end.wav', () async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 190));
    await HapticFeedback.mediumImpact();
  });

  void dispose() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
  }
}

final sessionCuesProvider = Provider<SessionCues>((ref) {
  final cues = DeviceSessionCues(enabled: () => ref.read(workoutCuesEnabledProvider));
  ref.onDispose(cues.dispose);
  return cues;
});
