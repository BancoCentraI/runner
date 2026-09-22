# Yeni Projeye Uyarlama (Customization)

> Bu doküman template'i **klonlayıp kendi projesine uyarlayan kullanıcı** içindir.
> Önce [`setup_after_clone.md`](setup_after_clone.md) adımlarını tamamla, sonra buraya dön.

Post-clone kurulum bittikten sonra template'i kendi projene çevirmek için:

1. `pubspec.yaml` içindeki `name` alanını değiştir.
2. Paket adını proje genelinde güncelle (`akillisletme` → yeni ad).
3. `assets/translations/` içindeki string'leri güncelle.
4. `AppString` içindeki store URL'lerini doldur (bkz. [settings_and_urls.md](settings_and_urls.md)).
5. `home_background.dart` içindeki animasyon metnini değiştir/özelleştir.
6. `app_theme_variant.dart` içinden gereksiz renk varyantlarını çıkar.
7. Onboarding adım içeriklerini güncelle.
8. **Android native modülleri** — aşağıdaki 7 kurulum sorusunu yanıtlayarak widget ve overlay'i kendi veri modeline uyarla.
9. `AppSemanticKeys` içindeki test kimliklerini kendi ekranlarına göre güncelle (`lib/product/const/app_semantic_keys.dart`).
10. İstersen `.claude/skills/starter-*` ve `.claude/agents/starter-*` isimlerindeki `starter-` önekini kendi proje adınla değiştir (`doc/guides/AGENTS.md` → "Skill'ler" tablosunu da güncelle).
11. `./script/general.sh` çalıştır.
12. Feature eklemeye başlamak için [`README.md`](README.md) checklist'ini takip et.

---

## 🤖 Android Modülleri Kurulum Soruları

Bu repo klonlandığında ve kullanıcı geliştirmeye başlamadan önce, aşağıdaki soruları kullanıcıya sor. Varsayılanları belirt ve kullanıcının kendi projesine göre özelleştirmesine yardımcı ol.

**Soru 1 — Veri tipi**
Sayaç (Int) yerine ne saklamak istiyorsun?
- Cevaba göre `SharedPreferences` key'ini, `MethodChannel` metodlarını ve widget/overlay layout metin alanlarını güncelle.
- Varsayılan: `"counter"` (Int)

**Soru 2 — Widget başlığı**
Ana ekran widget'ının başlık metni ne olsun?
- `res/layout/widget_home.xml` → `tv_widget_title` TextView'ının `android:text` alanını güncelle.
- Varsayılan: `"Sayaç"`

**Soru 3 — Overlay başlığı**
Yüzen penceredeki başlık metni ne olsun?
- `res/layout/overlay_window.xml` → ilk `TextView`'ın `android:text` alanını güncelle.
- Varsayılan: `"Sayaç"`

**Soru 4 — Bildirim metni**
Yüzen pencere arka planda çalışırken gösterilen bildirim metni ne olsun?
- `OverlayService.kt` → `buildNotification()` içindeki `setContentTitle(...)` değerini güncelle.
- Varsayılan: `"Uygulama arka planda çalışıyor"`

**Soru 5 — MethodChannel adları**
Flutter–Kotlin arasındaki channel adlarını değiştirmek istiyor musun?
- `MainActivity.kt`'deki `OVERLAY_CHANNEL` ve `COUNTER_CHANNEL` sabitlerini ve Flutter tarafındaki `MethodChannel(...)` çağrılarını (`android_modules_view.dart`) güncelle.
- Varsayılan: `"counter"`, `"overlay_permission"`

**Soru 6 — Overlay butonları**
Yüzen penceredeki buton seti yeterli mi, yoksa buton eklemek/çıkarmak istiyor musun?
- `res/layout/overlay_window.xml` layout + `OverlayService.kt` → `bindViews()` metodunu güncelle.
- Varsayılan: `−`, `Sıfırla`, `+`, `↗ (uygulamayı aç)`, `✕ (kapat)`

**Soru 7 — Demo sayfası**
`android_modules_view.dart` sadece bir demo/izin sayfasıdır. Bu sayfayı kendi UI'ına dönüştürmek mi istiyorsun, yoksa kaldırmak mı?
- Kaldırılırsa: `app_router.dart`'tan `AndroidModulesRoute`'u ve `home_view.dart`'tan ilgili butonu da sil.

---

## Native splash

Açılış animasyonunu kendi logona/markanla değiştirmek için: [`native_splash.md`](native_splash.md).
