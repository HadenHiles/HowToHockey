import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/firebase_options.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const useDeviceCheck = bool.fromEnvironment('VERIFY_DEVICE_CHECK');

  testWidgets('exchanges real attestation for a fresh App Check token', (tester) async {
    expect(kDebugMode, isFalse, reason: 'Run this test in profile mode.');
    expect(defaultTargetPlatform, isIn([TargetPlatform.android, TargetPlatform.iOS]), reason: 'Production attestation requires a physical mobile device.');

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAppCheck.instance.activate(providerAndroid: const AndroidPlayIntegrityProvider(), providerApple: useDeviceCheck ? const AppleDeviceCheckProvider() : const AppleAppAttestProvider());

    final token = await FirebaseAppCheck.instance.getToken(true);
    expect(token, isNotNull, reason: 'Firebase must issue an App Check token.');
    expect(token, isNotEmpty, reason: 'An empty token is not verification.');
  });
}
