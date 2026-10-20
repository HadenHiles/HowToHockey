import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/progress_tuning.dart';
import 'package:how_to_hockey/features/progress/progress_stats.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTuningSource implements TuningSource {
  FakeTuningSource(this.values);

  Map<String, num> values;
  Object? failWith;
  var fetches = 0;

  @override
  Future<Map<String, num>> fetch() async {
    fetches++;
    if (failWith != null) throw failWith!;
    return values;
  }
}

Future<ProviderContainer> open(FakeTuningSource source, [Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues(saved);
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()), tuningSourceProvider.overrideWithValue(source)]);
  addTearDown(container.dispose);
  return container;
}

Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('starts on the defaults, then takes what Remote Config says and remembers it', () async {
    final source = FakeTuningSource({TuningKeys.maxDaySeconds: 7200, TuningKeys.levelGrowth: 1.5});
    final container = await open(source);
    expect(container.read(progressTuningProvider), ProgressTuning.defaults);
    await settle();
    expect(source.fetches, 1);
    final tuned = container.read(progressTuningProvider);
    expect(tuned.maxDaySeconds, 7200);
    expect(tuned.levelGrowth, 1.5);
    expect(tuned.maxSessionSeconds, ProgressTuning.defaults.maxSessionSeconds, reason: 'anything not set keeps its default');

    final restarted = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()), tuningSourceProvider.overrideWithValue(FakeTuningSource({}))]);
    addTearDown(restarted.dispose);
    expect(restarted.read(progressTuningProvider), tuned, reason: 'remembered for the next start, even offline');
  });

  test('offline, nothing set up, or nonsense values leave things as they were', () async {
    final source = FakeTuningSource({})..failWith = Exception('offline');
    final container = await open(source);
    container.read(progressTuningProvider);
    await settle();
    expect(container.read(progressTuningProvider), ProgressTuning.defaults);

    source
      ..failWith = null
      ..values = {TuningKeys.maxSessionSeconds: -1, TuningKeys.levelGrowth: 99};
    await container.read(progressTuningProvider.notifier).refresh();
    expect(container.read(progressTuningProvider), ProgressTuning.defaults);

    source.values = {};
    await container.read(progressTuningProvider.notifier).refresh();
    expect(container.read(progressTuningProvider), ProgressTuning.defaults);
  });

  test('damaged saved values fall back to the defaults', () async {
    final container = await open(FakeTuningSource({}), {ProgressTuningNotifier.storageKey: 'not json'});
    expect(container.read(progressTuningProvider), ProgressTuning.defaults);
  });
}
