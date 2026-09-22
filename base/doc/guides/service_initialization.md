# Servis Başlatma ve Locator

Tüm bağımlılıkların tek sahibi `lib/product/service/service_locator.dart`.

## Akış

```
ApplicationInit.start()
  → WidgetsFlutterBinding.ensureInitialized()
  → AppErrorHandler.register()          // hata yakalama erken bağlanır
  → orientation + EasyLocalization
  → Firebase.initializeApp()            // yalnız AppConfig.firebaseEnabled ise
  → setupLocator()
      → _registerLazySingletons()       // senkron servisler
      → _registerAsyncSingletons()      // async init gerekenler
      → locator.allReady()              // hepsi hazır olana kadar bekler
```

`main()` bunu `await` ettiği için **ilk kare çizilmeden önce** tüm kritik
servisler kullanıma hazırdır.

## İki kayıt türü

**`registerLazySingleton`** — durumsuz, `init()` istemeyen servisler. İlk
erişimde oluşturulur, açılışta değil.

**`registerSingletonAsync`** — `init()` gerektirenler. `allReady()` hepsini
bekler; elle `await service.init()` zinciri yazılmaz. Aralarında sıra
bağımlılığı varsa `dependsOn:` ile bildirilir.

## Firebase servisleri: üçlü desen

Her Firebase servisi **`interface + FirebaseXxx + NoopXxx`** üçlüsünden oluşur.
`AppConfig.firebaseEnabled` kapalıyken no-op bağlanır.

```dart
..registerLazySingleton<AnalyticsService>(
  () => firebase ? FirebaseAnalyticsService() : const NoopAnalyticsService(),
)
```

Sonuç: **çağrı yerinde hiçbir zaman `if (firebaseEnabled)` yazılmaz.** Template
klonlandığı anda hiçbir kurulum olmadan çalışır; servis çağrıları sessizce
no-op olur.

Kayıtlı olanlar: `AuthService` · `CrashReporter` · `AnalyticsService` ·
`PushService` · `StorageService` · `UserProfileService` · `AppVersionSource`

`PurchaseService` de aynı desendedir ama Firebase'e değil, RevenueCat
anahtarının varlığına bakar (`AppConfig.isPurchaseConfigured`).

## Yeni servis ekleme

**1. Sözleşmeyi yaz** (`abstract interface class`), sonra implementasyonu.
Servis dış dünyanın tipini (Firebase, RevenueCat…) **sızdırmaz**; kendi
modelini ve hata kodunu döndürür.

**2. Kaydet:**

```dart
// Senkron
..registerLazySingleton<NewService>(NewServiceImpl.new)

// Async init gerekiyorsa
..registerSingletonAsync<NewService>(() async {
  final service = NewServiceImpl();
  await service.init();
  return service;
})
```

**3. Getter ekle:**

```dart
extension ServiceLocator on GetIt {
  NewService get newService => locator<NewService>();
}
```

**4. Dış bağımlılığı varsa no-op karşılığını da yaz** — kapalıyken uygulama
çalışmaya devam etmeli.

## Erişim

```dart
locator.auth          locator.crash         locator.analytics
locator.push          locator.storage       locator.userProfiles
locator.sharedCache   locator.productCache  locator.versionSource
locator.purchases     locator.permission    locator.urlLauncher
```

Cubit'ler servisi **constructor'dan** alır, locator'a doğrudan çağrı gömmez —
aksi halde test edilemez hale gelir (`clean_code.md` → Test).

```dart
BlocProvider(create: (_) => AuthCubit(locator.auth))
```

## Modül-özel servisler

Yalnızca tek bir feature'ın kullandığı servis locator'a **kaydedilmez**;
`lib/feature/<ad>/service/` altında durur ve o feature'ın cubit'ine
constructor'dan verilir. Karar ağacı: [service_rules.md](service_rules.md).
