# Android Release İmzalama — AI Yönergesi

> Bu dosya **AI ajanı için talimattır**. Kullanıcı "release imzası kur",
> "keystore oluştur", "Play'e yükleyeceğim" dediğinde bu akışı yürüt.
> Kaynak: <https://docs.flutter.dev/deployment/android>

Template şu an **debug anahtarıyla** imzalıyor (`build.gradle.kts` →
`signingConfig = signingConfigs.getByName("debug")`). Bu haliyle Play'e
yüklenemez.

## 🔒 Sert kurallar — bunlara uymadan devam etme

1. **Parolayı sen görmeyeceksin, yazmayacaksın, soramazsın.** `keytool`
   parolaları interaktif sorar. Komutu kullanıcıya ver, o çalıştırsın.
2. **Parolayı komut satırına gömme.** `-storepass`/`-keypass` bayrakları
   parolayı shell geçmişine ve process listesine düşürür.
3. **Keystore repo dışında durur.** İçeri koyulursa bir gün commit edilir.
   Öneri: `~/keys/<proje>-upload.jks`.
4. **`android/key.properties` asla commit edilmez** — `.gitignore`'da,
   öyle kalmalı.
5. **Keystore kaybolursa uygulama güncellenemez.** Play'e yüklenen ilk sürüm
   o anahtara bağlanır. Yedeği olmadan çıkılmaz.

---

## Adım 1 — Sor

**S1 — Release imzası şimdi kurulsun mu?**
Yalnızca Play'e/TestFlight'a yükleyecekse gerekli. Sadece geliştirme
yapıyorsa gerekmez, debug imzası yeter.

**S2 — Keystore nereye?**
Repo **dışında** bir yol iste. Varsayılan öner: `~/keys/<proje>-upload.jks`.
Klasör yoksa oluştur (`mkdir -p ~/keys`) — bu güvenli, sen yapabilirsin.

**S3 — Mevcut bir keystore var mı?**
Varsa yenisini **oluşturma**; yolunu al ve Adım 3'e geç. Yayınlanmış bir
uygulamanın anahtarı asla değiştirilemez.

---

## Adım 2 — Keystore'u kullanıcı oluştursun

Bu komutu **kullanıcıya ver**, sen çalıştırma:

```bash
keytool -genkey -v \
  -keystore ~/keys/<proje>-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Komut sırayla soracak: keystore parolası, ad-soyad, birim, kurum, şehir, ülke
kodu, sonra anahtar parolası (Enter'a basarsa keystore parolasıyla aynı olur).

Kullanıcıya söyle:
- **`-validity 10000`** (~27 yıl) bilinçlidir. Anahtar süresi dolarsa
  uygulama bir daha güncellenemez.
- **İki parolayı da bir parola yöneticisine kaydetsin.** Kurtarma yolu yok.
- **Keystore dosyasının yedeğini alsın** (parola yöneticisi eki ya da şifreli
  yedek). Diski giderse uygulaması gider.

---

## Adım 3 — `android/key.properties` oluştur

Dosyayı **sen oluştur**, ama parola satırlarını **boş bırak** — kullanıcı
kendi doldurur:

```properties
storePassword=
keyPassword=
keyAlias=upload
storeFile=/Users/<kullanici>/keys/<proje>-upload.jks
```

`storeFile` **mutlak yol** olmalı. Kullanıcıya "iki parola satırını sen
doldur, ben görmüyorum" de.

`.gitignore` kontrolü (zaten olmalı):

```bash
grep -q "android/key.properties" .gitignore && echo "✓ gitignore tamam" || echo "✗ EKLE"
```

---

## Adım 4 — `build.gradle.kts`'i bağla

`android/app/build.gradle.kts` içinde, `android { }` bloğundan **önce**:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

`android { }` içine:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        // `key.properties` yoksa (ör. CI, yeni klon) debug'a düş —
        // aksi halde build "keystore not found" ile kırılır.
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

Mevcut `signingConfig = signingConfigs.getByName("debug")` satırını ve
üstündeki TODO yorumunu **kaldır**.

---

## Adım 5 — Doğrula

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

İmzayı doğrula:

```bash
keytool -list -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Debug sertifikası (`CN=Android Debug`) görünüyorsa `key.properties`
okunmamıştır — yolu ve parolaları kontrol ettir.

---

## Adım 6 — Google girişi kullanılıyorsa SHA parmak izleri

**Bu adım atlanırsa uygulama debug'da çalışır ama Play'den indirilince Google
girişi çalışmaz.** En sık gözden kaçan hata budur.

Release anahtarının parmak izleri:

```bash
keytool -list -v -keystore ~/keys/<proje>-upload.jks -alias upload
```

`SHA1` ve `SHA-256` satırlarını Firebase Console → Project settings → Android
app → "Add fingerprint" ile ekle.

**Play App Signing kullanılıyorsa** (Play'in varsayılanı): Play Console →
Setup → App signing → **App signing key certificate**'in SHA'ları da
eklenmelidir. Play uygulamayı kendi anahtarıyla yeniden imzalar; senin upload
anahtarın kullanıcıya ulaşan sürümü imzalamaz.

SHA ekledikten sonra **`google-services.json`'ı yeniden indir** — eski dosya
yeni OAuth client'ı içermez.

Ayrıntı: [`auth_setup.md`](auth_setup.md) → Google ile giriş.

---

## Adım 7 — Özetle

Kullanıcıya tek ekranda ver:
- Keystore nereye kondu, yedeği alındı mı
- `key.properties`'e parolaları doldurması gerektiği
- Google girişi varsa hangi SHA'ların nereye eklendiği/eklenmesi gerektiği
- Play App Signing SHA'sının **yayından sonra** eklenmesi gerektiği

## Sık karşılaşılan arızalar

| Belirti | Sebep | Çözüm |
|---|---|---|
| `Keystore file not found` | `storeFile` göreli yol ya da yanlış | Mutlak yol yaz |
| `Cannot recover key` | `keyPassword` yanlış | İki parolayı da kontrol et |
| AAB debug sertifikasıyla imzalı | `key.properties` okunamadı | Dosya `android/` altında mı, yol doğru mu |
| Play'den inince Google girişi yok | Play App Signing SHA'sı eklenmemiş | Play Console'daki SHA'ları ekle + json yenile |
| Play "anahtar eşleşmiyor" | Farklı keystore ile imzalandı | İlk yayındaki anahtar zorunlu — kayıpsa Play destek |
