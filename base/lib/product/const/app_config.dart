import 'package:flutter/foundation.dart';

/// Backend ve kimlik dogrulama ozelliklerinin acilip kapandigi tek yer.
///
/// Template klonlandigi anda `firebaseEnabled: false` ile gelir: uygulama
/// derlenir, calisir ve giris ekrani `MockAuthService` uzerinden **gercekten**
/// calisir. Klonlayan Firebase'i kurunca buradaki bayraklari cevirir; baska
/// hicbir dosya degismez.
///
/// Bayraklari elle cevirmek zorunda degilsin — `doc/guides/auth_setup.md`
/// akisini calistir (ya da `starter-auth-setup` skill'ini), sorulari yanitla;
/// gerisi otomatik baglanir ve Console tarafinda yapman gerekenler listelenir.
///
/// **Buradaki hicbir deger sir degildir.** Firebase istemci anahtarlari ve
/// Google Web client ID zaten `google-services.json` / `GoogleService-Info.plist`
/// icinde dagitilir; guvenlik Firebase Security Rules ile saglanir.
@immutable
final class AppConfig {
  const AppConfig._();

  // ── Backend ────────────────────────────────────────────────

  /// Firebase gercekten kurulu mu?
  ///
  /// `false` iken:
  /// - `Firebase.initializeApp` cagrilmaz (yapilandirma dosyalari gerekmez),
  /// - kimlik dogrulama `MockAuthService` ile calisir,
  /// - Crashlytics / Analytics / Remote Config sessizce devre disi kalir.
  ///
  /// `true` yapmadan once `flutterfire configure` calistirilmis ve
  /// `lib/firebase_options.dart` uretilmis olmalidir — aksi halde acilista
  /// yapilandirma hatasi alinir.
  static const bool firebaseEnabled = false;

  // ── Kimlik dogrulama saglayicilari ─────────────────────────

  /// E-posta + sifre. Temel yontem; kapatilmasi onerilmez.
  static const bool enableEmailSignIn = true;

  /// Google ile giris.
  ///
  /// Acmadan once: Firebase Console'da Google saglayicisi acilmali, SHA-1 ve
  /// SHA-256 parmak izleri eklenmeli, [googleServerClientId] doldurulmali.
  /// Ayrinti: `doc/guides/auth_setup.md`.
  static const bool enableGoogleSignIn = false;

  /// Apple ile giris.
  ///
  /// **App Store kurali (Inceleme 4.8):** uygulamada baska bir ucuncu taraf
  /// giris (Google dahil) varsa Apple ile girisi de sunmak ZORUNLUDUR.
  /// Google acikken bunu kapali birakmak iOS'ta ret sebebidir.
  static const bool enableAppleSignIn = false;

  /// Firebase Console'da Google saglayicisi acilinca olusan **Web client ID**
  /// (`...apps.googleusercontent.com`). Google'dan `idToken` alabilmek icin
  /// zorunludur; `google-services.json` icinde `client_type: 3` olarak gecer.
  ///
  /// Bos birakilirsa Google girisi sessizce kirilir — `idToken` null doner ve
  /// Firebase credential'i anlamli bir hata vermeden reddeder.
  static const String googleServerClientId = '';

  // ── Davranis ───────────────────────────────────────────────

  /// Kayit sonrasi e-posta dogrulamasi zorunlu olsun mu?
  ///
  /// `true` ise dogrulanmamis kullanici korumali sayfalara giremez, dogrulama
  /// ekranina yonlendirilir.
  static const bool requireEmailVerification = false;

  /// Oturumsuz kullanici uygulamayi gezebilir mi?
  ///
  /// `true` (varsayilan): misafir gezer, yalnizca `AppRouter.protectedPrefixes`
  /// altindaki rotalar oturum ister. Kayit duvari donusumu dusurur — once
  /// degeri goster, sonra giris iste.
  ///
  /// `false`: uygulamanin tamami giris arkasinda.
  static const bool allowGuestBrowsing = true;

  /// Push bildirimleri acik mi? Kapaliyken FCM hic baslatilmaz ve izin
  /// istenmez — kullaniciya gereksiz izin dialog'u gosterilmez.
  static const bool enablePushNotifications = false;

  // ── Odeme (RevenueCat) ─────────────────────────────────────

  /// RevenueCat public SDK key'leri (dashboard → API Keys).
  ///
  /// Gizli veri degildir ama derleme zamaninda verilir:
  /// `--dart-define=REVENUECAT_ANDROID_KEY=goog_xxx`
  /// Bos ise odeme altyapisi devre disi kalir; herkes ucretsiz sayilir ve
  /// uygulama etkilenmez.
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );

  /// RevenueCat dashboard'da tanimli entitlement kimligi. Bu entitlement
  /// aktifse kullanici premium sayilir.
  static const String premiumEntitlementId = 'premium';

  // ── Turetilmis ─────────────────────────────────────────────

  /// Herhangi bir sosyal saglayici acik mi? Giris ekrani "veya" ayiricisini
  /// buna gore gosterir.
  static bool get hasSocialSignIn => enableGoogleSignIn || enableAppleSignIn;

  /// Google acik ama Web client ID verilmemis. Acilista uyarmak icin.
  static bool get isGoogleMisconfigured =>
      enableGoogleSignIn && googleServerClientId.isEmpty;

  /// Odeme altyapisi yapilandirilmis mi (en az bir platform anahtari var mi)?
  static bool get isPurchaseConfigured =>
      revenueCatAndroidKey.isNotEmpty || revenueCatIosKey.isNotEmpty;

  /// Apple kapali ama Google acik — App Store 4.8 ihlali.
  static bool get violatesAppleSignInRule =>
      enableGoogleSignIn && !enableAppleSignIn;
}
