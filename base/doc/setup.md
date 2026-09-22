# Kurulum — Buradan Başla

Bu projeyi yeni klonladıysan doğru dosyadasın.

## En kısa yol

Bir AI ajanına (Claude Code / Cursor) şunu söyle:

> **kurulumu yap**

Ajan sana ne istediğini sorar, kodu bağlar ve Firebase / Apple / Play /
RevenueCat tarafında **senin** yapman gerekenleri sırayla verir.
Adım adım kendin yürütmek istersen aşağıdaki tabloyu takip et.

---

## Temel fikir

Template klonlandığı anda **çalışır**. Giriş ekranı, ödeme altyapısı, sürüm
kontrolü ve bildirimler kodda hazır ama **kapalı** gelir. Hepsi tek dosyadaki
bayraklarla açılır:

```
lib/product/const/app_config.dart
```

Bir bayrak kapalıyken karşılığı olan servis sessiz bir "no-op"a düşer —
uygulama çökmez, ekranlar çalışmaya devam eder. Yani Firebase kurmadan da
uygulamayı açıp giriş ekranını deneyebilirsin (`MockAuthService` herhangi bir
e-posta/şifreyi kabul eder).

**Kurulum kod yazmak değildir: bayrak çevirmek + konsol tarafını yapmaktır.**

---

## Adımlar

| # | Adım | Rehber | Ne zaman |
|---|---|---|---|
| 1 | Bağımlılıklar, codegen, çeviri anahtarları | [guides/setup_after_clone.md](guides/setup_after_clone.md) | **İlk iş, her zaman** |
| 2 | Projeyi kendine uyarla (paket adı, metinler, tema, Android modülleri) | [guides/customization.md](guides/customization.md) | **Her zaman** |
| 3 | Firebase + giriş yöntemleri (Google / Apple / e-posta) | [guides/auth_setup.md](guides/auth_setup.md) | Hesap/oturum gerekiyorsa |
| 4 | Zorunlu güncelleme (Remote Config) | [guides/version_control_setup.md](guides/version_control_setup.md) | Yayına çıkmadan önce |
| 5 | Ödeme / abonelik (RevenueCat) | [guides/payment_setup.md](guides/payment_setup.md) | Premium özellik varsa |
| 6 | Android release imzalama (keystore) | [guides/android_signing.md](guides/android_signing.md) | Play'e yüklemeden önce |
| 7 | Açılış animasyonu (native splash) | [guides/native_splash.md](guides/native_splash.md) | Marka görselin hazırsa |
| 8 | Store URL'leri, iletişim, yasal metinler | [guides/settings_and_urls.md](guides/settings_and_urls.md) | Yayına çıkmadan önce |

1 ve 2 zorunlu, gerisi ihtiyaca göre. **Her adımdan sonra:**

```bash
./script/verify.sh
```

---

## Komutlar

```bash
./script/general.sh     # bağımlılık + codegen + çeviri anahtarları (klon sonrası tek komut)
./script/verify.sh      # format → analyze → test  (her işin sonunda)
./script/codegen.sh     # Freezed / GoRouter / Hive / FlutterGen
./script/lang.sh        # locale_keys.g.dart
./script/deep_clean.sh  # her şeyi sıfırdan kur
```

---

## Bayraklar

`lib/product/const/app_config.dart` — hangi adım neyi açar:

| Bayrak | Adım |
|---|---|
| `firebaseEnabled` | 3 |
| `enableGoogleSignIn` + `googleServerClientId` | 3 |
| `enableAppleSignIn` | 3 |
| `requireEmailVerification` | 3 |
| `allowGuestBrowsing` | 3 |
| `enablePushNotifications` | 3 |
| `revenueCatAndroidKey` / `revenueCatIosKey` | 5 |

Korumalı rotalar: `AppRouter.protectedPrefixes`
(`lib/product/navigation/app_router.dart`).

---

## Kurulumdan sonra

Geliştirmeye başlarken okunacak yer burası değil:

- **[guides/README.md](guides/README.md)** — görev → rehber tablosu, yeni feature checklist'i
- **[guides/AGENTS.md](guides/AGENTS.md)** — AI ajanları için bağlayıcı kurallar
- **[guides/project.md](guides/project.md)** — hangi sistem nerede

---

## AI ajanı için yürütme kuralları

Bu dosyayı bir ajan okuyorsa:

1. **Durumu önce oku** — `AppConfig` bayrakları, `lib/firebase_options.dart`
   hâlâ placeholder mı, `android/key.properties` var mı. Kullanıcıya zaten
   yaptığı şeyi sorma.
2. **Soruları adım başına tek seferde sor.**
3. **Yalnızca bayrak/yapılandırma değiştir.** Ekranlar, guard'lar ve servisler
   bayraklara göre kendini kurar; kod silip eklemek tekrarlanabilir değildir.
4. **İnteraktif komutları sen çalıştırma** — `flutterfire configure`,
   `firebase login`, `keytool -genkey` parola/oturum ister. Kullanıcıya ver.
5. **Sır isteme, saklama, yazma.** Keystore parolası vb. senin elinden geçmez;
   alanı boş bırak, kullanıcı doldursun.
6. **Konsol adımlarını eksiksiz ver.** Atlanan bir adım özelliğin *sessizce*
   çalışmamasına yol açar — en pahalı hata sınıfı budur.
7. **Sonunda özetle:** açılan bayraklar, kullanıcının yapması gerekenler,
   ertelenen adımlar.
