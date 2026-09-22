# Tema & Kişiselleştirme

> **Durum:** ✅ **v1 + v2 uygulandı** (2026-06-11). v3 (Hacker/Terminal + PRO) ertelendi.
> **Uygulama:** `lib/feature/settings/theme_selection/` (UI) + `lib/product/theme/`
> (mimari). Bkz. `lib/product/theme/THEME.md` ve feature `theme_selection.md`.
> **Mevcut altyapı:** `lib/product/theme/` — M3 seed-based, 8 varyant × light/dark,
> `AppThemeColors` ThemeExtension, `ThemeCubit` (SP'ye kalıcı).
> **Kaynak:** `fake_gps/doc/guides/theme-personalization.md` planının bu template'e
> (`clean_start`) uyarlanmış hali. Harita stili ve PRO/token narrative'i bu projede
> yok — ilgili maddeler düşürüldü veya opsiyonel not olarak bırakıldı.

## Vizyon
Tema'yı basit bir renk-seçim dialog'undan, kullanıcıya **kimlik** kazandıran tam
bir **kişiselleştirme** deneyimine çıkarmak. Renk + mod + tipografi tek yerden,
canlı önizlemeyle. Hem yeni kullanıcıyı bağlar (onboarding "wow") hem mevcut
kullanıcıyı tutar (retention).

## Neden
- Renk seçimi en sık dokunulan kişiselleştirme — düşük efor, yüksek görünür değer.
- Nötr (siyah/gri) temalar "renk istemeyen" kitleyi + OLED pil-duyarlı kullanıcıyı kazanır.
- Bir boilerplate olarak: yeni projeler için hazır, genişletilebilir tema sistemi.

---

## Mevcut durum (clean_start'ta ne var)
- `AppThemeVariant` enum → **8 seed renk** (purple/blue/green/orange/red/black/teal/indigo).
- `ColorScheme.fromSeed(seed, brightness)` → M3 uyumlu palet (`app_theme_variant.dart`).
- `AppThemeColors` ThemeExtension → semantic renkler (scoreGold/scoreRed/...), `lerp` dahil.
- `ThemeCubit` (plain `Cubit`, Freezed değil) → `ThemeState { variant, themeMode }`,
  SharedPreferences key'leri: `SharedKeys.themeVariant`, `SharedKeys.theme`.
- Seçim **dialog**'da (`ThemeSelectionDialog`): Wrap renk grid + `SegmentedButton` (System/Light/Dark).
- `theme_tile.dart` → dialog açar (trailing renk dairesi).
- `parts/text_theme.dart` mevcut → hacker monospace için tipografi slot'u hazır.

### Doküman ↔ gerçek farkları (uyarlama notları)
| Konu | Orijinal plan | clean_start |
|---|---|---|
| Variant sayısı | 5 seed | **8 seed** zaten var |
| Detay sayfa scaffold | `SettingsDetailScaffold` | Yok — `language_selection_view` deseni: düz `Scaffold + AppBar + AppPaddings.page` |
| Route | `/theme` | `TypedGoRoute` nested (`/settings/theme` eklenecek) |
| Harita stili (`map_type`) | var | **Yok** → F maddesi ve preset harita kısmı düşer |
| PRO / token | var | **Template** → H maddesi opsiyonel/ileriye dönük |

## Mimari değişiklik (önkoşul — kritik)
Şu an varyant **yalnızca bir seed** veriyor. Yeni temalar (hacker, monochrome,
custom seed, AMOLED) seed'le üretilemez veya tam custom `ColorScheme` ister. Bu
yüzden varyant modeli genişletilmeli:

- Varyant artık ya **seed** (M3 fromSeed) ya **hazır ColorScheme** (hacker/AMOLED)
  ya da **custom seed + scheme-variant** (monochrome/neutral/vibrant + contrastLevel)
  sağlayabilmeli. Öneri: `ThemeSpec` soyutlaması — `ColorScheme schemeFor(Brightness)`
  döndürür; alt tipler: `SeedThemeSpec`, `CustomSeedThemeSpec`, `RawSchemeThemeSpec`.
- **Kalıcılık:** tek `themeVariant` string key yetmez. SP'de
  `{ themeId, customSeedArgb?, schemeVariant, contrastLevel, amoled, useSystemColors }`
  tut. `ThemeState` bunları taşır (mevcut plain class genişler; Freezed'e geçmek opsiyonel).
- Geri uyum: mevcut `themeVariant` SP değeri (`"purple"` vb.) yeni `themeId`'ye maplenir.
  `AppThemeVariant.fromKey` zaten `orElse: purple` veriyor → göçsüz, güvenli.
- `theme.dart` içindeki `_darkSchemeFor/_lightSchemeFor` → `spec.schemeFor(brightness)`'a
  bağlanır. `AppThemeColors` (semantic) extension tüm temalarda korunur; sadece scheme değişir.

---

## Özellikler

### A. Seçim sayfası (dialog → tam sayfa)
- `ThemeSelectionDialog` → **tam sayfa** (`/settings/theme` nested `TypedGoRoute`,
  `slideRightTransition`, `language_selection_view` deseninde `Scaffold + AppBar`).
- `theme_tile.dart` `onTap` → dialog yerine route push (chevron — diğer tile'larla tutarlı).
- **Canlı önizleme kartı:** örnek AppBar + buton + switch + metin + kart; seçim
  değişince anında güncellenir (kullanıcı uygulamadan çıkmadan görür).

### B. Renk paleti — genişletilmiş
- Mevcut 8 renge istenirse yeni seed'ler eklenebilir (pink, amber...).
- **Custom seed renk seçici:** renk çarkından istediğin renk → `fromSeed` tam palet
  üretir. Düşük efor, yüksek kişiselleştirme. (SP'de ARGB int → `CustomSeedThemeSpec`.)
- **Material You (Android 12+):** `dynamic_color` paketi → duvar kağıdından sistem
  renkleri. "Sistem renklerini kullan" toggle'ı. Premium hissi, çok popüler.

### C. Nötr & özel temalar
- **Monochrome / Neutral:** `ColorScheme.fromSeed(..., dynamicSchemeVariant:
  DynamicSchemeVariant.monochrome | .neutral)` → gerçek siyah-beyaz / gri tema.
  - Light default adayı: nötr **gri** tema.
  - Dark default adayı: nötr **siyah** tema.
  - (Not: mevcut `black` variant seed-bazlı; gerçek monochrome için `dynamicSchemeVariant`.)
- **AMOLED Pure Black:** dark mod için ayrı "saf siyah" seçeneği (surface = #000000)
  → OLED pil tasarrufu + premium görünüm. `dark.copyWith(surface: Colors.black, ...)`.
- **Hacker / Terminal modu:** tam custom `ColorScheme` — siyah zemin + neon yeşil
  primary + **monospace font** (`parts/text_theme.dart`'a font ailesi girer).

### D. Kontrast & erişilebilirlik
- **Kontrast seviyesi:** `ColorScheme.fromSeed(contrastLevel: -1..1)` → "Standart /
  Yüksek kontrast" seçeneği. Erişilebilirlik + Play kalite puanı.

### E. Mod (themeMode)
- Mevcut System/Light/Dark korunur (`SegmentedButton`).
- Varyant artık light/dark'a göre farklı palet üretiyor zaten (fromSeed brightness).

### F. Harita stili entegrasyonu
- **Bu projede yok** (clean_start'ta harita modülü bulunmuyor). Map içeren bir
  projeye taşınırsa: tema değişince "harita stilini de uyumla?" önerisi eklenebilir.

### G. Tema presetleri (bundle)
- Renk + mod'u **tek dokunuşla** birleştiren adlandırılmış presetler (harita yok):
  - **Minimal** = nötr gri + light
  - **Okyanus** = mavi + system
  - **AMOLED** = siyah + dark
  - **Hacker** = neon yeşil + dark + monospace
- Onboarding'i mükemmelleştirir: yeni kullanıcı "Hacker" der, her şey set olur.

### H. PRO / token kapısı (opsiyonel, ileriye dönük)
- Template'te aktif değil. İleride monetize edilen bir projede: hacker modu,
  custom seed, AMOLED, Material You premium'a alınabilir. Şimdilik sadece mimari
  hook olarak not edilir (`ThemeSpec` zaten esnek).

---

## Fazlama

> ✅ v1 ve v2 tamamlandı. Aşağıdaki maddeler uygulanan kapsamı belgeler.
> Tek sapma: custom seed için `dynamicSchemeVariant` seçici UI'ı eklenmedi
> (state'te tutuluyor, varsayılan `tonalSpot`); monochrome/neutral zaten ayrı
> nötr tema seçenekleri olarak sunuluyor.

### v1 — Foundation (sayfa + nötr temalar + altyapı) ✅
1. **Mimari refactor:** `ThemeSpec` soyutlaması (seed | custom seed | raw scheme),
   `ThemeState`/`ThemeCubit` genişletme, SP şeması (`themeId` + flag'ler), geri uyum maplemesi.
2. Dialog → **tam sayfa** (`/settings/theme`, nested `TypedGoRoute`) + **canlı önizleme**.
   `theme_tile.dart` route push'a çevrilir.
3. **Nötr temalar:** monochrome gri (light default), siyah (dark default) + **AMOLED**.
4. **Variant isimleri lokalizasyonu:** şu an `label` hard-coded İngilizce (`'Purple'`...)
   → `LocaleKeys.theme_colorPurple/...` + nötr/hacker isimleri (mevcut dil dosyaları).
5. Kontrast fix: seçili ✓ ikonu rengini `ThemeData.estimateBrightnessForColor` ile
   seç (şu an sabit beyaz — açık seed'lerde okunmaz).

### v2 — Kişiselleştirme ✅
1. **Custom seed renk seçici** (bağımsız HSV slider'lı bottom sheet → `CustomSeedThemeSpec`, SP'de ARGB).
2. **Material You** (`dynamic_color`, Android 12+, `DynamicColorBuilder`).
3. **Kontrast seviyesi** toggle (Standart / Yüksek).
4. **Tema presetleri** (renk + mod bundle).

### v3 — Kimlik (ertelendi)
1. **Hacker / Terminal modu** (custom `ColorScheme` + monospace tipografi).
2. **PRO/token kapısı** (opsiyonel, monetize edilen projeler için hook).

---

## Teknik notlar / paketler
- `dynamicSchemeVariant: DynamicSchemeVariant.{monochrome,neutral,vibrant,...}` —
  Flutter `ColorScheme.fromSeed` parametresi (nötr/hacker temaları için).
- `contrastLevel` — `ColorScheme.fromSeed` parametresi (-1..1).
- [`dynamic_color`](https://pub.dev/packages/dynamic_color) — Material You.
- AMOLED: dark scheme'i `copyWith(surface: Colors.black, ...)` ile saf siyaha çek.
- Hacker monospace: `parts/text_theme.dart`'e font ailesi (örn. JetBrains Mono / Fira Code asset).
- Tüm temalar `AppThemeColors` (semantic) extension'ını korur; sadece scheme değişir.

## Riskler / dikkat
- Custom/raw `ColorScheme`'lerde **kontrast/erişilebilirlik** elle kontrol gerekir
  (fromSeed otomatik sağlıyor, raw scheme sağlamıyor). Hacker temada okunabilirlik test et.
- Varyant kalıcılık şeması değişince **eski SP değerleriyle geri uyum** şart (göçsüz maple).
- Yeni feature kuralı: implementasyona geçince `lib/product/theme/THEME.md` güncellenmeli.

## Bağlantılı dokümanlar
- `lib/product/theme/` — mevcut altyapı (`THEME.md` dahil)
- `doc/guides/widget_and_theme.md` — widget/tema yerleşim kuralları
- `doc/guides/route_and_strings.md` — TypedGoRoute + EasyLocalization string ekleme
