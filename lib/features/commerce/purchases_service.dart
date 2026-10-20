import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifiers. Coach Pro products also grant `player_pro`.
const playerProEntitlement = 'player_pro';
const coachProEntitlement = 'coach_pro';

/// The public SDK keys are meant to ship inside the app; they can only read offerings and make purchases.
const revenueCatAppleKey = 'appl_OeNEuTtPsolnKkVomQlwOKdSGwT';
const revenueCatGoogleKey = 'goog_XbMcpcfabIHJWMJKboTFfoCIiGg';

/// One plan the store can sell, with the price text the store itself reports.
class PlanOffer {
  const PlanOffer({required this.id, required this.coach, required this.yearly, required this.price, this.handle});

  final String id;
  final bool coach;
  final bool yearly;
  final String price;

  /// The store package behind this plan. Opaque to the screens.
  final Object? handle;
}

enum PurchaseOutcome { purchased, cancelled }

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

  Future<List<PlanOffer>> offers();
  Future<PurchaseOutcome> purchase(PlanOffer offer);
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
  Future<List<PlanOffer>> offers() async => const [];

  @override
  Future<PurchaseOutcome> purchase(PlanOffer offer) => throw const PurchaseFailure('Purchases aren\'t available right now.');

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
  Future<List<PlanOffer>> offers() async {
    final offerings = await Purchases.getOfferings();
    return [
      for (final (id, coach) in const [('player', false), ('coach', true)])
        for (final package in offerings.getOffering(id)?.availablePackages ?? const <Package>[])
          if (package.packageType == PackageType.monthly || package.packageType == PackageType.annual)
            PlanOffer(id: '$id/${package.identifier}', coach: coach, yearly: package.packageType == PackageType.annual, price: package.storeProduct.priceString, handle: package),
    ];
  }

  @override
  Future<PurchaseOutcome> purchase(PlanOffer offer) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(offer.handle! as Package));
      _entitlements.add(_activeEntitlements(result.customerInfo));
      return PurchaseOutcome.purchased;
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) == PurchasesErrorCode.purchaseCancelledError) return PurchaseOutcome.cancelled;
      throw const PurchaseFailure('The purchase didn\'t go through. You weren\'t charged. Try again in a moment.');
    }
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
