# Ödeme / Abonelik Kurulumu (RevenueCat) — AI Yönergesi

> Kullanıcı "ödeme ekle", "abonelik kur", "premium yapalım", "RevenueCat"
> dediğinde bu akışı yürüt.

Kod hazır: `PurchaseService` (+ RevenueCat impl), `SubscriptionCubit`,
`PremiumGuard`, modeller. Anahtar verilmemişken altyapı **no-op** çalışır —
herkes ücretsiz sayılır, uygulama etkilenmez.

Ödeme **Firebase'den bağımsızdır**; Firebase kurulu olmasa da çalışır. Ama
girişle birlikte kullanılıyorsa UID bağı kritiktir (aşağıda).

---

## Adım 1 — Sor

**S1 — Ne satılacak?** Abonelik (aylık/yıllık) mi, tek seferlik ömür boyu mu,
ikisi de mi?

**S2 — Hangi platformlar?** Android, iOS, ikisi.

**S3 — Ücretsiz deneme olacak mı?** Süresi mağazadan yönetilir, kodda değil.

**S4 — Hangi özellikler premium olacak?** Cevaba göre `PremiumFeature`
enum'ını (`lib/product/service/subscription/subscription_models.dart`)
güncelle — şu an örnek iki değer var.

---

## Adım 2 — Kullanıcının mağaza tarafında yapacakları

Bunları sen yapamazsın; sırayla ver ve tamamlanmasını bekle.

### Google Play (Android)

1. Play Console → uygulamayı oluştur, paket adı `applicationId` ile aynı olsun.
2. **Uygulamanın en az bir kez yayınlanmış olması gerekir** (kapalı test bile
   olur). Yayınlanmamış uygulamada ürünler API'den gelmez — "offering boş"
   sorununun bir numaralı sebebi budur.
3. Monetize → Subscriptions (veya In-app products) → ürünleri oluştur, **aktif
   et**.
4. Play Console → API access → RevenueCat için service account bağla.

### App Store (iOS)

1. App Store Connect → uygulamayı oluştur.
2. **Anlaşmalar, Vergi ve Bankacılık** bölümünü tamamla. Eksikse ürünler
   görünmez — sessiz ve çok yaygın bir tuzak.
3. Abonelik grubu + ürünleri oluştur.
4. App-Specific Shared Secret üret → RevenueCat'e gir.
5. Sandbox test kullanıcısı oluştur (gerçek Apple ID ile test **edilmez**).

### RevenueCat

1. Proje oluştur, Android ve/veya iOS uygulamasını ekle.
2. Ürünleri mağazadan **import et**.
3. **Entitlement oluştur** — kimliği `AppConfig.premiumEntitlementId` ile aynı
   olmalı (varsayılan: `premium`). Ürünleri bu entitlement'a bağla.
4. **Offering** oluştur ve `current` yap. Offering `current` değilse
   `fetchOffering()` boş döner.
5. API Keys → **public SDK key**'leri al (Google için `goog_...`, Apple için
   `appl_...`).

---

## Adım 3 — Anahtarları bağla

Anahtarlar `--dart-define` ile verilir, kodda tutulmaz:

```bash
flutter run \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=REVENUECAT_IOS_KEY=appl_xxx
```

Tekrar yazmamak için proje kökünde `dart_defines.json` oluştur:

```json
{
  "REVENUECAT_ANDROID_KEY": "goog_xxx",
  "REVENUECAT_IOS_KEY": "appl_xxx"
}
```

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Dosyayı `.gitignore`'a ekle. (Public SDK key teknik olarak sır değildir —
istemciye dağıtılır — ama repoda tutmamak doğru alışkanlıktır.)

IDE için: VS Code `launch.json` → `"toolArgs"`, Android Studio → Run
Configuration → Additional run args.

---

## Adım 4 — Kod tarafı

`AppConfig.isPurchaseConfigured` anahtar geldiği anda `true` olur; locator
otomatik olarak `RevenueCatPurchaseService`'e geçer. **Elle bayrak çevirmeye
gerek yok.**

Yapılacaklar:

1. `PremiumFeature` enum'ını gerçek özelliklerle doldur.
2. Kilitlenecek yerleri sar:
   ```dart
   PremiumGuard(
     feature: PremiumFeature.advancedFeature,
     onLockedTap: () => const PaywallRoute().push<void>(context),
     child: const AdvancedPanel(),
   )
   ```
3. Ayarlar'a **"Satın alımları geri yükle"** ekle:
   ```dart
   onTap: context.read<SubscriptionCubit>().restore,
   ```
   ⚠️ **iOS'ta bu buton olmadan uygulama reddedilir** (App Store 3.1.1).
4. Paywall ekranında `fetchOffering()` boş dönerse "yakında" durumu göster —
   hata gösterme. Ürün henüz import edilmemiş olabilir.

---

## Adım 5 — UID bağı (giriş varsa)

`AuthSideEffects` bunu zaten yapıyor: oturum açılınca
`Purchases.logIn(uid)`, kapanınca `logOut()`.

Kullanıcıya **neden önemli** olduğunu söyle: bu bağ olmadan abonelik cihaza
bağlı kalır; kullanıcı telefon değiştirdiğinde **ödediği aboneliği kaybeder**
ve destek talebi olarak geri döner. En sık görülen RevenueCat entegrasyon
hatası budur.

---

## Adım 6 — Test

**Android:** Play Console → kapalı test kanalına yükle, test hesabını
"License testing" listesine ekle. Test satın alımları ücretsizdir.

**iOS:** Sandbox hesabıyla cihazda test et. Simülatörde satın alma çalışmaz.

Doğrula:
1. Paywall planları ve **mağazadan gelen yerelleştirilmiş fiyatı** gösteriyor
   (fiyat kodda yazılı olmamalı).
2. Satın alma sonrası `PremiumGuard` kilidi açılıyor.
3. Satın almayı iptal → hata mesajı **gösterilmiyor** (iptal hata değildir).
4. Uygulamayı sil/kur → "Geri yükle" premium'u geri getiriyor.
5. Giriş yap → çıkış → başka hesapla gir → abonelik doğru hesapla geliyor.

---

## Sık karşılaşılan arızalar

| Belirti | Sebep | Çözüm |
|---|---|---|
| Offering boş | Uygulama hiç yayınlanmamış / ürün import edilmemiş / offering `current` değil | Play'de kapalı teste çık, RevenueCat'te import + current yap |
| iOS'ta ürün görünmüyor | Anlaşmalar/Vergi/Bankacılık tamamlanmamış | App Store Connect'te tamamla |
| Satın alma sonrası premium açılmıyor | Entitlement id uyuşmuyor | `AppConfig.premiumEntitlementId` ↔ RevenueCat entitlement |
| Cihaz değişince abonelik yok | UID bağı yok | `AuthSideEffects` bağlı mı kontrol et |
| Simülatörde satın alma başarısız | iOS'ta desteklenmiyor | Gerçek cihaz + sandbox hesabı |
| iOS reddi: "restore yok" | Geri yükle butonu eklenmemiş | Ayarlar'a ekle |
