import 'dart:async';

import 'package:akillisletme/product/const/app_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Yakalanmayan hatalari tek noktada toplar.
///
/// Iki ayri kanal vardir ve **ikisinin de baglanmasi gerekir**; yalnizca
/// `FlutterError.onError` baglanirsa framework disindaki async hatalar
/// (Future, Isolate, event handler) sessizce kaybolur:
///
/// - `FlutterError.onError` — widget/framework hatalari
/// - `PlatformDispatcher.instance.onError` — yakalanmayan async hatalar
///
/// Crashlytics, Firebase acikken [attachCrashlytics] ile devreye girer; kapali
/// iken raporlar yalnizca debug konsoluna yazilir. Cagri yerleri degismez.
@immutable
final class AppErrorHandler {
  const AppErrorHandler._();

  static bool _crashlyticsReady = false;

  static void register() {
    FlutterError.onError = (details) {
      // Debug'da konsola stack trace basmaya devam et, aksi halde gelistirme
      // sirasinda hatalar gorunmez olur.
      FlutterError.presentError(details);
      _report(details.exception, details.stack, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _report(error, stack, fatal: true);
      // true = hata ele alindi; uygulama kapanmaz.
      return true;
    };
  }

  /// `Firebase.initializeApp` tamamlandiktan sonra cagrilir. Once cagrilirsa
  /// Crashlytics baslatilmamis olur ve raporlar kaybolur.
  static Future<void> attachCrashlytics() async {
    if (!AppConfig.firebaseEnabled) return;
    // Debug'da toplama kapali: gelistirme sirasindaki kasitli hatalar gercek
    // crash raporlarini kirletmemeli.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    _crashlyticsReady = true;
  }

  /// Yakalanan ama akisi bozmayan hatalar icin (catch blogu icinden cagrilir).
  static void reportHandled(Object error, [StackTrace? stack]) =>
      _report(error, stack, fatal: false);

  /// Hata raporlarini kullanici kimligiyle iliskilendirir. Oturum kapaninca
  /// `null` gecilir.
  static Future<void> setUserId(String? uid) async {
    if (!_crashlyticsReady) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
  }

  static void _report(Object error, StackTrace? stack, {required bool fatal}) {
    if (kDebugMode) {
      debugPrint('${fatal ? '❌ FATAL' : '⚠️  HANDLED'}: $error');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }

    if (!_crashlyticsReady) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal),
    );
  }

  /// Uygulamayi guarded zone icinde calistirir.
  ///
  /// `PlatformDispatcher.onError` cogu durumu yakalar; `runZonedGuarded` ise
  /// zone icinde baslatilan ucuncu parti kodun hatalarini da toplar.
  static void run(void Function() body) {
    runZonedGuarded(body, (error, stack) => _report(error, stack, fatal: true));
  }
}
