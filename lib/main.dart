import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/hockey_app.dart';
import 'features/settings/appearance_settings_controller.dart';
import 'firebase_options.dart';

const _useFirebaseEmulators = bool.fromEnvironment('USE_EMULATORS');
const _configuredEmulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
const _verifyAppCheck = bool.fromEnvironment('VERIFY_APP_CHECK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final interLicense = await rootBundle.loadString('assets/fonts/OFL.txt');
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], interLicense);
  });
  final preferences = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final useDebugProviders = _useFirebaseEmulators || kDebugMode;
  final collectTelemetry = !_useFirebaseEmulators && !kDebugMode;
  final androidProvider = useDebugProviders ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider();
  final appleProvider = useDebugProviders ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider();

  await FirebaseAppCheck.instance.activate(providerAndroid: androidProvider, providerApple: appleProvider);
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(collectTelemetry);
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(collectTelemetry);

  FlutterError.onError = crashlytics.recordFlutterFatalError;
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  if (_verifyAppCheck) {
    if (useDebugProviders) {
      throw StateError(
        'App Check verification requires a profile/release build without '
        'Firebase emulators.',
      );
    }
    final token = await FirebaseAppCheck.instance.getToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not issue a valid App Check token.');
    }
    debugPrint('App Check verification passed using production attestation.');
  }

  if (_useFirebaseEmulators) {
    final emulatorHost = _configuredEmulatorHost.isNotEmpty
        ? _configuredEmulatorHost
        : defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

    FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
    FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
  }

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)], child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HockeyApp();
  }
}
