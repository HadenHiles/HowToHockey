import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('SharedPreferences has not been initialized.'),
);

enum AppAppearance {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppAppearance(this.label);

  final String label;

  ThemeMode get themeMode => switch (this) {
    AppAppearance.system => ThemeMode.system,
    AppAppearance.light => ThemeMode.light,
    AppAppearance.dark => ThemeMode.dark,
  };

  static AppAppearance fromStoredValue(String value) {
    return AppAppearance.values.firstWhere(
      (appearance) => appearance.name == value,
      orElse: () => throw FormatException(
        'Unrecognized saved appearance preference: $value',
      ),
    );
  }
}

class AppearanceSettingsNotifier extends Notifier<AppAppearance> {
  static const String preferenceKey = 'appearance';

  @override
  AppAppearance build() {
    return _readSavedAppearance(ref.read(sharedPreferencesProvider));
  }

  static AppAppearance _readSavedAppearance(SharedPreferences preferences) {
    final value = preferences.getString(preferenceKey);
    return value == null
        ? AppAppearance.system
        : AppAppearance.fromStoredValue(value);
  }

  Future<void> setAppearance(AppAppearance appearance) async {
    if (appearance == state) return;

    final preferences = ref.read(sharedPreferencesProvider);
    final saved = await preferences.setString(preferenceKey, appearance.name);
    if (!saved) {
      throw StateError('Failed to save the appearance preference.');
    }

    state = appearance;
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceSettingsNotifier, AppAppearance>(
      AppearanceSettingsNotifier.new,
    );
