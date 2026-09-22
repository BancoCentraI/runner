import 'dart:async';

import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/service/subscription/subscription_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Odeme/abonelik altyapisinin dar arayuzu.
///
/// UI ve `SubscriptionCubit` yalnizca bu kontrata baglidir; **RevenueCat
/// tipleri bu dosyanin disina CIKMAZ** → altyapi degisirse tek dosya degisir.
abstract interface class PurchaseService {
  /// SDK'yi yapilandirir ve dinleyiciyi kurar. Anahtar yoksa no-op.
  Future<void> init();

  /// En son bilinen durum (senkron erisim).
  SubscriptionStatus get currentStatus;

  /// Durum degisimlerini yayinlar (satin alma, iptal, yenileme, restore).
  Stream<SubscriptionStatus> get statusStream;

  /// Guncel durumu altyapidan ceker (acilista otomatik senkron/restore).
  Future<SubscriptionStatus> refresh();

  /// Satin alimlari geri yukler (manuel "Satin alimlari geri yukle").
  ///
  /// **Magaza sarti:** iOS'ta bu buton olmadan uygulama reddedilir.
  Future<SubscriptionStatus> restore();

  /// Satin alinabilir planlari getirir. Urun import edilmemisse veya anahtar
  /// yoksa **bos** offering doner.
  Future<SubscriptionOffering> fetchOffering();

  /// Verilen plana ait satin almayi baslatir.
  Future<PurchaseAttemptResult> purchase(String planId);

  /// Abonelikleri kullanici hesabina baglar.
  ///
  /// **Cagrilmazsa kullanici cihaz degistirdiginde odedigi aboneligi
  /// kaybeder.** Giriste uid ile, cikista `null` ile cagrilir.
  Future<void> setAppUserId(String? uid);
}

/// Anahtar verilmemisken kullanilan sessiz implementasyon — herkes ucretsiz.
final class NoopPurchaseService implements PurchaseService {
  const NoopPurchaseService();

  @override
  Future<void> init() async {}

  @override
  SubscriptionStatus get currentStatus => const SubscriptionStatus.free();

  @override
  Stream<SubscriptionStatus> get statusStream =>
      const Stream<SubscriptionStatus>.empty();

  @override
  Future<SubscriptionStatus> refresh() async => currentStatus;

  @override
  Future<SubscriptionStatus> restore() async => currentStatus;

  @override
  Future<SubscriptionOffering> fetchOffering() async =>
      const SubscriptionOffering.empty();

  @override
  Future<PurchaseAttemptResult> purchase(String planId) async =>
      const PurchaseAttemptResult(PurchaseOutcome.error);

  @override
  Future<void> setAppUserId(String? uid) async {}
}

/// [PurchaseService]'in RevenueCat (`purchases_flutter`) implementasyonu.
final class RevenueCatPurchaseService implements PurchaseService {
  final StreamController<SubscriptionStatus> _controller =
      StreamController<SubscriptionStatus>.broadcast();

  SubscriptionStatus _status = const SubscriptionStatus.free();

  /// Plan id → RevenueCat `Package` eslemesi. RevenueCat tipi burada sakli.
  final Map<String, Package> _packages = {};

  bool _configured = false;

  @override
  SubscriptionStatus get currentStatus => _status;

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  static String get _apiKey => defaultTargetPlatform == TargetPlatform.iOS
      ? AppConfig.revenueCatIosKey
      : AppConfig.revenueCatAndroidKey;

