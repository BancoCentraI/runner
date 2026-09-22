# Tasarım Token'ları

Ham değer yazmak yasak. Padding, radius, gölge, süre ve ikon boyutu tek yerden gelir; tasarım değişince tek dosya güncellenir.

| İhtiyaç | Token | Dosya |
|---|---|---|
| Padding / boşluk | `AppPaddings` | `lib/product/const/app_paddings.dart` |
| Köşe yarıçapı | `AppRadius` | `lib/product/const/app_radius.dart` |
| Gölge | `AppShadows` | `lib/product/theme/app_shadows.dart` |
| Animasyon süresi | `AppDurations` | `lib/product/const/app_durations.dart` |
| İkon boyutu | `AppIconSizes` | `lib/product/const/app_icon_sizes.dart` |
| Renk | `colorScheme` / `AppThemeColors` | `lib/product/theme/` |
| Yazı stili | `textTheme` | `lib/product/theme/parts/text_theme.dart` |

## AppPaddings

```dart
padding: AppPaddings.allXxl        // EdgeInsets.all(24)
padding: AppPaddings.page          // horizontal: 16, vertical: 8
padding: AppPaddings.horizontalL   // horizontal: 16

Column(spacing: AppPaddings.m, children: [...])   // SizedBox yerine
```

Değerler: `xs`=4, `s`=8, `m`=12, `l`=16, `xl`=20, `xxl`=24, `xxxl`=32.

## AppRadius

```dart
borderRadius: AppRadius.card       // liste öğesi / kart
borderRadius: AppRadius.sheet      // bottom sheet (yalnız üst köşeler)
borderRadius: AppRadius.allPill    // tam yuvarlak chip
```

Değerler: `xs`=4, `s`=8, `m`=12, `l`=16, `xl`=20, `xxl`=28, `pill`=999.

## AppShadows

Gölge rengi `colorScheme.shadow`'dan gelir ve dark mod'da opaklık otomatik artar — bu yüzden token'lar **`context` alan fonksiyonlardır**:

```dart
DecoratedBox(
  decoration: BoxDecoration(
    borderRadius: AppRadius.card,
    boxShadow: AppShadows.card(context),
  ),
)
```

Katmanlar: `card` → `raised` → `hero`, ayrıca `bottomBar` (yukarı düşen gölge) ve `popover`.

## AppDurations

```dart
AnimatedContainer(duration: AppDurations.short, ...)
```

`instant`=120ms, `short`=220ms, `medium`=350ms, `long`=600ms. Ayrıca `snackBar`, `debounce`, `networkTimeout`.

## AppIconSizes

`xs`=14, `s`=18, `m`=24 (varsayılan), `l`=32, `xl`=48, `xxl`=72.

## Responsive

`ResponsiveExtension` (`lib/product/utils/extension/context_extension.dart`):

```dart
context.isWide                    // genişlik > 600
context.r(AppPaddings.l)          // boyut ölçekle
context.rf(16)                    // yazı boyutu ölçekle (daha dar aralık)
context.widthRatio(.4)            // ekran genişliğinin %40'ı
```

Ölçek, 390pt referans genişliğe göre hesaplanır ve `0.85–1.25` arasına clamp'lenir.

## Yeni token ekleme

Bir değer ikinci kez yazılacaksa token'a çıkar. Token dosyasına ekle, çağrı yerine **değer yazma**. Renk ekleniyorsa `AppThemeColors`'a hem light hem dark karşılığıyla eklenir.

## Yapma → Yap

| Yapma | Yap |
|---|---|
| `EdgeInsets.all(16)` | `AppPaddings.allL` |
| `SizedBox(height: 12)` | `Column(spacing: AppPaddings.m, ...)` |
| `BorderRadius.circular(12)` | `AppRadius.allM` |
| `Duration(milliseconds: 300)` | `AppDurations.short` |
| `Icon(Icons.x, size: 24)` | `Icon(Icons.x, size: AppIconSizes.m)` |
| `BoxShadow(color: Colors.black26, ...)` | `AppShadows.card(context)` |
| `MediaQuery.of(context).size.width > 600` | `context.isWide` |
