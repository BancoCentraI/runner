# Theme System

## Mimari

Theme sistemi şu bileşenlerden oluşur:

1. **Tema Spec'i** (`ThemeSpec`) — bir temanın `ColorScheme schemeFor(Brightness)` üretme stratejisi. Alt tipler:
   - `SeedThemeSpec` — M3 seed varyantları (8 renk) + opsiyonel kontrast
   - `CustomSeedThemeSpec` — kullanıcı seed'i + `dynamicSchemeVariant` + `contrastLevel`
   - `RawSchemeThemeSpec` — tam kontrollü `ColorScheme` (AMOLED saf siyah; v3 hacker için hazır)
2. **Renk Varyantı** (`AppThemeVariant`) — 8 seed renk paleti
3. **Tema Kataloğu** (`AppThemeOption` / `AppThemeCatalog`) — seçim sayfasındaki hazır temalar (8 seed + nötr/AMOLED)
4. **Presetler** (`ThemePreset`) — renk + mod kombinasyonu (tek dokunuş)
5. **Tema Modu** (`ThemeMode`) — System / Light / Dark
6. **Material You** — `dynamic_color` ile sistem (duvar kağıdı) renkleri (Android 12+)
7. **Semantik Renkler** (`AppThemeColors`) — variant'tan bağımsız, dark/light duyarlı sabit renkler

## State Yönetimi

**`ThemeCubit`** → `ThemeState` emit eder.

`ThemeState` alanları:
- `themeId` → aktif tema kimliği (`purple`... / `monochrome` / `amoled` / `custom`)
- `customSeedArgb` → `custom` teması için seçilen seed (ARGB int)
- `schemeVariant` → custom/nötr temalarda `DynamicSchemeVariant`
- `contrastLevel` → -1..1 (0 = standart, 1 = yüksek)
- `useSystemColors` → Material You açık/kapalı
- `themeMode` → system/light/dark

`state.spec` resolve edilmiş `ThemeSpec`'i, `state.previewColor` tile/önizleme rengini verir.
Geriye dönük uyum için `state.variant` hâlâ bir `AppThemeVariant` döndürür.

```dart
// Hazır tema seç (seed veya nötr)
context.read<ThemeCubit>().selectTheme('blue');
context.read<ThemeCubit>().setVariant(AppThemeVariant.blue); // eşdeğer

// Custom seed
context.read<ThemeCubit>().setCustomSeed(const Color(0xFF00BCD4));

// Kontrast / Material You / mod
context.read<ThemeCubit>().setContrastLevel(1);
context.read<ThemeCubit>().setUseSystemColors(enabled: true);
context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);

// Preset
context.read<ThemeCubit>().applyPreset(ThemePreset.all.first);
```

## Persistence

| Veri | SharedKeys | Tip | Örnek |
|------|-----------|-----|-------|
| Tema kimliği | `themeVariant` | `String` | `"purple"`, `"amoled"`, `"custom"` |
| Custom seed | `themeCustomSeed` | `int` (ARGB) | `0xFF00BCD4` |
| Scheme variant | `themeSchemeVariant` | `String` | `"tonalSpot"` |
| Kontrast | `themeContrast` | `double` | `0.0`, `1.0` |
| Material You | `themeUseSystemColors` | `bool` | `true` |
| Tema modu | `theme` | `String` | `"system"`, `"dark"` |

Eski `themeVariant` string değerleri (`"purple"`...) doğrudan yeni `themeId`'ye uyar
— göçsüz geri uyum (`AppThemeVariant.fromKey` fallback: purple).

## MaterialApp Entegrasyonu

`main.dart` `DynamicColorBuilder` ile sarmalanır; sistem (Material You) şemaları
`AppTheme`'e geçirilir ve `useSystemColors` açıksa kullanılır:

```dart
final themeState = context.watch<ThemeCubit>().state;
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) => MaterialApp.router(
    themeMode: themeState.themeMode,
    theme: AppTheme.lightTheme(themeState, dynamicScheme: lightDynamic),
    darkTheme: AppTheme.darkTheme(themeState, dynamicScheme: darkDynamic),
    ...
  ),
);
```

## Dosya Yapısı

```
lib/product/theme/
├── THEME.md
├── app_theme_variant.dart       # Enum — 8 seed paleti
├── app_theme_option.dart        # Tema kataloğu (8 seed + nötr/AMOLED) + AppThemeIds
├── theme_preset.dart            # Renk+mod presetleri
├── app_theme_colors.dart        # ThemeExtension — semantik renkler
├── theme.dart                   # AppTheme giriş noktası (part files)
├── spec/
│   └── theme_spec.dart          # ThemeSpec + Seed/CustomSeed/RawScheme + amoledThemeSpec()
├── base/
│   ├── color_schemes.dart       # _resolveScheme (spec ↔ Material You)
│   ├── dark_theme.dart          # Dark ThemeData builder (fontFamily destekli)
│   └── light_theme.dart         # Light ThemeData builder (fontFamily destekli)
├── parts/
│   ├── text_theme.dart          # _buildTextTheme({fontFamily}) — Poppins + Inter
│   └── ...                      # appbar/button/card/chip/input/slider/switch
├── state/
│   ├── theme_cubit.dart         # ThemeCubit — tüm tema setter'ları
│   └── theme_state.dart         # ThemeState — zengin durum + spec/previewColor
└── widget/
    └── theme_setting_tile.dart  # Büyük gradient tile (tam sayfayı açar)
```