  @override
  Future<void> init() async {
    if (_apiKey.isEmpty) return;
    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(
        (info) => _emit(_mapCustomerInfo(info)),
      );
      // Acilista otomatik restore/senkron: ayni magaza hesabiyla onceki satin
      // alma varsa premium hemen taninir.
      await refresh();
    } on PlatformException catch (error, stackTrace) {
      // Yapilandirma hatasi ana uygulamayi bozmamali → ucretsizle devam.
      AppErrorHandler.reportHandled(error, stackTrace);
    }
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    if (!_configured) return _status;
    try {
      return _emit(_mapCustomerInfo(await Purchases.getCustomerInfo()));
    } on PlatformException catch (error, stackTrace) {
      AppErrorHandler.reportHandled(error, stackTrace);
      return _status;
    }
  }

  @override
  Future<SubscriptionStatus> restore() async {
    if (!_configured) return _status;
    try {
      return _emit(_mapCustomerInfo(await Purchases.restorePurchases()));
    } on PlatformException catch (error, stackTrace) {
      AppErrorHandler.reportHandled(error, stackTrace);
      return _status;
    }
  }

  @override
  Future<SubscriptionOffering> fetchOffering() async {
    if (!_configured) return const SubscriptionOffering.empty();
    try {
      final current = (await Purchases.getOfferings()).current;
      if (current == null) return const SubscriptionOffering.empty();

      _packages
        ..clear()
        ..addEntries(
          current.availablePackages.map((p) => MapEntry(p.identifier, p)),
        );

      return SubscriptionOffering(
        plans: current.availablePackages
            .map(
              (p) => SubscriptionPlan(
                id: p.identifier,
                title: p.storeProduct.title,
                priceString: p.storeProduct.priceString,
                period: _mapPeriod(p.packageType),
                hasFreeTrial:
                    p.storeProduct.subscriptionOptions?.any(
                      (o) => o.freePhase != null,
                    ) ??
                    false,
              ),
            )
            .toList(),
      );
    } on PlatformException catch (error, stackTrace) {
      AppErrorHandler.reportHandled(error, stackTrace);
      return const SubscriptionOffering.empty();
    }
  }

  @override
  Future<PurchaseAttemptResult> purchase(String planId) async {
    if (!_configured) {
      return const PurchaseAttemptResult(PurchaseOutcome.error);
    }
    final package = _packages[planId];
    if (package == null) {
      return const PurchaseAttemptResult(PurchaseOutcome.error);
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _emit(_mapCustomerInfo(result.customerInfo));
      return const PurchaseAttemptResult(PurchaseOutcome.purchased);
    } on PlatformException catch (error, stackTrace) {
      // Iptal hata degildir — auth akisindaki ayni kural.
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseAttemptResult(PurchaseOutcome.cancelled);
      }
      AppErrorHandler.reportHandled(error, stackTrace);
      return PurchaseAttemptResult(
        PurchaseOutcome.error,
        errorMessage: error.message,
      );
    }
  }

  @override
  Future<void> setAppUserId(String? uid) async {
    if (!_configured) return;
    try {
      if (uid == null) {
        await Purchases.logOut();
      } else {
        await Purchases.logIn(uid);
      }
      await refresh();
    } on PlatformException catch (error, stackTrace) {
      // Anonim kullanicida `logOut` hata verebilir — akisi bozmaz.
      AppErrorHandler.reportHandled(error, stackTrace);
    }
  }

  SubscriptionPeriod _mapPeriod(PackageType type) => switch (type) {
    PackageType.weekly => SubscriptionPeriod.weekly,
    PackageType.monthly => SubscriptionPeriod.monthly,
    PackageType.twoMonth => SubscriptionPeriod.twoMonth,
    PackageType.threeMonth => SubscriptionPeriod.threeMonth,
    PackageType.sixMonth => SubscriptionPeriod.sixMonth,
    PackageType.annual => SubscriptionPeriod.annual,
    PackageType.lifetime => SubscriptionPeriod.lifetime,
    _ => SubscriptionPeriod.unknown,
  };

  SubscriptionStatus _mapCustomerInfo(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[AppConfig.premiumEntitlementId];
    if (entitlement == null) return const SubscriptionStatus.free();

    final expiration = entitlement.expirationDate;
    return SubscriptionStatus(
      isPremium: true,
      expiresAt: expiration == null ? null : DateTime.tryParse(expiration),
    );
  }

  SubscriptionStatus _emit(SubscriptionStatus status) {
    _status = status;
    if (!_controller.isClosed) _controller.add(status);
    return status;
  }
}
