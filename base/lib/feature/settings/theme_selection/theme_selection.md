# Theme Selection (Tema & Kişiselleştirme)

Tam sayfa tema kişiselleştirme deneyimi. Ayarlar > Tema tile'ından açılır
(`/settings/theme`). Eski `ThemeSelectionDialog` bu sayfayla değiştirildi.

Renk + nötr tema + custom seed + Material You + kontrast + mod + presetleri
**canlı önizlemeyle** tek yerden sunar. Her etkileşim `ThemeCubit` üzerinden
anında uygulanır ve `SharedCache`'e kalıcı yazılır.

---

## Sayfada ne var (yukarıdan aşağıya, birebir)

Sayfa bir `Scaffold` + `AppBar` (başlık: `theme.title`) ve `ThemeCubit` dinleyen
bir `ListView`'dan oluşur. Bölümler sırayla:

### 1. Canlı önizleme kartı — `ThemePreviewCard`
Aktif temayı gösteren kart. İçeriği:
- Üstte örnek **AppBar şeridi** (`colorScheme.primary` zemin, menü + başlık + üç nokta ikonları).
- **Başlık** (`theme.previewHeadline`) + **açıklama metni** (`theme.previewBody`).
- Bir **FilledButton** + bir **OutlinedButton** (her ikisi `theme.previewAction`).
- Açık konumda bir **Switch**.
- İki **Chip** (`secondaryContainer` ve `tertiaryContainer` renkli).

Amaç: seçim değiştiğinde temanın gerçek bileşenlerde nasıl göründüğünü
uygulamadan çıkmadan göstermek. Sayfanın tamamı zaten aktif temayla çizilir.

### 2. Renkler — `theme.sectionColors`
`Wrap` içinde renk dairesi kartları (`ThemeSwatch`):
- **8 seed renk** (`AppThemeCatalog.colors`): Purple, Blue, Green, Orange, Red,
  Black, Teal, Indigo. Dokununca `cubit.selectTheme(id)`.
- **Custom** kartı (palet ikonlu): dokununca `CustomColorSheet` açılır. Seçiliyse
  daire seçilen seed rengini gösterir.

Seçili kartın etrafında renkli border + daire içinde ✓ ikonu (kontrastı
`estimateBrightnessForColor` ile otomatik: açık renkte siyah, koyuda beyaz).

### 3. Nötr — `theme.sectionNeutral`
`Wrap` içinde nötr/özel tema kartları (`AppThemeCatalog.neutrals`):
- **Monochrome** (gri daire) → `dynamicSchemeVariant.monochrome` ile gerçek gri palet.
- **AMOLED** (siyah daire) → dark modda surface'ler saf siyah (`#000000`).

### 4. Sistem renkleri (Material You) — `theme.systemColors` *(yalnızca Android)*
`SwitchListTile` (duvar kağıdı ikonu). Başlık `theme.systemColors`, alt metin
`theme.systemColorsDesc`. Açıkken duvar kağıdından üretilen sistem renkleri
kullanılır (`setUseSystemColors`). Bir renk/tema seçilince otomatik kapanır.
Android dışında bu bölüm hiç gösterilmez.

### 5. Kontrast — `theme.contrast`
İki seçenekli `SegmentedButton`:
- **Standart** (`theme.contrastStandard`) → `contrastLevel = 0`
- **Yüksek** (`theme.contrastHigh`) → `contrastLevel = 1`

`setContrastLevel` ile seed ve custom temalara uygulanır (erişilebilirlik).

### 6. Mod — `theme.mode`
Üç seçenekli `SegmentedButton`: **Sistem / Açık / Koyu**
(`settings.themeModeSystem/Light/Dark` anahtarları). `setThemeMode`.

### 7. Presetler — `theme.presets`
`Wrap` içinde preset kartları (`ThemePreset.all`, parıltı ikonlu). Renk + modu
**tek dokunuşla** uygular (`applyPreset`):
- **Minimal** = monochrome + light
- **Ocean** = blue + system
- **Sunset** = orange + dark
- **AMOLED** = amoled + dark

Bir preset, aktif `themeId` + `themeMode` ile birebir eşleşiyorsa seçili görünür.

---

## Custom renk seçici — `CustomColorSheet`
Bottom sheet (drag handle + `theme.pickColor` başlığı). Harici paket kullanmadan
HSV slider'larıyla renk üretir; `fromSeed` bu renkten tam M3 paletini kurar.
- Üstte **canlı önizleme bandı** (seçilen renk).
- Üç gradyan slider: **Ton** (`theme.hue`, 0–360), **Doygunluk**
  (`theme.saturation`), **Parlaklık** (`theme.brightnessLevel`).
- **Uygula** (`theme.apply`) → `cubit.setCustomSeed(color)` + sheet kapanır.

---

## İçerdiği yapılar (dosyalar)

| Dosya | Görev |
|-------|-------|
| `theme_selection_view.dart` | Sayfa iskeleti + bölümler (önizleme, renkler, nötr, sistem renkleri, kontrast, mod, presetler) |
| `widget/theme_preview_card.dart` | Aktif temayı gösteren canlı önizleme kartı |
| `widget/theme_swatch.dart` | Ortak renk dairesi + etiket kartı; seçili ✓ kontrastı otomatik |
| `widget/custom_color_sheet.dart` | Paketsiz HSV slider'lı custom seed renk seçici (bottom sheet) |

State/mimari `lib/product/theme/` altında (bkz. `THEME.md`):
- `state/theme_state.dart` — `themeId`, `customSeedArgb`, `schemeVariant`, `contrastLevel`, `useSystemColors`, `themeMode`
- `state/theme_cubit.dart` — `selectTheme`, `setCustomSeed`, `setContrastLevel`, `setUseSystemColors`, `setThemeMode`, `applyPreset`
- `spec/theme_spec.dart` — `SeedThemeSpec` / `CustomSeedThemeSpec` / `RawSchemeThemeSpec` (`schemeFor(Brightness)`)
- `app_theme_option.dart` — katalog (8 seed + nötr/AMOLED) + `AppThemeIds`
- `theme_preset.dart` — renk+mod presetleri

## Kalıcılık

`SharedKeys`: `themeVariant` (themeId), `theme` (mod), `themeCustomSeed` (ARGB int),
`themeSchemeVariant`, `themeContrast` (double), `themeUseSystemColors` (bool).
Eski `themeVariant` string değerleri yeni `themeId`'ye doğrudan uyar (göçsüz).

## Localization

Tüm metinler `assets/translations/*.json` içindeki `theme.*` (ve mod için
`settings.themeMode*`) anahtarlarından gelir. Anahtar değişiminde
`locale_keys.g.dart` `-s en.json` ile yeniden üretilmeli (bkz. `THEME.md`).

## Notlar

- Material You (sistem renkleri) yalnızca Android'de gösterilir; `main.dart`'taki
  `DynamicColorBuilder` üzerinden uygulanır.
- AMOLED teması dark modda surface'leri saf siyaha çeker (`RawSchemeThemeSpec`).
- Custom seed renk seçici bağımlılık eklemez (HSV slider'lar Material ile).
- v3 (Hacker/Terminal modu, PRO kapısı) henüz uygulanmadı; `ThemeSpec.fontFamily`
  ve `RawSchemeThemeSpec` o aşama için hazır bırakıldı.
