import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat entitlement identifiers. Coach Pro products also grant `player_pro`.
const playerProEntitlement = 'player_pro';
const coachProEntitlement = 'coach_pro';

/// The public SDK keys are meant to ship inside the app; they can only read offerings and make purchases.
const revenueCatAppleKey = 'appl_OeNEuTtPsolnKkVomQlwOKdSGwT';
const revenueCatGoogleKey = 'goog_XbMcpcfabIHJWMJKboTFfoCIiGg';

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PurchasesService {
  /// False when this build can't sell anything, for example on a platform without store keys.
  bool get available;

  /// The entitlement identifiers that are active for the identified account right now.
  Stream<Set<String>> get entitlements;

  /// Ties purchases to a signed-in account. Null means nobody who can buy is signed in.
  Future<void> identify(String? uid);

  /// RevenueCat's paywall for an offering (`player` or `coach`). Its wording, plans and look are edited in the
  /// RevenueCat dashboard, so they change without an app release. Null when there is nothing to show.
  Future<Widget?> paywall(String offeringId, {required VoidCallback onFinished});

  Future<Set<String>> restore();

  /// Where the person can change or cancel their plan.
  Future<Uri> manageUri();
}

class UnavailablePurchases implements PurchasesService {
  const UnavailablePurchases();

  @override
  bool get available => false;

  @override
  Stream<Set<String>> get entitlements => const Stream.empty();

  @override
  Future<void> identify(String? uid) async {}

  @override
  Future<Widget?> paywall(String offeringId, {required VoidCallback onFinished}) async => null;

  @override
  Future<Set<String>> restore() => throw const PurchaseFailure('Purchases aren\'t available right now.');

  @override
  Future<Uri> manageUri() async => defaultManageUri();
}

Uri defaultManageUri() =>
    defaultTargetPlatform == TargetPlatform.android ? Uri.parse('https://play.google.com/store/account/subscriptions') : Uri.parse('https://apps.apple.com/account/subscriptions');

Set<String> _activeEntitlements(CustomerInfo info) => {
  for (final entry in info.entitlements.active.entries)
    if (entry.value.isActive) entry.key,
};

/// The real store connection, through RevenueCat.
class RevenueCatPurchases implements PurchasesService {
  RevenueCatPurchases._();

  final _entitlements = StreamController<Set<String>>.broadcast();
  String? _identified;

  static Future<RevenueCatPurchases?> configure() async {
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => revenueCatAppleKey,
      TargetPlatform.android => revenueCatGoogleKey,
      _ => '',
    };
    if (key.isEmpty) return null;
    await Purchases.configure(PurchasesConfiguration(key));
    final service = RevenueCatPurchases._();
    Purchases.addCustomerInfoUpdateListener((info) => service._entitlements.add(_activeEntitlements(info)));
    return service;
  }

  @override
  bool get available => true;

  @override
  Stream<Set<String>> get entitlements => _entitlements.stream;

  @override
  Future<void> identify(String? uid) async {
    if (uid == _identified) return;
    _identified = uid;
    final info = uid == null ? await Purchases.logOut() : (await Purchases.logIn(uid)).customerInfo;
    _entitlements.add(_activeEntitlements(info));
  }

  @override
  Future<Widget?> paywall(String offeringId, {required VoidCallback onFinished}) async {
    final offering = (await Purchases.getOfferings()).getOffering(offeringId);
    if (offering == null) return null;
    return PaywallView(
      offering: offering,
      displayCloseButton: true,
      onPurchaseCompleted: (info, _) {
        _entitlements.add(_activeEntitlements(info));
        onFinished();
      },
      onRestoreCompleted: (info) => _entitlements.add(_activeEntitlements(info)),
      onDismiss: onFinished,
    );
  }

  @override
  Future<Set<String>> restore() async {
    try {
      final active = _activeEntitlements(await Purchases.restorePurchases());
      _entitlements.add(active);
      return active;
    } on PlatformException {
      throw const PurchaseFailure('Couldn\'t restore purchases. Check your connection and try again.');
    }
  }

  @override
  Future<Uri> manageUri() async {
    final url = (await Purchases.getCustomerInfo()).managementURL;
    return url == null ? defaultManageUri() : Uri.parse(url);
  }
}
