import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Kullanici davranisi olcumunun sozlesmesi (Firebase Analytics / GA4).
///
/// UI/feature dogrudan `FirebaseAnalytics.instance` cagirmaz; bu soyutlamaya
/// baglanir — olay semasi tek noktada tutulur ve testte sahtelenebilir.
///
/// **Kural:** olay adlarini cagri yerinde string olarak yazma; anlamli bir
/// metot ekle ya da `AnalyticsEvents` sabitlerini kullan. Aksi halde sema
/// zamanla dagilir ve GA4'te ayni olay farkli isimlerle birikir.
abstract interface class AnalyticsService {
  /// Rota gecislerini otomatik `screen_view` olarak loglayan gozlemci;
  /// GoRouter'in `observers` listesine eklenir.
  NavigatorObserver? get navigatorObserver;

  /// Serbest olay kaydi.
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Giris yapildi (`login`). [method]: `password` / `google.com` / `apple.com`.
  Future<void> logLogin(String method);

  /// Kayit olundu (`sign_up`).
  Future<void> logSignUp(String method);

  /// Bir icerik secildi (`select_content`).
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  });

  /// Arama yapildi (`search`).
  Future<void> logSearch(String term);

  /// Satin alma tamamlandi (`purchase`).
  Future<void> logPurchase({
    required String productId,
    required double value,
    required String currency,
  });

  /// Kullanici kimligi (Firebase Auth uid — asla PII). Cikista `null` gec.
  Future<void> setUserId(String? uid);

  /// Kullanici ozelligi (or. premium mi) — PII olmayan.
  Future<void> setUserProperty({required String name, required String? value});

  /// Toplama acik/kapali (KVKK rizasi icin).
  Future<void> setEnabled({required bool enabled});
}

/// Firebase kapaliyken kullanilan sessiz implementasyon.
final class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  NavigatorObserver? get navigatorObserver => null;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logLogin(String method) async {}

  @override
  Future<void> logSignUp(String method) async {}

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {}

  @override
  Future<void> logSearch(String term) async {}

  @override
  Future<void> logPurchase({
    required String productId,
    required double value,
    required String currency,
  }) async {}

  @override
  Future<void> setUserId(String? uid) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}

/// `firebase_analytics` kullanan uretim implementasyonu.
final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  NavigatorObserver get navigatorObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  @override
  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) => _analytics.logSelectContent(contentType: contentType, itemId: itemId);

  @override
  Future<void> logSearch(String term) => _analytics.logSearch(searchTerm: term);

  @override
  Future<void> logPurchase({
    required String productId,
    required double value,
    required String currency,
  }) => _analytics.logPurchase(
    currency: currency,
    value: value,
    items: [AnalyticsEventItem(itemId: productId, price: value)],
  );

  @override
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) => _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> setEnabled({required bool enabled}) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);
}
