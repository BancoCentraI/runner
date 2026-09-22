import 'package:akillisletme/product/cache/hive_v2/hive_cache.dart';
import 'package:akillisletme/product/cache/product_cache.dart';
import 'package:akillisletme/product/cache/shared_operation/shared_cache.dart';
import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/service/firebase/analytics/analytics_service.dart';
import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';
import 'package:akillisletme/product/service/firebase/auth/firebase_auth_service.dart';
import 'package:akillisletme/product/service/firebase/auth/mock_auth_service.dart';
import 'package:akillisletme/product/service/firebase/crashlytics/crash_reporter.dart';
import 'package:akillisletme/product/service/firebase/firestore/user_profile_service.dart';
import 'package:akillisletme/product/service/firebase/messaging/push_service.dart';
import 'package:akillisletme/product/service/firebase/storage/storage_service.dart';
import 'package:akillisletme/product/service/services/permission_service.dart';
import 'package:akillisletme/product/service/services/remote_config_service.dart';
import 'package:akillisletme/product/service/services/url_launcher_service.dart';
import 'package:akillisletme/product/service/subscription/purchase_service.dart';
import 'package:get_it/get_it.dart';

/// Uygulama servis konteyneri. Tum bagimliliklarin tek sahibi burasidir.
///
/// **Desen:** her Firebase servisi `interface + FirebaseXxx + NoopXxx`
/// uclusunden olusur. `AppConfig.firebaseEnabled` kapaliyken no-op baglanir —
/// boylece template klonlandigi anda hicbir kurulum olmadan calisir ve cagri
/// yerleri hicbir yerde `if (firebaseEnabled)` yazmak zorunda kalmaz.
final GetIt locator = GetIt.instance;

/// Servisleri kaydeder ve async init gerektirenler hazir olana kadar bekler.
Future<void> setupLocator() async {
  _registerLazySingletons();
  _registerAsyncSingletons();
  await locator.allReady();
}

/// Durumsuz, senkron servisler — ilk erisimde olusturulur (acilista degil).
void _registerLazySingletons() {
  const firebase = AppConfig.firebaseEnabled;

  locator
    ..registerLazySingleton<UrlLauncherService>(
      () => UrlLauncherService.instance,
    )
    ..registerLazySingleton<PermissionService>(() => PermissionService.instance)
    ..registerLazySingleton<CrashReporter>(
      () => firebase ? FirebaseCrashReporter() : const NoopCrashReporter(),
    )
    ..registerLazySingleton<AnalyticsService>(
      () =>
          firebase ? FirebaseAnalyticsService() : const NoopAnalyticsService(),
    )
    ..registerLazySingleton<StorageService>(
      () => firebase ? FirebaseStorageService() : const NoopStorageService(),
    )
    ..registerLazySingleton<UserProfileService>(
      () => firebase
          ? FirestoreUserProfileService(cache: locator<SharedCache>())
          : const NoopUserProfileService(),
    )
    // Firebase kurulu degilken bellek-ici mock devreye girer: giris akisi
    // klonlandigi anda calisir. AuthCubit ve ekranlar ikisini ayirt etmez.
    ..registerLazySingleton<AuthService>(
      () => firebase
          ? FirebaseAuthService(
              googleServerClientId: AppConfig.googleServerClientId,
            )
          : MockAuthService(),
    );
}

/// Async `init()` gerektiren servisler.
///
/// `registerSingletonAsync` + [GetIt.allReady] ile orkestre edilir: elle
/// `await service.init()` zinciri yazmaya gerek kalmaz.
void _registerAsyncSingletons() {
  const firebase = AppConfig.firebaseEnabled;

  locator
    ..registerSingletonAsync<SharedCache>(() async {
      final cache = SharedCache.instance;
      await cache.init();
      return cache;
    })
    ..registerSingletonAsync<ProductCache>(() async {
      final cache = ProductCache(cacheManager: HiveCacheManager());
      await cache.init();
      return cache;
    })
    // Zorunlu guncelleme kapisi (splash) icin minimum surum.
    // `allReady()` bunu bekler → splash acildiginda deger hazirdir.
    ..registerSingletonAsync<AppVersionSource>(() async {
      if (!firebase) return const StaticVersionSource();
      final service = RemoteConfigService.instance;
      await service.init();
      return service;
    })
    ..registerSingletonAsync<PushService>(() async {
      if (!firebase || !AppConfig.enablePushNotifications) {
        return const NoopPushService();
      }
      final service = FirebasePushService();
      await service.init();
      return service;
    })
    // Odeme altyapisi Firebase'den BAGIMSIZDIR — RevenueCat kendi anahtariyla
    // calisir. Anahtar verilmemisse herkes ucretsiz kabul edilir.
    ..registerSingletonAsync<PurchaseService>(() async {
      if (!AppConfig.isPurchaseConfigured) return const NoopPurchaseService();
      final service = RevenueCatPurchaseService();
      await service.init();
      return service;
    });
}

/// Servislere tip-guvenli, okunabilir erisim: `locator.sharedCache` gibi.
extension ServiceLocator on GetIt {
  SharedCache get sharedCache => locator<SharedCache>();
  ProductCache get productCache => locator<ProductCache>();
  UrlLauncherService get urlLauncher => locator<UrlLauncherService>();
  PermissionService get permission => locator<PermissionService>();
  AuthService get auth => locator<AuthService>();
  CrashReporter get crash => locator<CrashReporter>();
  AnalyticsService get analytics => locator<AnalyticsService>();
  PushService get push => locator<PushService>();
  StorageService get storage => locator<StorageService>();
  UserProfileService get userProfiles => locator<UserProfileService>();
  AppVersionSource get versionSource => locator<AppVersionSource>();
  PurchaseService get purchases => locator<PurchaseService>();
}
