# Firebase & Giriş Kurulumu — AI Yönergesi

> Bu dosya **AI ajanı için talimattır**, kullanıcı için rehber değil.
> Kullanıcı "girişi kur", "Firebase'i bağla", "Google girişi ekle" dediğinde bu
> akışı yürüt. Kullanıcı tek başına okuyacaksa: soruları kendine sor, cevaplarına
> göre bayrakları çevir, sonundaki manuel adımları uygula.

Kod **zaten hazır**. Servisler (`FirebaseAuthService`, `MockAuthService`),
ekranlar, route guard ve hata çevirileri yerinde. Bu akış yalnızca üç şey yapar:

1. Kullanıcıya ne istediğini sorar,
2. `lib/product/const/app_config.dart` içindeki bayrakları çevirir,
3. Kullanıcının **Console/Xcode/Play tarafında** yapması gerekenleri listeler.

Kod yazmıyorsun — bayrak çeviriyor ve checklist veriyorsun.

---

## Adım 0 — Durumu oku

Önce mevcut durumu tespit et, kullanıcıya zaten yaptığı şeyi sorma:

```bash
grep -E "firebaseEnabled|enableGoogleSignIn|enableAppleSignIn|requireEmailVerification|allowGuestBrowsing|googleServerClientId" lib/product/const/app_config.dart
ls lib/firebase_options.dart android/app/google-services.json ios/Runner/GoogleService-Info.plist 2>/dev/null
```

`lib/firebase_options.dart` içinde `PLACEHOLDER` yazıyorsa `flutterfire configure` **henüz çalıştırılmamıştır**.

---

## Adım 1 — Soruları sor

Hepsini **tek seferde** sor; kullanıcı zaten cevaplamışsa tekrar sorma.

**S1 — Firebase kurulu mu?**
> `flutterfire configure` çalıştırdın mı, `lib/firebase_options.dart` gerçek değerlerle dolu mu?
- *Hayır* → Adım 2'yi (Firebase kurulumu) ver, akış orada durur. Bayrak `false` kalır; uygulama `MockAuthService` ile çalışmaya devam eder.
- *Evet* → devam.

**S2 — Hangi giriş yöntemleri?**
> E-posta/şifre her zaman açık. Ek olarak: Google? Apple?
- Google seçilirse **Apple da zorunludur** (App Store İnceleme 4.8: üçüncü taraf giriş varsa Apple da sunulmalı). Kullanıcı Apple'ı istemezse bunu söyle ve iOS'ta ret riskini yaz; kararı ona bırak.

**S3 — E-posta doğrulaması zorunlu olsun mu?**
> Kayıt olan kullanıcı e-postasını doğrulamadan uygulamayı kullanabilsin mi?
- Varsayılan: hayır (`requireEmailVerification = false`).

**S4 — Misafir gezebilsin mi?**
> Oturumsuz kullanıcı uygulamayı gezebilsin mi, yoksa her şey giriş arkasında mı olsun?
- Varsayılan: gezebilsin (`allowGuestBrowsing = true`). Bu durumda hangi rotaların oturum isteyeceğini sor → `AppRouter.protectedPrefixes`.

---

## Adım 2 — Firebase projesi (S1 = hayır ise)

