import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Uzak cokme/hata raporlamanin sozlesmesi.
///
/// Kod bu soyutlamaya baglanir; Firebase kapaliyken [NoopCrashReporter],
/// acikken [FirebaseCrashReporter] baglanir. `AppErrorHandler` bunu kullanir.
abstract interface class CrashReporter {
  /// Yakalanmis bir hatayi raporlar. [fatal] true ise cokme gibi ele alinir.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal,
  });

  /// Flutter framework (widget agaci) hatasini olumcul olarak raporlar.
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Rapora eklenecek serbest metin iz kaydi (breadcrumb). Cokme aninda
  /// kullanicinin hangi adimlardan gectigini gormeyi saglar.
  void log(String message);

  /// Raporlari kullaniciya baglar (Firebase Auth uid — asla PII).
  Future<void> setUserId(String? uid);

  /// Hata anindaki durumu anlamak icin anahtar/deger baglami.
  Future<void> setCustomKey(String key, Object value);

  /// Toplama acik/kapali (KVKK rizasi / debug icin).
  Future<void> setEnabled({required bool enabled});
}

/// Firebase kapaliyken kullanilan sessiz implementasyon.
///
/// Debug'da konsola yazar ki gelistirme sirasinda hatalar gorunmez olmasin.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('${fatal ? '❌ FATAL' : '⚠️  HANDLED'}: $error');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (kDebugMode) FlutterError.presentError(details);
  }

  @override
  void log(String message) {
    if (kDebugMode) debugPrint('📝 $message');
  }

  @override
  Future<void> setUserId(String? uid) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}

/// `firebase_crashlytics` kullanan uretim implementasyonu.
final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter([FirebaseCrashlytics? crashlytics])
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      _crashlytics.recordFlutterFatalError(details);

  @override
  void log(String message) => _crashlytics.log(message);

  @override
  Future<void> setUserId(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  @override
  Future<void> setEnabled({required bool enabled}) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
