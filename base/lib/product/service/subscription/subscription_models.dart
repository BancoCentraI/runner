import 'package:flutter/foundation.dart';

/// Odeme altyapisindan **bagimsiz** abonelik durumu.
///
/// RevenueCat tiplerinin (`CustomerInfo`, `EntitlementInfo`) servis disina
/// sizmamasi icin kendi modelimiz. Altyapi degisirse yalnizca
/// `PurchaseService` impl'i degisir, gerisi bu modele bagli kalir.
@immutable
class SubscriptionStatus {
  const SubscriptionStatus({required this.isPremium, this.expiresAt});

  /// Premium olmayan (ucretsiz) durum.
  const SubscriptionStatus.free() : isPremium = false, expiresAt = null;

  final bool isPremium;

  /// Bitis/yenilenme tarihi. Yasam boyu satin alimlarda `null`.
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatus &&
          other.isPremium == isPremium &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(isPremium, expiresAt);
}

/// Bir abonelik planinin yenilenme periyodu.
enum SubscriptionPeriod {
  weekly,
  monthly,
  twoMonth,
  threeMonth,
  sixMonth,
  annual,
  lifetime,
  unknown,
}

/// Satin alinabilir tek bir plan.
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
    this.hasFreeTrial = false,
  });

  /// Paket tanimlayicisi — satin alma cagrisinda kullanilir.
  final String id;

  final String title;

  /// **Magazadan gelen** yerellestirilmis fiyat. Fiyat asla kodda yazilmaz:
  /// para birimi, vergi ve bolgesel fiyatlandirma magazadan gelir.
  final String priceString;

  final SubscriptionPeriod period;

  /// Magaza tarafinda tanimli ucretsiz deneme asamasi var mi?
  /// (Suresi Play/App Store Connect'ten yonetilir; kod sureyi hardcode etmez.)
  final bool hasFreeTrial;
}

/// O anki sunum — satin alinabilir planlarin listesi.
@immutable
class SubscriptionOffering {
  const SubscriptionOffering({required this.plans});
  const SubscriptionOffering.empty() : plans = const [];

  final List<SubscriptionPlan> plans;

  /// RevenueCat'te urun henuz import edilmemisse bos doner — paywall bunu
  /// "yakinda" durumu olarak ele almalidir, hata olarak degil.
  bool get isEmpty => plans.isEmpty;
}

/// Bir satin alma denemesinin sonucu.
enum PurchaseOutcome {
  /// Basarili, entitlement guncellendi.
  purchased,

  /// Kullanici akisi iptal etti — **hata degildir**, mesaj gosterilmez.
  cancelled,

  error,
}

@immutable
class PurchaseAttemptResult {
  const PurchaseAttemptResult(this.outcome, {this.errorMessage});

  final PurchaseOutcome outcome;
  final String? errorMessage;
}

/// Premium'a cekilmis uygulama ozellikleri.
///
/// Yeni bir ozelligi premium yapmak = buraya **tek satir** eklemek + ilgili
/// yeri `PremiumGuard` ile sarmalamak. Hangi ozelligin premium oldugu tek
/// merkezden yonetilir.
enum PremiumFeature {
  /// Ornek — kendi ozelliklerinle degistir.
  advancedFeature,

  /// Reklamsiz kullanim.
  removeAds,
}

/// Premium erisim sorgusunun dar arayuzu.
///
/// Kilit uygulayan yerler tum `SubscriptionCubit` yerine buna baglanir →
/// testte sahtelenebilir ve erisim tek noktadan (bypass edilemez) kontrol
/// edilir.
abstract interface class PremiumEntitlement {
  bool isPremiumFor(PremiumFeature feature);

  /// Herhangi bir premium ozellik acik mi? Genel "premium rozeti" gostermek
  /// gibi ozellik-bagimsiz yerlerde kullanilir.
  bool get hasAnyPremium;
}