Kullanıcıya ver, sen çalıştırma (interaktif giriş ister):

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Üretilen dosyalar:
- `lib/firebase_options.dart` (placeholder'ın üzerine yazar)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Sonra Console → **Authentication → Sign-in method**'dan kullanılacak sağlayıcıları aç.

> **applicationId uyumu:** `android/app/build.gradle.kts` içindeki `applicationId`, Firebase Android app'inin paket adıyla **birebir aynı** olmalı; yoksa `google-services.json` eşleşmez ve giriş sessizce çalışmaz.

Kullanıcı bunları tamamlayınca akışa Adım 3'ten devam et.

---

## Adım 3 — Bayrakları çevir

`lib/product/const/app_config.dart`:

| Cevap | Bayrak |
|---|---|
| Firebase kurulu | `firebaseEnabled = true` |
| Google isteniyor | `enableGoogleSignIn = true` |
| Apple isteniyor | `enableAppleSignIn = true` |
| Google açıksa | `googleServerClientId = '<Web client ID>'` |
| E-posta doğrulama zorunlu | `requireEmailVerification = true` |
| Misafir gezinemesin | `allowGuestBrowsing = false` |

Korumalı rotalar değişiyorsa `AppRouter.protectedPrefixes` listesini güncelle
(`lib/product/navigation/app_router.dart`).

Sonra:

```bash
./script/verify.sh
```

Bayrak dışında **hiçbir dosyayı değiştirme.** Ekranlar, butonlar ve guard bu
bayraklara göre kendini ayarlar.

---

## Adım 4 — Manuel adımları ver

Yalnızca **açılan sağlayıcıların** bloğunu ver. Kullanıcı bunları senin yerine yapamayacağın için (Console erişimi, Xcode, keystore) net ve sıralı yaz.

### 🔑 Google ile giriş

**Web client ID'yi bul**
Firebase Console → Authentication → Sign-in method → Google (açık olmalı) → "Web SDK configuration" → Web client ID. `...apps.googleusercontent.com` ile biter.
Alternatif: `android/app/google-services.json` içinde `"client_type": 3` olan `client_id`.

Bu değeri `AppConfig.googleServerClientId`'ye yaz. **Boş bırakılırsa giriş sessizce kırılır** — `idToken` null döner, Firebase credential'ı anlamsız bir hatayla reddeder.

**Android**
1. Debug **ve** release imza anahtarlarının SHA-1 + SHA-256 parmak izlerini Firebase Android app'ine ekle:
   ```bash
   # debug
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```
2. Play App Signing kullanıyorsan Play Console → Setup → App signing'deki sertifikanın SHA'larını da ekle. **Bu adım atlanırsa uygulama Play'den indirildiğinde Google girişi çalışmaz ama debug'da çalışır** — en sık gözden kaçan hata budur.
3. SHA ekledikten sonra `google-services.json`'ı **yeniden indir**. Eski dosya yeni OAuth client'ı içermez.

**iOS**
1. `GoogleService-Info.plist` içindeki `REVERSED_CLIENT_ID` değerini kopyala.
2. `ios/Runner/Info.plist` → `CFBundleURLTypes` altına URL scheme olarak ekle.
3. ⚠️ `flutterfire configure` her yeniden çalıştırıldığında plist yenilenir ama **Info.plist'teki scheme otomatik güncellenmez.** İkisi ayrışırsa Google girişi hiçbir anlamlı hata vermeden kırılır. Plist her yenilendiğinde bu eşitliği elle doğrula.

### 🍎 Apple ile giriş

1. [Apple Developer](https://developer.apple.com) → Certificates, Identifiers & Profiles → App ID → **Sign in with Apple** yeteneğini aç.
2. Xcode → Runner target → Signing & Capabilities → **+ Capability → Sign in with Apple** (entitlements dosyasına `com.apple.developer.applesignin` ekler).
3. Firebase Console → Authentication → Apple sağlayıcısını aç.
   ⚠️ **Services ID alanını native iOS girişi için BOŞ bırak.** O alan web/Android akışı içindir; native akışta doldurmak doğrulamayı bozar.
4. Test: simülatöre Ayarlar'dan bir Apple hesabıyla **tam** (iki adımlı doğrulama dahil) giriş yapılmış olmalı. Yarıda bırakılmış oturum, giriş sayfası hiç açılmadan anında hata döndürür. Kesin doğrulama her zaman gerçek cihazdır.

> Kodda zaten halledilmiş, kullanıcının bilmesi gereken iki nokta:
> Apple ad/e-postayı **yalnızca ilk yetkilendirmede** döndürür (`FirebaseAuthService` ilk girişte profile yazıyor), ve `accessToken: authorizationCode` parametresi olmadan Firebase token'ı reddeder — ikisi de yerinde.

### ✉️ E-posta doğrulama (`requireEmailVerification = true` ise)

1. Firebase Console → Authentication → Templates → doğrulama e-postası şablonunu ve gönderen adını özelleştir.
2. Kullanıcıya davranışı anlat: doğrulanmamış kullanıcı `EmailVerificationView`'a kilitlenir, yalnızca "Doğruladım" ve "Tekrar gönder" yapabilir.
3. Spam klasörü uyarısı — özel domain doğrulanmadıysa Firebase'in varsayılan gönderen adresi sık spam'e düşer.

### 🗑️ Hesap silme

Kodda hazır (`AuthCubit.deleteAccount`) ve **mağaza şartıdır**: hesap oluşturmaya izin veren uygulama hesap silmeyi de sunmak zorundadır (App Store 5.1.1(v), Google Play).

Kullanıcıya söyle:
- Silme öncesi yeniden doğrulama yapılır (e-posta → şifre, Google/Apple → sağlayıcı sayfası). Firebase 5 dakikadan taze giriş ister.
- Bu akış yalnızca **Firebase Auth kullanıcısını** siler. Firestore/Storage'da kullanıcıya ait veri varsa onları silmek ayrı bir iştir; ölçek büyüdüğünde Admin SDK ile bir Cloud Function'a taşınmalıdır (istemci yalnızca kendi dökümanlarını silebilir).

---

## Adım 5 — Doğrula ve özetle

```bash
./script/verify.sh
```

Uygulamayı çalıştır, şu üçünü test et ve kullanıcıya sonucu bildir:
1. E-posta ile kayıt → giriş → çıkış
2. Açılan her sosyal sağlayıcı ile giriş
3. Korumalı bir rotaya oturumsuz gitmeyi dene → login'e yönlendirmeli

Sonra **tek ekranda** özetle: hangi bayraklar açıldı, kullanıcının hâlâ yapması gereken manuel adımlar, ve atlanan/ertelenen şeyler.

---

## Sık karşılaşılan arızalar

| Belirti | Sebep | Çözüm |
|---|---|---|
| Google girişi hiçbir hata vermeden kapanıyor | `googleServerClientId` boş | Web client ID'yi doldur |
| Debug'da çalışıyor, Play'den inince çalışmıyor | Play App Signing SHA'ları eklenmemiş | Play Console'daki sertifika SHA'larını ekle + json'ı yenile |
| iOS'ta Google girişi sessizce kırık | `Info.plist` URL scheme'i eski | `REVERSED_CLIENT_ID` ile eşitle |
| `invalid-credential — Invalid OAuth response from apple.com` | `accessToken` eksik | Kodda halledilmiş; farklı bir şey değiştiyse `FirebaseAuthService._appleCredential`'a bak |
| Apple girişinde ad boş geliyor | Ad yalnızca ilk yetkilendirmede gelir | Test için: iCloud ayarları → Apple Account → Sign in with Apple → uygulamayı sil |
| E-posta kullanıcısı çıkış yapamıyor | Google v7 `signOut` initialize'sız çağrılmış | Kodda halledilmiş (try/catch); değiştiyse geri al |
| "Doğru şifreyle" `invalid-credential` | Hesap sosyal girişle açılmış, şifresi yok | Console'da kullanıcının `providerData`'sına bak |
| Giriş sonrası ekranda takılı kalıyor | Guard'lı rotaya `push` ile gidilmiş | `go` kullan (`doc/guides/auth.md`) |

## İlgili dokümanlar

- `doc/guides/auth.md` — mimari ve günlük kullanım
- `doc/guides/flutter-firebase-auth-rehberi.md` — derinlemesine teşhis rehberi
- `lib/feature/auth/auth.md` — ekran modülü
