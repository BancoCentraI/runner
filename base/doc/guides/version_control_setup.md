# Zorunlu Güncelleme Kurulumu (Remote Config) — AI Yönergesi

> Kullanıcı "zorunlu güncelleme", "sürüm kontrolü", "eski sürümü engelle"
> dediğinde bu akışı yürüt.

Kod hazır: `AppVersionSource` → `RemoteConfigService`, `VersionChecker`,
`SplashCubit` ve `_UpdateRequiredView`. Firebase kapalıyken
`StaticVersionSource` bağlanır ve güncelleme **hiç tetiklenmez**.

Önkoşul: [`auth_setup.md`](auth_setup.md) Adım 2 (Firebase projesi) tamamlanmış
ve `AppConfig.firebaseEnabled = true` olmalı.

---

## Adım 1 — Console'da anahtarları oluştur

Firebase Console → Remote Config → **iki ayrı parametre**:

| Parametre | Tip | Örnek |
|---|---|---|
| `version_ios` | String | `1.0.0` |
| `version_android` | String | `1.0.0` |

Sonra **Publish changes**. Yayınlanmazsa değerler cihaza inmez.

> ### Neden iki ayrı anahtar?
>
> İki mağaza ayrı hızda ilerler. Tek `version` anahtarı olsaydı: Android'e
> 2.0.7 çıkarıp değeri `2.0.7` yaptığında, App Store'da 2.0.7 **henüz
> yokken** iOS kullanıcıları da güncellemeye zorlanır ve indirecek sürüm
> bulunmadığı için **uygulamaya hiç giremez**. Geri dönüşü yeni bir Remote
> Config yayını gerektirir; o arada tüm iOS kullanıcıları kilitlidir.
>
> Kod, platform anahtarı tanımlı değilse eski tek `version` anahtarına düşer —
> geçiş dönemi için.

---

## Adım 2 — Kullanım kuralı

Değeri **mağazada gerçekten yayında olan** sürüme ayarla, yeni çıkardığına
değil. Sıra:

1. Yeni sürümü mağazaya yükle.
2. **İncelemeden geçip yayına çıkmasını bekle.**
3. O platformun Remote Config değerini yükselt.

Bu sıra bozulursa kullanıcılar var olmayan bir sürüme yönlendirilir.

Kullanıcıya ayrıca söyle:
- Değer `pubspec.yaml`'daki `version` alanının **build numarasız** kısmıyla
  karşılaştırılır (`2.0.0+15` → `2.0.0`).
- Karşılaştırma segment bazlıdır: `1.2.10 < 1.3.0` doğru sonuçlanır.
- Değer okunamazsa/boşsa güncelleme istenmez — kullanıcı kilitlenmez.

---

## Adım 3 — Store URL'leri

Güncelle butonu `AppString.appStoreUrl` / `AppString.playStoreUrl` adreslerini
açar. Boşsa buton hiçbir şey yapmaz.

→ [`settings_and_urls.md`](settings_and_urls.md)

---

## Adım 4 — Ağ gereksinimi

Uygulama açılışta veri çekiyorsa `SplashCubit(requiresNetwork: true)` yap
(`app_router.dart` → `SplashRoute`). O zaman bağlantı yokken kullanıcı boş
ekran yerine "tekrar dene" görür.

Template varsayılanı `false` — kutudan çıkan hali uzak kaynağa bağımlı değil.

---

## Adım 5 — Test

1. `pubspec.yaml` → `version` alanını geçici olarak düşür (ör. `0.0.1+1`).
2. `flutter run` → zorunlu güncelleme ekranı çıkmalı.
3. "Güncelle" mağazayı açmalı.
4. Sürümü geri al, ekran kaybolmalı.

Debug'da `minimumFetchInterval` sıfırdır, her açılışta taze çeker. Release'te
1 saattir — test ederken değişikliği hemen görmezsen sebebi budur.

## Sık karşılaşılan arızalar

| Belirti | Sebep | Çözüm |
|---|---|---|
| Ekran hiç çıkmıyor | Parametre publish edilmemiş | Console'da Publish changes |
| Değişiklik hemen yansımıyor | Release'te 1 saat cache | Bekle ya da debug'da test et |
| iOS kullanıcıları kilitli | Tek `version` anahtarı kullanılmış | `version_ios`/`version_android`'e geç |
| Güncelle butonu bir şey yapmıyor | Store URL boş | `AppString`'i doldur |