Tam sayfa seçim UI'ı **feature** tarafındadır:
`lib/feature/settings/theme_selection/` (bkz. `theme_selection.md`).

## Mevcut Temalar

**Seed renkler (8):** Purple `#7C4DFF`, Blue `#2196F3`, Green `#4CAF50`,
Orange `#FF9800`, Red `#E91E63`, Black `#212121`, Teal `#009688`, Indigo `#3F51B5`.

**Nötr / özel:** Monochrome (gri, `dynamicSchemeVariant.monochrome`),
AMOLED (dark'ta saf siyah surface), Custom (kullanıcı seed'i).

**Presetler:** Minimal (mono+light), Ocean (blue+system), Sunset (orange+dark),
AMOLED (amoled+dark).

## Tema Modu Seçenekleri

| Mod | Açıklama |
|-----|----------|
| System | Cihazın dark/light ayarını takip eder |
| Light | Her zaman açık tema |
| Dark | Her zaman koyu tema |

## Typography (TextTheme)

Tüm metin stilleri `_buildTextTheme({String? fontFamily})`'den gelir ve
`Theme.of(context).textTheme.*` ile erişilir. Varsayılan: Poppins (display/headline)
+ Inter (title/label/body). `fontFamily` verildiğinde tüm stiller `.apply()` ile
tek seferde override edilir — bu, tema spec'lerinin kendi tipografisini sağlamasına
olanak tanır (v3 hacker/terminal monospace bu mekanizmayı kullanacak).

| Stil | Font | Boyut | Ağırlık | Kullanım |
|------|------|-------|---------|----------|
| `displayLarge` | Poppins | 57 | w400 | Hero başlıklar |
| `displayMedium` | Poppins | 45 | w400 | Büyük başlıklar |
| `displaySmall` | Poppins | 36 | w400 | Orta başlıklar |
| `headlineLarge` | Poppins | 32 | w400 | Sayfa başlıkları |
| `headlineMedium` | Poppins | 28 | w400 | Bölüm başlıkları |
| `headlineSmall` | Poppins | 24 | w400 | Alt başlıklar |
| `titleLarge` | Inter | 22 | w500 | Kart/tile başlıkları |
| `titleMedium` | Inter | 16 | w500 | Buton label'ları, dialog başlıkları |
| `titleSmall` | Inter | 14 | w500 | Küçük başlıklar |
| `labelLarge` | Inter | 14 | w500 | Tab/segment label'ları |
| `labelMedium` | Inter | 12 | w500 | Section başlıkları |
| `labelSmall` | Inter | 11 | w500 | Chip/badge metinleri |
| `bodyLarge` | Inter | 16 | w400 | Ana içerik metni |
| `bodyMedium` | Inter | 14 | w400 | Genel metin, açıklama |
| `bodySmall` | Inter | 12 | w400 | Yardımcı metin |

### Kullanım

```dart
Text('Başlık', style: Theme.of(context).textTheme.headlineSmall)
// Yanlış — inline fontSize kullanma
```

## Semantik Renkler (AppThemeColors)

`ThemeExtension` ile variant'tan bağımsız, dark/light moda duyarlı semantik renkler.
Geçişlerde `lerp()` ile smooth interpolasyon.

| Renk | Light | Dark |
|------|-------|------|
| `scoreGold` | `#FFD700` | `#FFE066` |
| `scoreRed` | `#FF4757` | `#FF6B81` |
| `scoreGreen` | `#2ED573` | `#7BED9F` |
| `scoreBlue` | `#1E90FF` | `#70A1FF` |
| `scorePink` | `#FF6B81` | `#FF8FA3` |
| `toggleActive` | `#2ED573` | `#7BED9F` |
| `toggleInactive` | `#EF5350` | `#FF8A80` |

```dart
context.appColors.scoreGold        // kısa erişim (önerilen)
```

## Yeni Seed Variant Ekleme

1. `app_theme_variant.dart` enum'una yeni değer ekle (`key`, `label`, `seedColor`, `previewColor`).
2. `app_theme_option.dart`'taki `_seedLabelKey` switch'ine yeni case + ilgili
   `theme.name.<x>` çeviri anahtarını ekle.
3. Bu kadar — katalog/grid otomatik günceller, `ColorScheme.fromSeed` paleti üretir.

## Localization

Tema string'leri `assets/translations/*.json` içindeki `theme.*` ve `settings.*`
bloklarında. Değişiklik sonrası `locale_keys.g.dart` yeniden üretilmeli:

```bash
dart run easy_localization:generate -S assets/translations -s en.json \
  -O lib/product/init/language -o locale_keys.g.dart -f keys
```

> Not: `-s en.json` zorunlu — `en.json` tam anahtar setine sahip referans dosyadır.

## Kurallar

- **Inline `TextStyle(fontSize:)` / inline renk kullanma** — `textTheme.*`,
  `colorScheme.*`, `context.appColors.*` kullan.
- **Persistence** her zaman string/temel tip key ile (int index değil).
- **Yeni tema** eklenirken kontrast/erişilebilirlik kontrol et (raw scheme'ler
  `fromSeed` otomatiğine sahip değil).
