import 'package:akillisletme/firebase_options.dart';
import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uygulama acilisindaki tek seferlik hazirlik adimlari.
///
/// Sira onemlidir: binding → hata yakalama → platform ayarlari → lokalizasyon
/// → Firebase → servisler. Hata yakalama erken baglanir ki sonraki adimlarda
/// olusan hatalar da raporlansin.
@immutable
final class ApplicationInit {
  const ApplicationInit();

  Future<void> start() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorHandler.register();

    await _lockOrientation();
    await EasyLocalization.ensureInitialized();

    if (AppConfig.firebaseEnabled) {
      await _initializeFirebase();
    }

    _warnOnMisconfiguration();

    await setupLocator();
  }

  /// Firebase kurulu degilken bu hic cagrilmaz — template klonlandigi anda
  /// `firebase_options.dart` placeholder'dir ve calistirilmasi hata verirdi.
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppErrorHandler.attachCrashlytics();
  }

  /// Sessizce kirilan yapilandirma hatalarini gelistirme sirasinda gorunur
  /// kilar. Hicbiri uygulamayi durdurmaz; yalnizca uyarir.
  void _warnOnMisconfiguration() {
    if (!kDebugMode) return;

    if (AppConfig.isGoogleMisconfigured) {
      debugPrint(
        '⚠️  Google girisi acik ama AppConfig.googleServerClientId bos. '
        'idToken alinamaz, giris sessizce basarisiz olur. '
        'Bkz. doc/guides/auth_setup.md',
      );
    }
    if (AppConfig.violatesAppleSignInRule) {
      debugPrint(
        '⚠️  Google girisi acik ama Apple kapali. App Store Inceleme 4.8: '
        'ucuncu taraf giris varsa Apple ile giris de ZORUNLUDUR — iOS '
        'yayininda ret sebebi. Bkz. doc/guides/auth_setup.md',
      );
    }
  }

  /// Template dikey yerlesime gore tasarlandi. Yatay destegi gerekiyorsa bu
  /// cagriyi kaldirmak yeterli — ancak once tum ekranlarin genis yerlesimde
  /// dogru gorundugu dogrulanmali (`context.isWide`).
  Future<void> _lockOrientation() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
